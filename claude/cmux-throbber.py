#!/usr/bin/env python3
"""Spin a braille throbber on this session's cmux workspace row while a turn runs.

cmux status pills take a static SF Symbol, so the icon cannot animate — but the
pill's TEXT can, and rewriting it is cheap (~2ms of CPU per call). A detached
child process cycles frames while Claude is working; the Stop hook kills it.

  cmux-throbber.py start   # UserPromptSubmit hook — spawn the spinner
  cmux-throbber.py stop    # Stop / SessionEnd hook — kill it, clear the pill
  cmux-throbber.py _spin   # internal: the child loop

Driven by hooks rather than the status line so it only spins during a turn: the
status line also renders while the session sits idle, which would leave a
spinner implying work that is not happening.

Best effort throughout — never raises, never prints.
"""
import json
import os
import signal
import subprocess
import sys
import time

FRAMES = '⠋⠙⠹⠸⠼⠴⠦⠧'
INTERVAL = 0.4
COLOR = '#3b6ea5'          # slate blue; red stays reserved for hands-on work
KEY = 'claude_code'        # cmux's own pill — animate it rather than sit beside it
MAX_SECONDS = 60 * 60      # backstop: never spin longer than an hour

# Waiting-for-you beats spinning: a spinner on a session that is blocked on a
# permission prompt is a lie, and cmux's own "Needs input" pill would be
# overwritten by the next frame anyway. The Notification hook raises this flag,
# a PostToolUse `rm` drops it the moment the turn is moving again.
WAIT_ICON = 'person.crop.circle.fill'
WAIT_COLOR = '#c0504d'     # same red as the row, so pill and row agree
# No words anywhere: the row colour says the state, the icon says whose turn it
# is, the bar says how full the context is. cmux rejects an empty status value,
# so a pill with nothing to show carries a zero-width space.
BLANK = '​'
# Ten cells, each subdivided into eighths by the partial-block glyphs, so the
# bar resolves to ~1.25% without being twenty characters wide.
BAR_CELLS = 10
BAR_FULL = '█'
BAR_EMPTY = '░'
BAR_PARTIALS = ('', '▏', '▎', '▍', '▌', '▋', '▊', '▉')
WAIT_TYPES = ('permission_prompt', 'agent_needs_input', 'idle_prompt', 'elicitation_dialog')

# The ROW colour is session state, not context — context is the progress bar.
#   red    stopped: waiting on you, nothing is moving
#   green  an agent is working
#   blue   no agent here, just a terminal
ROW_STOPPED = '#c0504d'
ROW_WORKING = '#5b9357'
ROW_IDLE = '#3b6ea5'


def cli():
    return os.environ.get('CMUX_BUNDLED_CLI_PATH') or 'cmux'


def env():
    return dict(os.environ, CMUX_QUIET='1')


def wait_path():
    panel = os.environ.get('CMUX_PANEL_ID', 'nopanel')
    return os.path.join(os.environ.get('TMPDIR', '/tmp'),
                        'claude-cmux-needsinput-%s.flag' % panel)


def pid_path():
    # Keyed by pane, not session: the pill belongs to the workspace row the
    # pane sits in, and that is what the cmux CLI targets by default.
    panel = os.environ.get('CMUX_PANEL_ID', 'nopanel')
    return os.path.join(os.environ.get('TMPDIR', '/tmp'), 'claude-cmux-throbber-%s.pid' % panel)


def row_color(color):
    run(['workspace-action', '--action', 'set-color', '--color', color])


def run(args):
    subprocess.run(
        [cli()] + args,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        timeout=5,
        env=env(),
    )


def active_dir(workspace):
    """One marker file per working pane, grouped by workspace.

    The row belongs to a WORKSPACE but a spinner belongs to a PANE, and a
    workspace can hold several panes each running their own agent. Without this,
    the first pane to finish painted the row red while its neighbour was still
    working — which is exactly what a red row with a live spinner looked like.
    """
    path = os.path.join(os.environ.get('TMPDIR', '/tmp'),
                        'claude-cmux-active', workspace or 'noworkspace')
    try:
        os.makedirs(path, exist_ok=True)
    except Exception:
        pass
    return path


def workspace_id():
    try:
        out = subprocess.run(
            [cli(), 'identify', '--id-format', 'uuids'],
            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
            timeout=5, env=env(), text=True,
        ).stdout
        return (json.loads(out).get('caller') or {}).get('workspace_id')
    except Exception:
        return None


def alive(pid):
    try:
        os.kill(int(pid), 0)
        return True
    except Exception:
        return False


def agent_pid():
    """Walk up from this hook to the claude process that spawned it.

    Hooks run under a shell, so the parent is not always the agent; six hops is
    plenty. Used by the spin loop to notice a session that died without ever
    running its Stop hook — an interrupted or crashed turn used to leave a
    spinner running for the full hour.
    """
    pid = os.getppid()
    for _ in range(6):
        if pid <= 1:
            break
        try:
            out = subprocess.run(['ps', '-p', str(pid), '-o', 'ppid=,command='],
                                 stdout=subprocess.PIPE, text=True, timeout=5).stdout.strip()
        except Exception:
            break
        if not out:
            break
        parent, _, command = out.partition(' ')
        if '/claude' in command or command.startswith('claude'):
            return pid
        try:
            pid = int(parent)
        except ValueError:
            break
    return None


def ctx_path():
    panel = os.environ.get('CMUX_PANEL_ID', 'nopanel')
    return os.path.join(os.environ.get('TMPDIR', '/tmp'), 'claude-cmux-ctx-%s' % panel)


def context_bar():
    """The status line leaves the context percentage here; draw it as blocks.

    Riding in the pill rather than cmux's own progress row keeps the icon and
    the bar on ONE line instead of two.
    """
    try:
        with open(ctx_path()) as f:
            pct = float(f.read().strip())
    except Exception:
        return ''
    pct = max(0.0, min(100.0, pct))
    eighths = int(round(pct / 100.0 * BAR_CELLS * 8))
    full, rest = divmod(eighths, 8)
    bar = BAR_FULL * full + BAR_PARTIALS[rest]
    return bar + BAR_EMPTY * (BAR_CELLS - len(bar))


def paint(icon, color, lead=''):
    """One pill: an icon, then the context bar. `lead` goes in front of the bar."""
    value = (lead + ' ' if lead else '') + context_bar()
    args = ['set-status', KEY, value or BLANK, '--color', color]
    if icon:
        args += ['--icon', icon]
    run(args)


def others_working(workspace, me):
    """Panes in this workspace still working — stale markers reaped on the way."""
    live = []
    directory = active_dir(workspace)
    for name in os.listdir(directory) if os.path.isdir(directory) else []:
        if name == me:
            continue
        marker = os.path.join(directory, name)
        try:
            with open(marker) as f:
                pid = f.read().strip()
        except Exception:
            pid = ''
        if pid and alive(pid):
            live.append(name)
        else:
            try:
                os.remove(marker)
            except Exception:
                pass
    return live


def stop():
    # No pid file means we were never spinning on this row — leave it alone.
    try:
        with open(pid_path()) as f:
            state = json.load(f)
    except Exception:
        return
    try:
        os.kill(int(state['pid']), signal.SIGTERM)
    except Exception:
        pass
    for path in (pid_path(), wait_path()):
        try:
            os.remove(path)
        except Exception:
            pass

    panel = os.environ.get('CMUX_PANEL_ID', 'nopanel')
    workspace = state.get('workspace')
    try:
        os.remove(os.path.join(active_dir(workspace), panel))
    except Exception:
        pass
    # A finished turn IS the waiting state — but only if this row has no other
    # pane still working, or we would red out a neighbour that is mid-turn.
    if others_working(workspace, panel):
        return
    try:
        row_color(ROW_STOPPED)
        paint(WAIT_ICON, WAIT_COLOR)
    except Exception:
        pass


def start():
    stop()  # never leave two spinners racing on one row
    workspace = workspace_id()
    agent = agent_pid()
    child = subprocess.Popen(
        [sys.executable, os.path.abspath(__file__), '_spin'],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        env=dict(os.environ, CMUX_THROBBER_AGENT_PID=str(agent or '')),
        start_new_session=True,
    )
    try:
        with open(pid_path(), 'w') as f:
            json.dump({'pid': child.pid, 'workspace': workspace}, f)
    except Exception:
        pass
    try:
        panel = os.environ.get('CMUX_PANEL_ID', 'nopanel')
        with open(os.path.join(active_dir(workspace), panel), 'w') as f:
            f.write(str(agent or os.getpid()))
    except Exception:
        pass
    try:
        row_color(ROW_WORKING)
        # cmux's own progress row is redundant now that the bar rides in the
        # pill; dropping it is the line of vertical space this buys back.
        run(['clear-progress'])
    except Exception:
        pass


def spin():
    """Paint until something says otherwise — and check what that something is.

    Three ways to stop, because relying on the Stop hook alone left spinners
    running on rows that had already gone red: the hook never fires for an
    interrupted or crashed turn.
    """
    deadline = time.time() + MAX_SECONDS
    agent = os.environ.get('CMUX_THROBBER_AGENT_PID') or ''
    me = str(os.getpid())
    i = 0
    while time.time() < deadline:
        # 1. a newer spinner owns this pane, or stop() removed the file
        try:
            with open(pid_path()) as f:
                if str(json.load(f).get('pid')) != me:
                    return
        except Exception:
            return
        # 2. the agent that asked for this spinner is gone
        if agent and not alive(agent):
            try:
                row_color(ROW_STOPPED)
                paint(WAIT_ICON, WAIT_COLOR)
                os.remove(pid_path())
            except Exception:
                pass
            return
        try:
            if os.path.exists(wait_path()):
                paint(WAIT_ICON, WAIT_COLOR)
            else:
                paint(None, COLOR, lead=FRAMES[i % len(FRAMES)])
        except Exception:
            return
        i += 1
        time.sleep(INTERVAL)


def main():
    if not os.environ.get('CMUX_PANEL_ID'):
        return
    action = sys.argv[1] if len(sys.argv) > 1 else ''
    if action == '_spin':
        spin()
        return
    # Hook payloads arrive on stdin; drained so the hook never blocks on a pipe.
    payload = {}
    try:
        if not sys.stdin.isatty():
            payload = json.loads(sys.stdin.read() or '{}') or {}
    except Exception:
        payload = {}
    if action == 'start':
        try:
            os.remove(wait_path())
        except Exception:
            pass
        start()
    elif action == 'stop':
        stop()
    elif action == 'waiting':
        if payload.get('notification_type') in WAIT_TYPES:
            try:
                open(wait_path(), 'w').close()
            except Exception:
                pass
            # Assert it now too: the notification may arrive with no spinner
            # running, and cmux writes its own bell pill at the same moment.
            paint(WAIT_ICON, WAIT_COLOR)
            row_color(ROW_STOPPED)


try:
    main()
except Exception:
    pass

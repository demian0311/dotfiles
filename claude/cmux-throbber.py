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
WAIT_COLOR = '#c9a227'     # slate gold — reads as "your turn" without shouting
WAIT_TEXT = 'Needs input'
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


def snapshot():
    """What cmux had in the pill before we took it over, so stop() can put it back."""
    try:
        out = subprocess.run(
            [cli(), 'list-status'],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            timeout=5,
            env=env(),
            text=True,
        ).stdout
    except Exception:
        return None
    for line in out.splitlines():
        if not line.startswith(KEY + '='):
            continue
        rest = line[len(KEY) + 1:]
        saved = {'value': rest, 'icon': None, 'color': None, 'priority': None}
        # Every field is located against the untouched line — trimming `value`
        # as we go once cut the ` color=` marker off before it was read.
        cut = len(rest)
        for field in ('icon', 'color', 'priority'):
            marker = ' %s=' % field
            at = rest.find(marker)
            if at != -1:
                saved[field] = rest[at + len(marker):].split(' ')[0]
                cut = min(cut, at)
        saved['value'] = rest[:cut]
        return saved
    return None


def restore(saved):
    if not saved or not saved.get('value'):
        run(['clear-status', KEY])
        return
    args = ['set-status', KEY, saved['value']]
    if saved.get('icon'):
        args += ['--icon', saved['icon']]
    if saved.get('color'):
        args += ['--color', saved['color']]
    if saved.get('priority'):
        args += ['--priority', saved['priority']]
    run(args)


def stop():
    # No pid file means we were never spinning on this row — leave the pill
    # exactly as cmux left it. (Restoring unconditionally here once wiped
    # cmux's own pill before start() had a chance to snapshot it.)
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
    try:
        restore(state.get('saved'))
    except Exception:
        pass
    # A finished turn IS the waiting state: nothing moves until you type.
    try:
        row_color(ROW_STOPPED)
    except Exception:
        pass


def start():
    stop()  # never leave two spinners racing on one row
    saved = snapshot()
    child = subprocess.Popen(
        [sys.executable, os.path.abspath(__file__), '_spin'],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        env=os.environ.copy(),
        start_new_session=True,
    )
    try:
        with open(pid_path(), 'w') as f:
            json.dump({'pid': child.pid, 'saved': saved}, f)
    except Exception:
        pass
    try:
        row_color(ROW_WORKING)
    except Exception:
        pass


def spin():
    deadline = time.time() + MAX_SECONDS
    i = 0
    while time.time() < deadline:
        try:
            if os.path.exists(wait_path()):
                run(['set-status', KEY, WAIT_TEXT, '--icon', WAIT_ICON, '--color', WAIT_COLOR])
            else:
                run(['set-status', KEY, FRAMES[i % len(FRAMES)], '--color', COLOR])
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
            run(['set-status', KEY, WAIT_TEXT, '--icon', WAIT_ICON, '--color', WAIT_COLOR])
            row_color(ROW_STOPPED)


try:
    main()
except Exception:
    pass

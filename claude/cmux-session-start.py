#!/usr/bin/env python3
"""Paint this session's cmux row for a Claude session that has nothing in it yet.

Registered as a Claude Code SessionStart hook. The row-colour states are shared
with cmux-throbber.py, which owns the other three:

  yellow  a Claude session with no conversation in it — fresh, or just /clear-ed
  green   an agent is working                 (cmux-throbber.py start)
  red     stopped: waiting on you             (cmux-throbber.py stop)
  blue    no Claude here, just a terminal     (cmux-session-end.py, .zshrc)

Only `startup` and `clear` are empty. A `resume` has a conversation behind it and
a `compact` is a turn in flight — painting either yellow would claim a session is
idle while it is mid-thought.

It also RESETS THE PILL, not just the row. cmux registers every session it sees
with lifecycle `running` and only leaves that state on a Stop hook or an idle
notification — neither of which a `/clear` produces, because no turn ever ran.
Measured 2026-08-05: one cleared pane sat on a green "Running" pill for 37
minutes with no hook event of any kind between its SessionStart and the next
prompt. A sibling pane happened to get Claude Code's 60-second idle notification
and recovered; that rescue is incidental, not the mechanism, so the only reliable
fix is to state the empty state here rather than wait to be corrected.

It also drops the marker that tells a plain shell prompt whether this workspace
still has a live Claude in it: without one, every new terminal in a workspace
would paint the row blue over a session that is running fine. SessionEnd removes
it; a stale marker whose pid is gone is reaped by whoever reads it.

Best effort throughout — never raises, never prints.
"""
import json
import os
import subprocess
import sys

ROW_EMPTY = '#c9a227'          # muted gold, same family as the other three
EMPTY_SOURCES = ('startup', 'clear')

# The pill cmux writes its own lifecycle into — the same key cmux-throbber.py
# animates, so the two never sit beside each other saying different things.
PILL_KEY = 'claude_code'
# Whose turn it is, in the row's own colour. The icon has to be passed
# explicitly: cmux keeps the previous one when the flag is omitted, and the
# previous one is the lightning bolt that means Running.
PILL_ICON = 'person.crop.circle.fill'
PILL_BLANK = '​'               # zero-width space; cmux rejects an empty value
THROBBER = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'cmux-throbber.py')


def cli():
    return os.environ.get('CMUX_BUNDLED_CLI_PATH') or 'cmux'


def run(args):
    subprocess.run(
        [cli()] + args,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        timeout=5,
        env=dict(os.environ, CMUX_QUIET='1'),
    )


def live_dir(workspace):
    """One marker per pane running a Claude session, grouped by workspace."""
    path = os.path.join(os.environ.get('TMPDIR', '/tmp'),
                        'claude-cmux-live', workspace or 'noworkspace')
    try:
        os.makedirs(path, exist_ok=True)
    except Exception:
        pass
    return path


def agent_pid():
    """Walk up from this hook to the claude process that spawned it.

    Hooks run under a shell, so the parent is not always the agent; six hops is
    plenty. The pid is what lets a stale marker be told from a live one.

    Matched on `comm` (the executable) rather than the full command line: the
    wrapper shell's own arguments name ~/.claude paths, so a substring test
    against the command line matches the shell itself and returns a pid that is
    dead a second later — which reads as "no Claude here" from the next prompt.
    """
    pid = os.getppid()
    for _ in range(6):
        if pid <= 1:
            break
        try:
            out = subprocess.run(['ps', '-p', str(pid), '-o', 'ppid=,comm='],
                                 stdout=subprocess.PIPE, text=True, timeout=5).stdout.strip()
        except Exception:
            break
        if not out:
            break
        parent, _, comm = out.partition(' ')
        if os.path.basename(comm.strip()) == 'claude':
            return pid
        try:
            pid = int(parent)
        except ValueError:
            break
    return None


def main():
    if not os.environ.get('CMUX_PANEL_ID'):
        return

    payload = {}
    try:
        if not sys.stdin.isatty():
            payload = json.loads(sys.stdin.read() or '{}') or {}
    except Exception:
        payload = {}

    workspace = os.environ.get('CMUX_WORKSPACE_ID', '')
    panel = os.environ.get('CMUX_PANEL_ID', 'nopanel')
    # No pid, no marker: a marker is only worth writing if its liveness can be
    # checked later, and an unresolvable one would either pin the row forever or
    # be reaped on sight anyway.
    agent = agent_pid()
    if agent:
        try:
            with open(os.path.join(live_dir(workspace), panel), 'w') as f:
                f.write(str(agent))
        except Exception:
            pass
    # A shell prompt only repaints on a transition, so the flag it keeps has to
    # go the moment a session appears — otherwise the next idle prompt is a
    # no-op and the row stays whatever this session left behind.
    try:
        os.remove(os.path.join(os.environ.get('TMPDIR', '/tmp'),
                               'claude-cmux-idle-%s' % (workspace or 'noworkspace')))
    except Exception:
        pass

    if payload.get('source') not in EMPTY_SOURCES:
        return

    # A spinner outlives a /clear: the claude process is the same one, so the
    # child's own "did my agent die" check never trips and it would keep
    # repainting frames over everything below. Its Stop hook only fires for a
    # turn that ended, and a cleared session's last turn may have been
    # interrupted instead. Painting red on the way out is fine — the row and
    # pill below land after it.
    try:
        subprocess.run(
            [sys.executable, THROBBER, 'stop'],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=10,
        )
    except Exception:
        pass
    # The bar belongs to the conversation that just went away; leaving it drawn
    # would show the old fill until the status line next writes.
    try:
        os.remove(os.path.join(os.environ.get('TMPDIR', '/tmp'),
                               'claude-cmux-ctx-%s' % panel))
    except Exception:
        pass

    try:
        run(['workspace-action', '--action', 'set-color', '--color', ROW_EMPTY])
        run(['set-status', PILL_KEY, PILL_BLANK, '--color', ROW_EMPTY, '--icon', PILL_ICON])
    except Exception:
        pass


try:
    main()
except Exception:
    pass

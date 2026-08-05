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


def cli():
    return os.environ.get('CMUX_BUNDLED_CLI_PATH') or 'cmux'


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

    try:
        subprocess.run(
            [cli(), 'workspace-action', '--action', 'set-color', '--color', ROW_EMPTY],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=5,
            env=dict(os.environ, CMUX_QUIET='1'),
        )
    except Exception:
        pass


try:
    main()
except Exception:
    pass

#!/usr/bin/env python3
"""Clear the cmux sidebar decoration this session's status line drew.

Registered as a Claude Code SessionEnd hook. Without it a finished session
leaves a coloured row and a stale context meter behind, which reads as work
still in flight. Best effort: never raises, never prints.
"""
import json
import os
import subprocess
import sys


def live_others(workspace, me):
    """Panes in this workspace still holding a Claude session.

    The row belongs to a WORKSPACE, so one pane quitting Claude must not paint
    the row "just a terminal" while its neighbour still has one open. Markers are
    written by cmux-session-start.py; dead ones are reaped on the way past.
    """
    directory = os.path.join(os.environ.get('TMPDIR', '/tmp'),
                             'claude-cmux-live', workspace or 'noworkspace')
    live = []
    for name in os.listdir(directory) if os.path.isdir(directory) else []:
        if name == me:
            continue
        marker = os.path.join(directory, name)
        try:
            with open(marker) as f:
                os.kill(int(f.read().strip()), 0)
            live.append(name)
        except Exception:
            try:
                os.remove(marker)
            except Exception:
                pass
    return live


def main():
    if not os.environ.get('CMUX_PANEL_ID'):
        return

    session_id = ''
    try:
        session_id = (json.load(sys.stdin) or {}).get('session_id', '')
    except Exception:
        pass

    workspace = os.environ.get('CMUX_WORKSPACE_ID', '')
    panel = os.environ.get('CMUX_PANEL_ID', 'nopanel')
    try:
        os.remove(os.path.join(os.environ.get('TMPDIR', '/tmp'),
                               'claude-cmux-live', workspace or 'noworkspace', panel))
    except Exception:
        pass

    cli = os.environ.get('CMUX_BUNDLED_CLI_PATH') or 'cmux'
    env = dict(os.environ, CMUX_QUIET='1')
    commands = [['clear-progress']]
    if not live_others(workspace, panel):
        # Blue is the row state for no Claude here any more, just a terminal.
        commands.insert(0, ['workspace-action', '--action', 'set-color',
                            '--color', '#3b6ea5'])
    for args in commands:
        try:
            subprocess.run(
                [cli] + args,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                timeout=5,
                env=env,
            )
        except Exception:
            pass

    tmp = os.environ.get('TMPDIR', '/tmp')
    panel = os.environ.get('CMUX_PANEL_ID', 'nopanel')
    for path in (
        os.path.join(tmp, 'claude-cmux-%s.json' % (session_id or 'nosession')),
        os.path.join(tmp, 'claude-cmux-ctx-%s' % panel),
    ):
        try:
            os.remove(path)
        except Exception:
            pass


try:
    main()
except Exception:
    pass

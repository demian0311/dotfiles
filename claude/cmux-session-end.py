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


def main():
    if not os.environ.get('CMUX_PANEL_ID'):
        return

    session_id = ''
    try:
        session_id = (json.load(sys.stdin) or {}).get('session_id', '')
    except Exception:
        pass

    cli = os.environ.get('CMUX_BUNDLED_CLI_PATH') or 'cmux'
    env = dict(os.environ, CMUX_QUIET='1')
    for args in (
        # Blue is the third row state: no agent here any more, just a terminal.
        ['workspace-action', '--action', 'set-color', '--color', '#3b6ea5'],
        ['clear-progress'],
    ):
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

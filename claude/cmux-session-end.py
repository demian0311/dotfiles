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
        ['workspace-action', '--action', 'clear-color'],
        ['clear-progress'],
        ['clear-status', 'quota'],
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

    state_path = os.path.join(
        os.environ.get('TMPDIR', '/tmp'),
        'claude-cmux-%s.json' % (session_id or 'nosession'),
    )
    try:
        os.remove(state_path)
    except Exception:
        pass


try:
    main()
except Exception:
    pass

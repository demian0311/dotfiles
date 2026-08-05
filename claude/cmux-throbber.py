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
KEY = 'agent'
MAX_SECONDS = 60 * 60      # backstop: never spin longer than an hour


def cli():
    return os.environ.get('CMUX_BUNDLED_CLI_PATH') or 'cmux'


def env():
    return dict(os.environ, CMUX_QUIET='1')


def pid_path():
    # Keyed by pane, not session: the pill belongs to the workspace row the
    # pane sits in, and that is what the cmux CLI targets by default.
    panel = os.environ.get('CMUX_PANEL_ID', 'nopanel')
    return os.path.join(os.environ.get('TMPDIR', '/tmp'), 'claude-cmux-throbber-%s.pid' % panel)


def run(args):
    subprocess.run(
        [cli()] + args,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        timeout=5,
        env=env(),
    )


def stop():
    path = pid_path()
    try:
        with open(path) as f:
            pid = int(f.read().strip())
        os.kill(pid, signal.SIGTERM)
    except Exception:
        pass
    try:
        os.remove(path)
    except Exception:
        pass
    try:
        run(['clear-status', KEY])
    except Exception:
        pass


def start():
    stop()  # never leave two spinners racing on one row
    child = subprocess.Popen(
        [sys.executable, os.path.abspath(__file__), '_spin'],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        env=os.environ.copy(),
        start_new_session=True,
    )
    try:
        with open(pid_path(), 'w') as f:
            f.write(str(child.pid))
    except Exception:
        pass


def spin():
    deadline = time.time() + MAX_SECONDS
    i = 0
    while time.time() < deadline:
        try:
            run(['set-status', KEY, FRAMES[i % len(FRAMES)], '--color', COLOR, '--priority', '90'])
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
    try:
        if not sys.stdin.isatty():
            json.loads(sys.stdin.read() or '{}')
    except Exception:
        pass
    if action == 'start':
        start()
    elif action == 'stop':
        stop()


try:
    main()
except Exception:
    pass

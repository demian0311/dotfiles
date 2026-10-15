#!/usr/bin/env python3
"""PreToolUse:Bash — refuse a command that can end the user's whole session.

An orphaned process is adopted by the nearest subreaper, which for anything a
session starts is `systemd --user` (anchor) or the user's launchd. So
`kill $(ps -o ppid= -p <orphan>)` signals the user manager, which stops every
user unit and the desktop with it. A bob-day build agent did exactly that on
2026-10-15 at 09:55:30 and took the run down with the session (#1348).

Refused: a kill-family command whose target is read from a parent PID, and the
commands that end the user manager or a login session outright. Stop a process
by the PID saved when it was started. Fails open: any parse error allows it.
"""
import json
import re
import sys

KILL = re.compile(r"(^|[\s;&|(`$])(/usr/bin/|/bin/)?kill\b")
PARENT = re.compile(r"\bppid\b|\$\{?PPID\b|/proc/[^\s/]+/stat\b", re.IGNORECASE)
SESSION_END = re.compile(
    r"\bsystemctl\s+(--user\s+)?(.*\s)?(exit|kill\s+user@)"
    r"|\bloginctl\s+(terminate|kill)-(user|session)\b"
)

REASON = (
    "Refused: this can end the owner's whole desktop session. An orphan's "
    "parent is the user manager (systemd --user), so killing a PID read from "
    "ppid/$PPID signals it, and every user unit dies (#1348). Stop only the "
    "process you started, by the PID you saved when you started it."
)


def main():
    try:
        command = (json.load(sys.stdin).get("tool_input") or {}).get("command") or ""
    except Exception:
        return
    if (KILL.search(command) and PARENT.search(command)) or SESSION_END.search(command):
        print(json.dumps({"hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": REASON,
        }}))


main()

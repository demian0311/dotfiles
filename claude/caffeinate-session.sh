#!/bin/sh
# SessionStart — hold ONE sleep assertion for the whole life of this Claude
# Code session, instead of only while a turn is running.
#
# Claude Code already spawns `caffeinate -i -t 300` of its own accord and
# renews it on activity (observed on 2.1.263, two live assertions parented
# directly by the claude process). That covers a running turn and nothing
# else: the 300s timeout lapses once Claude stops and waits for you, and this
# machine's battery `sleep` is 1 MINUTE, so stepping away mid-conversation
# put it to sleep about six minutes later. This closes that gap.
#
# `caffeinate -w <pid>` releases the assertion when that pid exits, so the
# session owns it and nothing has to clean up on SessionEnd — which matters
# because a killed session runs no SessionEnd hook at all.
#
# What this deliberately does NOT do:
#   -d  keep the DISPLAY lit. Off by default: on battery that is the
#       expensive half, and a dark screen over a machine that is still awake
#       was never the complaint. Set CLAUDE_CAFFEINATE_FLAGS='-di' to add it.
#   -s  prevent sleep outright. `man caffeinate`: valid on AC power ONLY, so
#       on battery it silently asserts nothing.
#   Nothing here survives CLOSING THE LID. Clamshell sleep is not an idle
#   sleep, and no assertion of any kind defers it.
#
# SessionStart fires on startup, resume, clear AND compact, so this must be
# idempotent — it is, by checking for an assertion already bound to this pid.

set -u

flags="${CLAUDE_CAFFEINATE_FLAGS:--i}"

command -v caffeinate >/dev/null 2>&1 || exit 0

# The claude process is this hook's parent in practice, but a harness is free
# to interpose a shell, so walk up rather than trusting $PPID. Bounded, and
# falls back to the parent if nothing matches.
find_claude_pid() {
  p="$PPID"
  i=0
  while [ "$i" -lt 8 ] && [ -n "$p" ] && [ "$p" -gt 1 ] 2>/dev/null; do
    comm=$(ps -o comm= -p "$p" 2>/dev/null) || return 1
    [ -z "$comm" ] && return 1
    case "${comm##*/}" in
      claude) printf '%s\n' "$p"; return 0 ;;
    esac
    p=$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ')
    i=$((i + 1))
  done
  return 1
}

pid=$(find_claude_pid) || pid="$PPID"
[ -n "$pid" ] || exit 0

# Already holding one for this session (a resume, a /clear, a compact).
if ps -axo command= | grep -q "^caffeinate .*-w $pid\$"; then
  exit 0
fi

# shellcheck disable=SC2086 -- $flags is a deliberate word-split of the flag set
nohup caffeinate $flags -w "$pid" >/dev/null 2>&1 &

exit 0

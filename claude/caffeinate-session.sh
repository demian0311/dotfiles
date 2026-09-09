#!/bin/sh
# Hold power assertions on behalf of a Claude Code session. Two modes, wired to
# three hooks in settings.json:
#
#   (no args)   SessionStart  — SYSTEM assertion, held for the session's life.
#   --display   SessionStart, UserPromptSubmit, Stop — DISPLAY assertion, held
#               for a rolling window and renewed by activity.
#
# Why the split. Claude Code already spawns `caffeinate -i -t 300` of its own
# accord and renews it on activity (observed on 2.1.263). That covers a running
# turn and nothing else: the 300s timeout lapses once Claude stops and waits for
# you, and this machine's battery `sleep` is 1 MINUTE, so stepping away
# mid-conversation put it to sleep about six minutes later. The system half
# closes that gap and must last the whole session.
#
# The display half must NOT. It used to: a single `-di -w <pid>` meant that any
# open session pinned the screen on indefinitely, and sessions here stay open
# for days — two were found holding a display assertion for 54 HOURS on
# 2026-09-09. So the display assertion is now a window that starts over on each
# turn boundary and expires on its own.
#
# `caffeinate -w <pid>` releases when that pid exits, so the session owns both
# assertions and nothing has to clean up on SessionEnd — which matters because a
# killed session runs no SessionEnd hook at all. ✅ `-t` and `-w` COMPOSE, and
# the man page does not say so: measured 2026-09-09, `caffeinate -d -t 3 -w
# <live pid>` released at 3s with the victim still running. Whichever fires
# first wins, so a display window can never outlive its session.
#
# Two knobs:
#
#   CLAUDE_CAFFEINATE_FLAGS='-di'   session assertion flags. Default `-i`.
#                                   `-di` restores the old always-lit behaviour.
#   CLAUDE_CAFFEINATE_DISPLAY_SECS  display window. Default 900 (15 min).
#                                   0 disables the display hold entirely.
#
# ⚠️ What the window competes with: macOS's own `displaysleep` (`pmset -g
# custom`) counts from the last USER INPUT, not from the last turn — 20 min on
# AC, 2 min on battery here. So this window only extends anything while you are
# reading output without touching the machine; it never shortens macOS's timer,
# it only suspends it. Whichever is later is when the screen goes dark.
#
# What this still does NOT do:
#   -s  prevent sleep outright. `man caffeinate`: valid on AC power ONLY, so
#       on battery it silently asserts nothing.
#   Nothing here survives CLOSING THE LID. Clamshell sleep is not an idle
#   sleep, and no assertion of any kind defers it.
#   A turn running longer than the window drops the display assertion partway
#   through; Stop renews it at the end. Renewing per tool call was rejected as
#   a shell spawn on every single tool use.
#
# SessionStart fires on startup, resume, clear AND compact, so both modes must
# be idempotent — the session mode checks for an assertion already bound to this
# pid, and the display mode replaces its own predecessor rather than stacking.

set -u

mode="${1:-session}"

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

if [ "$mode" = "--display" ]; then
  # Drop this session's own display holder first, so renewing does not stack one
  # process per turn AND so setting the window to 0 takes effect now rather than
  # whenever the last one happens to expire. Matched on argv rather than a
  # pidfile: the claude pid is in the command line, which makes the owner
  # unambiguous and needs no state on disk. The `-d` test is what keeps this off
  # the session's `-i` holder, whose argv also ends in `-w <pid>`.
  old=$(ps -axo pid=,command= | awk -v p="$pid" \
    '$2 == "caffeinate" && $3 == "-d" && $(NF-1) == "-w" && $NF == p { print $1 }')
  # shellcheck disable=SC2086
  # $old is a deliberate word-split: there may be more than one stale holder.
  [ -n "$old" ] && kill $old 2>/dev/null

  # 0 disables the hold. A malformed value is treated the same rather than
  # guessed at, so a typo fails visibly (the screen sleeps) instead of silently
  # reinstating the default.
  secs="${CLAUDE_CAFFEINATE_DISPLAY_SECS:-900}"
  case "$secs" in
    ''|*[!0-9]*|0) exit 0 ;;
  esac

  nohup caffeinate -d -t "$secs" -w "$pid" >/dev/null 2>&1 &
  exit 0
fi

flags="${CLAUDE_CAFFEINATE_FLAGS:--i}"

# Already holding one for this session (a resume, a /clear, a compact).
if ps -axo command= | grep -q "^caffeinate ${flags} -w $pid\$"; then
  exit 0
fi

# shellcheck disable=SC2086
# $flags is a deliberate word-split of the flag set.
nohup caffeinate $flags -w "$pid" >/dev/null 2>&1 &

exit 0

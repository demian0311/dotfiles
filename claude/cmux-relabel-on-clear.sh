#!/bin/sh
# SessionStart:clear — the previous thread's cmux sidebar label is stale the
# moment the context is cleared, and a label describing finished work is worse
# than a generic one. Reset it to a neutral placeholder immediately, then remind
# Claude to set the real one as soon as this session's subject is clear.
#
# `cmux workspace rename` does NOT default to the calling session's workspace
# (it errors with "could not resolve workspace handle"); $CMUX_WORKSPACE_ID is
# the handle. Verified 2026-08-05.

CMUX_BIN="${CMUX_CLAUDE_HOOK_CMUX_BIN:-cmux}"

if [ -n "$CMUX_WORKSPACE_ID" ] && command -v "$CMUX_BIN" >/dev/null 2>&1; then
  "$CMUX_BIN" workspace rename "$CMUX_WORKSPACE_ID" --title clear >/dev/null 2>&1
  printf '%s\n' 'The cmux workspace label was reset to "clear" because the context was cleared. Set the real one as soon as this session'"'"'s subject is clear (2-4 lowercase words naming the work, not the state): cmux workspace rename "$CMUX_WORKSPACE_ID" --title "<label>"'
fi

exit 0

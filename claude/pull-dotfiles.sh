#!/usr/bin/env bash
# Bring this repo current, then re-run install.sh if the pull moved anything.
#
# Nothing else does this on a machine nobody is sitting at. install.sh re-links
# the tree and regenerates settings.json at every SessionStart but never
# fetches, anchor has no crontab and one systemd timer (Omarchy's own updater),
# and the nightly issue run's pull loop is `cd ~/code/diagrammo && for d in */`,
# which cannot reach ~/code/dotfiles. So without this, every shared skill, rule
# and setting on the second machine sits at whatever was last fetched by hand
# (#859, 2026-09-18).
#
# 🔴 EVERYTHING IS INSIDE main(), CALLED ON THE LAST LINE. Bash reads a script
# incrementally, so a pull that rewrites this file mid-execution can resume at
# the wrong byte offset. A function body is parsed as one unit before any of it
# runs, which is what makes a self-updating script safe. Do not hoist code out
# of main() for tidiness.
#
# 🔴 It is spawned DETACHED by `install.sh --pull` and never runs in the hook's
# own process. The SessionStart hook has a 10-second timeout and this reaches
# the network: blocking would mean a slow network costs the repair, not just
# the update.
#
# Usage: pull-dotfiles.sh [--force]   # --force ignores the throttle

main() {
  set -uo pipefail

  local force=false
  [ "${1:-}" = "--force" ] && force=true

  local here root stamp log interval
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  root="$(dirname "$here")"
  stamp="$HOME/.claude/.dotfiles-pull-stamp"
  log="$HOME/.claude/dotfiles-pull.log"
  interval=900   # 15m — several sessions can start in a burst

  exec >>"$log" 2>&1
  printf '\n=== %s ===\n' "$(date '+%Y-%m-%d %H:%M:%S')"

  if ! $force; then
    local last now
    last=0
    [ -f "$stamp" ] && last="$(command cat "$stamp" 2>/dev/null || echo 0)"
    now="$(date +%s)"
    if [ "$(( now - last ))" -lt "$interval" ]; then
      echo "skip: pulled less than ${interval}s ago"
      return 0
    fi
  fi
  date +%s > "$stamp"

  # Never pull over somebody's work. A dirty tree here is a real edit in
  # progress — .zshrc sits modified for days at a time — and a pull that
  # stashed or clobbered it would be the worst thing this script could do.
  if [ -n "$(git -C "$root" status --porcelain 2>/dev/null)" ]; then
    echo "skip: working tree is dirty"
    git -C "$root" status --short
    return 0
  fi

  local before after
  before="$(git -C "$root" rev-parse HEAD 2>/dev/null)" || { echo "skip: not a git repo"; return 0; }

  # --ff-only so a divergence fails loudly here rather than opening a merge
  # nobody is present to resolve.
  if ! git -C "$root" pull --ff-only; then
    echo "pull failed (see above) — left alone"
    return 1
  fi

  after="$(git -C "$root" rev-parse HEAD)"
  if [ "$before" = "$after" ]; then
    echo "already current at ${after:0:8}"
    return 0
  fi

  echo "moved ${before:0:8} -> ${after:0:8}; re-running install.sh"
  # Without --pull, or this recurses.
  "$here/install.sh" --quiet
}

main "$@"

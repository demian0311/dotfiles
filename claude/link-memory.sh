#!/usr/bin/env bash
# Point every Claude Code memory directory at a POOL tracked in this repo.
#
# Memory lives at ~/.claude/projects/<cwd-slug>/memory, where the slug is the
# session's working directory with "/" replaced by "-". Three consequences, all
# bad (#3): a worktree is a new slug and starts with no notes at all; the same
# project reached by two paths keeps two sets; and none of it is in any repo, so
# the second machine has none of it.
#
# This maps a directory to its project POOL -- worktrees resolve to their main
# checkout -- and symlinks the slug's memory directory at claude/memory/<pool>.
# The repo's existing --pull then carries notes to both machines with no new
# mechanism.
#
# Pools are kept SEPARATE on purpose. Merging them would put every MEMORY.md
# line in front of every session; per-project keeps that near 1k tokens.
#
# Safe to re-run; it is the repair.
set -u

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pool_root="$repo_dir/memory"
projects="$HOME/.claude/projects"
quiet=false
[ "${1:-}" = "--quiet" ] && { quiet=true; shift; }

say() { $quiet || printf "$@"; }

# Pools allowed into this repo, one per line, in claude/memory/PUBLIC. THIS REPO
# IS PUBLIC (#3), and the mechanism below reaches whatever project the session
# happens to be in -- so the default has to be "leave it alone", not "publish
# it". An unlisted pool is never written to and never linked; its notes stay in
# ~/.claude/projects/<slug>/memory exactly as Claude Code left them.
public_list="$pool_root/PUBLIC"
is_public() { [ -f "$public_list" ] && grep -qxF "$1" "$public_list"; }

# A directory's pool: the main checkout's name for anything in a git repo (so a
# worktree resolves to its parent), else the directory's own name. $HOME is
# "home" rather than the username, so the two machines agree.
pool_for() {
  local d="$1" common top
  [ -d "$d" ] || return 1
  if common="$(git -C "$d" rev-parse --git-common-dir 2>/dev/null)"; then
    top="$(cd "$d" && cd "$(dirname "$common")" && pwd)"
    qualify "$top"
    return 0
  fi
  [ "$d" = "$HOME" ] && { echo home; return 0; }
  qualify "$d"
}

# A bare "workspace" or "src" says nothing in a repo shared by two machines, so
# those get their parent's name in front: /home/demian/.openclaw/workspace
# becomes openclaw-workspace. A leading dot is dropped.
qualify() {
  local d="$1" base parent
  base="$(basename "$d")"
  case "$base" in
    workspace|src|repo|main|app|code)
      parent="$(basename "$(dirname "$d")")"
      printf '%s-%s' "${parent#.}" "$base" ;;
    *) printf '%s' "$base" ;;
  esac
}

# Claude Code's slug: both "/" and "." become "-".
slug_for() { printf '%s' "$1" | sed 's|[/.]|-|g'; }

link_one() {
  local dir="$1" pool slug mem
  pool="$(pool_for "$dir")" || return 0
  [ -n "$pool" ] || return 0
  slug="$(slug_for "$dir")"
  mem="$projects/$slug/memory"

  if ! is_public "$pool"; then
    # Already linked in means this pool IS publishing, whatever the list says --
    # the other machine may have linked it before the list existed. Say so every
    # run, loudly and even under --quiet, rather than leaving it to be noticed.
    if [ -L "$mem" ] && [ "$(readlink "$mem")" = "$pool_root/$pool" ]; then
      printf 'WARN   memory/%s is linked into the PUBLIC repo and is not in memory/PUBLIC\n' "$pool"
      return 0
    fi
    say 'skip   %s (pool "%s" not in memory/PUBLIC; notes stay private)\n' "$slug" "$pool"
    return 0
  fi

  mkdir -p "$pool_root/$pool" "$projects/$slug"

  if [ -L "$mem" ] && [ "$(readlink "$mem")" = "$pool_root/$pool" ]; then
    say 'ok     memory/%s <- %s\n' "$pool" "$slug"
    return 0
  fi

  # A real directory here holds notes written before this existed. Move them in
  # rather than dropping them; never overwrite a note already in the pool.
  if [ -d "$mem" ] && [ ! -L "$mem" ]; then
    local moved=0
    for f in "$mem"/*; do
      [ -e "$f" ] || continue
      if [ -e "$pool_root/$pool/$(basename "$f")" ]; then
        # Keep both, but move BOTH in: a leftover here makes the rmdir below
        # fail, and the directory is then left with neither a link nor the
        # notes -- Claude reads nothing at all. Measured 2026-09-21.
        printf 'keep   memory/%s/%s (pool copy wins; local kept as %s.local)\n' \
          "$pool" "$(basename "$f")" "$(basename "$f")"
        mv "$f" "$pool_root/$pool/$(basename "$f").local"
      else
        mv "$f" "$pool_root/$pool/" && moved=$((moved+1))
      fi
    done
    if ! rmdir "$mem" 2>/dev/null; then
      printf 'skip   %s still has files; not replacing it with a link\n' "$mem"
      return 0
    fi
    [ "$moved" -gt 0 ] && printf 'adopt  %s note(s) -> memory/%s\n' "$moved" "$pool"
  elif [ -e "$mem" ] || [ -L "$mem" ]; then
    rm -f "$mem"
  fi

  ln -sfn "$pool_root/$pool" "$mem"
  printf 'link   memory/%s <- %s\n' "$pool" "$slug"
}

# The directory this session is in -- CLAUDE_PROJECT_DIR when a hook supplies
# it, otherwise the current one. Forward-mapping a path to its slug is exact;
# inverting a slug is NOT, because the slug replaces both "/" and "." with "-"
# (/home/demian/.openclaw/workspace -> -home-demian--openclaw-workspace), so this
# never tries. A slug with no session in it is linked the first time one runs
# there, which is the only time it matters.
here="${CLAUDE_PROJECT_DIR:-$PWD}"
[ -d "$here" ] && link_one "$here"

#!/usr/bin/env bash
# Link the tracked Claude Code config in this repo into ~/.claude.
#
# Idempotent and safe to re-run. Claude Code sometimes rewrites settings.json
# by replacing the file, which turns the symlink back into a regular file —
# re-running this restores the link (the replaced file is kept as a .bak-<date>
# alongside it, so nothing written since the last link is lost silently).

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target_dir="$HOME/.claude"

# Files linked from claude/<name> to ~/.claude/<name>.
links=(
  settings.json
  CLAUDE.md
  set-title.py
  statusline.py
  cmux-relabel-on-clear.sh
  cmux-session-start.py
  cmux-session-end.py
  cmux-throbber.py
)

mkdir -p "$target_dir"

for name in "${links[@]}"; do
  src="$repo_dir/$name"
  dest="$target_dir/$name"

  if [ ! -e "$src" ]; then
    printf 'skip   %s (not in repo)\n' "$name"
    continue
  fi

  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    printf 'ok     %s\n' "$name"
    continue
  fi

  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    # A plain file here is either the pre-link original or something Claude Code
    # wrote after replacing the link. Either way it is NEWER than the repo copy,
    # so adopt it into the repo rather than clobbering it with a stale version.
    if ! cmp -s "$dest" "$src"; then
      cp "$dest" "$src"
      printf 'adopt  %s (live copy differed; repo updated)\n' "$name"
    fi
    backup="$dest.bak-$(date +%Y%m%d-%H%M%S)"
    mv "$dest" "$backup"
    printf 'backup %s -> %s\n' "$name" "$(basename "$backup")"
  fi

  ln -sfn "$src" "$dest"
  printf 'link   %s\n' "$name"
done

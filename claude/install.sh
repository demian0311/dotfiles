#!/usr/bin/env bash
# Put the tracked Claude Code config in this repo where Claude Code will read it.
#
# Two mechanisms, because the two files differ:
#
#   CLAUDE.md      ~/.claude/CLAUDE.md is a one-line "@<path>" import pointing
#                  here. That is Claude Code's own documented memory-import
#                  syntax, so there is no link for anything to replace.
#   skills/<name>  each directory under claude/skills/ symlinked to
#                  ~/.claude/skills/<name>. Iterated from the repo, so a NEW
#                  skill needs no edit here. Vendor skills Claude Code installs
#                  itself live in the same directory and are never touched.
#   everything else  symlinked into ~/.claude.
#
# Idempotent, and re-running it is the repair: Claude Code rewrites settings.json
# when settings change, and a rewrite that replaces the file leaves a plain file
# where the symlink was. This adopts such a file back into the repo before
# re-linking, so the newer version wins; the displaced copy is kept as a
# .bak-<timestamp> next to it.
#
# Usage: install.sh [--quiet]   # --quiet reports repairs only, for hook use.

set -euo pipefail

quiet=false
[ "${1:-}" = "--quiet" ] && quiet=true

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target_dir="$HOME/.claude"

# Files symlinked from claude/<name> to ~/.claude/<name>.
links=(
  settings.json
  set-title.py
  statusline.py
  cmux-relabel-on-clear.sh
  cmux-session-start.py
  cmux-session-end.py
  cmux-throbber.py
)

# Reported only when not --quiet: the run changed nothing.
say_ok() { $quiet || printf "$@"; }

mkdir -p "$target_dir"

for name in "${links[@]}"; do
  src="$repo_dir/$name"
  dest="$target_dir/$name"

  if [ ! -e "$src" ]; then
    say_ok 'skip   %s (not in repo)\n' "$name"
    continue
  fi

  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    say_ok 'ok     %s\n' "$name"
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

# Skills: one symlink per directory under claude/skills/. The list is the repo's
# own contents rather than a hardcoded array, so adding a skill is just adding a
# directory. Only names present here are ever touched — the vendor skills sitting
# beside them in ~/.claude/skills are left exactly alone.
skills_src="$repo_dir/skills"
skills_dest="$target_dir/skills"

if [ -d "$skills_src" ]; then
  mkdir -p "$skills_dest"
  for src in "$skills_src"/*/; do
    [ -d "$src" ] || continue
    src="${src%/}"
    name="$(basename "$src")"
    dest="$skills_dest/$name"

    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
      say_ok 'ok     skills/%s\n' "$name"
      continue
    fi

    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
      # Same reasoning as the file loop: a real directory here is newer than the
      # repo copy, so adopt it. Staged through a temp sibling so a failed copy
      # can never leave the repo copy destroyed.
      if ! diff -rq "$dest" "$src" >/dev/null 2>&1; then
        staged="$src.adopting"
        rm -rf "$staged"
        cp -R "$dest" "$staged"
        rm -rf "$src"
        mv "$staged" "$src"
        printf 'adopt  skills/%s (live copy differed; repo updated)\n' "$name"
      fi
      # 🔴 The backup must land OUTSIDE ~/.claude/skills. Claude Code treats every
      # directory in there as a skill, so a foo.bak-<stamp> sibling registers as a
      # SECOND skill with the same description — observed 2026-08-14. That is why
      # this differs from the file loop, where a .bak sibling is inert.
      mkdir -p "$target_dir/skills-backup"
      backup="$target_dir/skills-backup/$name.bak-$(date +%Y%m%d-%H%M%S)"
      mv "$dest" "$backup"
      printf 'backup skills/%s -> skills-backup/%s\n' "$name" "$(basename "$backup")"
    fi

    ln -sfn "$src" "$dest"
    printf 'link   skills/%s\n' "$name"
  done
fi

# CLAUDE.md: a pointer file, not a link. Anything Claude Code appends to the
# global memory lands in the pointer and shows up here as an unexpected extra
# line, which is louder than a silently replaced symlink.
pointer="$target_dir/CLAUDE.md"
want="@$repo_dir/CLAUDE.md"

if [ -f "$pointer" ] && [ ! -L "$pointer" ] && [ "$(command cat "$pointer")" = "$want" ]; then
  say_ok 'ok     CLAUDE.md (import pointer)\n'
else
  if [ -e "$pointer" ] || [ -L "$pointer" ]; then
    # A plain pointer file with anything else in it is a global memory Claude
    # Code appended (the "#" shortcut writes here). Move it into the tracked
    # file rather than dropping it — it was written to be kept.
    if [ ! -L "$pointer" ]; then
      extra="$(grep -vxF "$want" "$pointer" | sed -e '/^[[:space:]]*$/d')"
      if [ -n "$extra" ]; then
        backup="$pointer.bak-$(date +%Y%m%d-%H%M%S)"
        cp "$pointer" "$backup"
        printf '\n%s\n' "$extra" >> "$repo_dir/CLAUDE.md"
        printf 'adopt  CLAUDE.md (%s line(s) appended to the repo copy; original kept as %s)\n' \
          "$(printf '%s\n' "$extra" | wc -l | tr -d ' ')" "$(basename "$backup")"
      fi
    fi
    rm -f "$pointer"
  fi
  printf '%s\n' "$want" > "$pointer"
  printf 'write  CLAUDE.md (import pointer -> %s)\n' "$repo_dir/CLAUDE.md"
fi

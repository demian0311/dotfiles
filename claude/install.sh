#!/usr/bin/env bash
# Put the tracked Claude Code config in this repo where Claude Code will read it.
#
# Two mechanisms, because the two files differ:
#
#   CLAUDE.md      ~/.claude/CLAUDE.md is an "@<path>" import pointer, not a
#                  link. That is Claude Code's own documented memory-import
#                  syntax, so there is nothing for anything to replace. On macOS
#                  it carries a SECOND line importing CLAUDE.macos.md, which
#                  holds the cmux hook rules; anchor has no cmux, and loading
#                  them there cost 2k tokens a session for rules it could not
#                  act on (#1).
#   skills/<name>  each directory under claude/skills/ symlinked to
#                  ~/.claude/skills/<name>. Iterated from the repo, so a NEW
#                  skill needs no edit here. Vendor skills Claude Code installs
#                  itself live in the same directory and are never touched.
#   settings.json  GENERATED, not linked — settings.base.json plus a per-host
#                  overlay, because twelve of the Mac's hooks are macOS-only and
#                  would fire and fail on anchor. settings-sync.py has the detail
#                  and does the adopting.
#   plugins        settings.json's `enabledPlugins` is a declaration; making it
#                  true is `claude plugin install`, whose state is per-machine
#                  and in no repo. plugins-sync.sh installs the difference AND
#                  updates each plugin to the marketplace's latest, since two
#                  machines that merely both have a plugin are not in sync — they
#                  had already drifted hours after setup (#860). It reaches the
#                  network, so this runs it DETACHED and at most once every
#                  PLUGIN_SYNC_INTERVAL seconds — the SessionStart hook that
#                  calls this script has a 10-second timeout.
#   AGENTS.md      ~/.codex/AGENTS.md symlinked to agents/GLOBAL.md, which is the
#                  only file both harnesses read. Codex takes exactly one global
#                  instruction file and nothing was creating the link.
#   everything else  symlinked into ~/.claude.
#
# Idempotent, and re-running it is the repair: Claude Code rewrites settings.json
# when settings change, and a rewrite that replaces the file leaves a plain file
# where the symlink was. This adopts such a file back into the repo before
# re-linking, so the newer version wins; the displaced copy is kept as a
# .bak-<timestamp> next to it.
#
# Usage: install.sh [--quiet] [--plugins] [--pull]
#   --quiet    report repairs only, for hook use
#   --plugins  run the plugin install in the FOREGROUND and wait for it;
#              what a fresh machine's bootstrap wants
#   --pull     spawn pull-dotfiles.sh DETACHED to bring this repo current
#              and re-run this script if the pull moved anything. Wired into
#              settings.linux.json's SessionStart, because nothing else
#              fetches on a machine nobody is sitting at (#859)

set -euo pipefail

quiet=false
force_plugins=false
do_pull=false
for arg in "$@"; do
  case "$arg" in
    --quiet)   quiet=true ;;
    --plugins) force_plugins=true ;;
    --pull)    do_pull=true ;;
  esac
done

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target_dir="$HOME/.claude"

# Files symlinked from claude/<name> to ~/.claude/<name>.
links=(
  set-title.py
  shrink-image-read.py
  statusline.py
  cmux-relabel-on-clear.sh
  caffeinate-session.sh
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

# The cmux hook-and-pill rules only mean anything where cmux exists, so macOS
# imports a second file and anchor does not. Same uname split settings-sync.py
# uses to pick the settings overlay.
if [ "$(uname -s)" = "Darwin" ] && [ -f "$repo_dir/CLAUDE.macos.md" ]; then
  want="$want
@$repo_dir/CLAUDE.macos.md"
fi

if [ -f "$pointer" ] && [ ! -L "$pointer" ] && [ "$(command cat "$pointer")" = "$want" ]; then
  say_ok 'ok     CLAUDE.md (import pointer)\n'
else
  if [ -e "$pointer" ] || [ -L "$pointer" ]; then
    # A plain pointer file with anything else in it is a global memory Claude
    # Code appended (the "#" shortcut writes here). Move it into the tracked
    # file rather than dropping it — it was written to be kept.
    #
    # Everything EXCEPT another checkout's pointer line. `$repo_dir` differs per
    # checkout, so a run from a worktree reads the primary checkout's pointer as
    # memory and appends it to the tracked CLAUDE.md, and the next run from the
    # primary does the same with the worktree's. That ping-pong put a
    # self-import AND an import of a since-deleted worktree into the global
    # instructions, and committed one of them (#861, 2026-09-18). A line that
    # imports a CLAUDE.md is a pointer, never memory, whoever wrote it — so it
    # is dropped and reported rather than kept.
    #
    # Every grep here tolerates no matches: `set -o pipefail` plus `set -e`
    # would otherwise abort the script on the very case this guard exists for,
    # a pointer file holding one foreign pointer line and nothing else.
    if [ ! -L "$pointer" ]; then
      not_ours="$(grep -vxF "$want" "$pointer" || true)"
      stale_ptr="$(printf '%s\n' "$not_ours" | grep -cE '^[[:space:]]*@.*/CLAUDE(\.[a-z]+)?\.md[[:space:]]*$' || true)"
      extra="$(printf '%s\n' "$not_ours" \
        | grep -vE '^[[:space:]]*@.*/CLAUDE(\.[a-z]+)?\.md[[:space:]]*$' \
        | sed -e '/^[[:space:]]*$/d' || true)"
      if [ "$stale_ptr" != "0" ]; then
        printf 'drop   CLAUDE.md (%s import pointer(s) from another checkout, not adopted)\n' \
          "$stale_ptr"
      fi
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

# settings.json: generated rather than linked, and the generator also adopts any
# key Claude Code rewrote from inside a session back into settings.base.json.
# That adoption is what carries a plugin enabled on one machine to the other.
if [ -x "$repo_dir/settings-sync.py" ] || [ -f "$repo_dir/settings-sync.py" ]; then
  if $quiet; then
    python3 "$repo_dir/settings-sync.py" "$(dirname "$repo_dir")" --quiet || true
  else
    python3 "$repo_dir/settings-sync.py" "$(dirname "$repo_dir")" || true
  fi
fi

# Codex reads ONE global instruction file, ~/.codex/AGENTS.md, and claude/CLAUDE.md
# has claimed for weeks that it is a symlink to agents/GLOBAL.md. Nothing created
# it, so on anchor Codex had no global instructions at all (#1). Only linked where
# ~/.codex already exists — that directory is Codex's own, and its absence means
# Codex is not installed here.
codex_dir="$HOME/.codex"
codex_link="$codex_dir/AGENTS.md"
codex_want="$(dirname "$repo_dir")/agents/GLOBAL.md"

if [ -d "$codex_dir" ]; then
  if [ -L "$codex_link" ] && [ "$(readlink "$codex_link")" = "$codex_want" ]; then
    say_ok 'ok     codex AGENTS.md\n'
  else
    if [ -f "$codex_link" ] && [ ! -L "$codex_link" ]; then
      backup="$codex_link.bak-$(date +%Y%m%d-%H%M%S)"
      mv "$codex_link" "$backup"
      printf 'backup codex AGENTS.md -> %s\n' "$(basename "$backup")"
    fi
    ln -sfn "$codex_want" "$codex_link"
    printf 'link   codex AGENTS.md -> agents/GLOBAL.md\n'
  fi
fi

# Plugins. Installing reaches the network, and the SessionStart hook that calls
# this script has a 10-second timeout, so the common path is: ask the cheap
# local question (is anything missing?), and if so hand the slow part to a
# detached process. --plugins runs it in the foreground instead, which is what a
# fresh machine wants.
PLUGIN_SYNC_INTERVAL=21600   # 6h — a failed install should retry, not hammer
plugin_script="$repo_dir/plugins-sync.sh"
plugin_log="$HOME/.claude/plugins-sync.log"
plugin_stamp="$HOME/.claude/.plugins-sync-stamp"

if [ -x "$plugin_script" ]; then
  if $force_plugins; then
    "$plugin_script" || printf 'warn   plugins (see above)\n'
    date +%s > "$plugin_stamp"
  else
    last=0
    [ -f "$plugin_stamp" ] && last="$(command cat "$plugin_stamp" 2>/dev/null || echo 0)"
    now="$(date +%s)"
    # 🔴 `||`, not `&&`. --check is local and cheap and can only see a MISSING
    # plugin; version drift needs a marketplace refresh, which is a network
    # call and cannot go on the hook path. Gating the background run on --check
    # alone deadlocked the version pass — a stale catalog reports everything
    # present, so nothing ever refreshed the catalog (#860). The staleness
    # clock fires it regardless; --check only makes a missing plugin arrive
    # sooner than the next interval.
    if [ "$(( now - last ))" -ge "$PLUGIN_SYNC_INTERVAL" ] || ! "$plugin_script" --check >/dev/null 2>&1; then
      date +%s > "$plugin_stamp"
      nohup "$plugin_script" >>"$plugin_log" 2>&1 &
      printf 'plugins syncing in the background (install + versions) -> %s\n' "$plugin_log"
    else
      say_ok 'ok     plugins\n'
    fi
  fi
fi

# Bring the repo current, detached. Last, so this run finishes with the tree it
# started on; if the pull moves anything, pull-dotfiles.sh re-runs this script
# against the new content a moment later.
#
# 🔴 Never pull in THIS process. Bash reads a script incrementally, so a pull
# that rewrites install.sh mid-run can resume at the wrong byte offset. And the
# SessionStart hook has a 10-second timeout, so a network call here would mean a
# slow connection costs the repair rather than just the update.
if $do_pull && [ -x "$repo_dir/pull-dotfiles.sh" ]; then
  nohup "$repo_dir/pull-dotfiles.sh" >/dev/null 2>&1 &
  say_ok 'pull   spawned (log: %s)\n' "$HOME/.claude/dotfiles-pull.log"
fi

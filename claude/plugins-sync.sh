#!/usr/bin/env bash
# Install the marketplace plugins that settings.json says should be enabled.
#
# `enabledPlugins` and `extraKnownMarketplaces` in settings.json are a
# DECLARATION — they say which plugins this account wants. What actually makes a
# plugin present is `claude plugin install`, whose result lives in
# ~/.claude/plugins/{known_marketplaces.json,installed_plugins.json,cache/}. That
# state is per-machine and is not in any repo, which is why anchor had the
# official marketplace known and zero plugins installed while the Mac had three
# (measured 2026-09-18, the skill-delivery split #857).
#
# So: settings.base.json is the tracked list, this turns it into installs, and
# settings-sync.py adopts a plugin installed by hand back into the repo — a
# plugin installed on either machine reaches the other on the next `git pull`.
#
# 🔴 It never passes `-y`. That flag accepts a MARKETPLACE-DECLARED COMMAND, so
# an unattended `-y` here would run whatever a catalog asked for, on every
# machine, with nobody watching. A plugin needing one is reported and left for a
# person; the github-sourced ones we use need no command at all.
#
# Usage:
#   plugins-sync.sh            install anything missing
#   plugins-sync.sh --check    report what is missing, exit 1 if any; install nothing
set -uo pipefail

check_only=false
[ "${1:-}" = "--check" ] && check_only=true

settings="$HOME/.claude/settings.json"
plugins_dir="$HOME/.claude/plugins"

[ -f "$settings" ] || { echo "plugins: no $settings yet"; exit 0; }

# Claude Code is not necessarily on a hook's PATH — it is under ~/.openclaw/bin
# on anchor and a version-managed shim on the Mac. Resolve it or do nothing.
claude_bin="$(command -v claude 2>/dev/null || true)"
for candidate in "$HOME/.openclaw/bin/claude" "$HOME/.claude/local/claude" \
                 "$HOME/.local/bin/claude" /opt/homebrew/bin/claude /usr/local/bin/claude; do
  [ -n "$claude_bin" ] && break
  [ -x "$candidate" ] && claude_bin="$candidate"
done
[ -n "$claude_bin" ] || { echo "plugins: claude not found on PATH; skipped"; exit 0; }

# What is wanted, and what is already here. One python pass over four files
# rather than four jq calls, because jq is not installed everywhere.
plan="$(python3 - "$settings" "$plugins_dir" <<'PY'
import json, os, sys

settings_path, plugins_dir = sys.argv[1], sys.argv[2]

def load(path, default):
    try:
        with open(path) as f:
            return json.load(f)
    except (OSError, ValueError):
        return default

settings = load(settings_path, {})
known = load(os.path.join(plugins_dir, "known_marketplaces.json"), {})
installed = load(os.path.join(plugins_dir, "installed_plugins.json"), {}).get("plugins", {})

wanted_plugins = [name for name, on in settings.get("enabledPlugins", {}).items() if on]
extra_markets = settings.get("extraKnownMarketplaces", {})

# A marketplace is needed when some wanted plugin names it and it is not known.
for name in sorted({p.split("@", 1)[1] for p in wanted_plugins if "@" in p}):
    if name in known:
        continue
    source = extra_markets.get(name, {}).get("source", {})
    repo = source.get("repo") or source.get("url") or source.get("path")
    if repo:
        print("market\t%s\t%s" % (name, repo))
    else:
        # claude-plugins-official ships with Claude Code, so a marketplace with
        # no declared source is not an error — `plugin install` finds it.
        print("market-unknown\t%s\t-" % name)

for name in wanted_plugins:
    if name not in installed:
        print("plugin\t%s\t-" % name)
PY
)"

if [ -z "$plan" ]; then
  echo "plugins: all enabled plugins installed"
  exit 0
fi

missing_count="$(printf '%s\n' "$plan" | grep -c .)"

if $check_only; then
  printf '%s\n' "$plan" | while IFS=$'\t' read -r kind name _; do
    echo "plugins: missing $kind $name"
  done
  # `market-unknown` is not missing work — it is a marketplace that ships with
  # Claude Code. Counting it would make --check fail forever on a machine with
  # nothing to do, and install.sh spawns a background run on every failure.
  printf '%s\n' "$plan" | grep -qv '^market-unknown' || exit 0
  exit 1
fi

echo "plugins: $missing_count item(s) to install"
status=0

while IFS=$'\t' read -r kind name source; do
  case "$kind" in
    market)
      echo "plugins: adding marketplace $name ($source)"
      "$claude_bin" plugin marketplace add "$source" || status=1
      ;;
    market-unknown)
      echo "plugins: marketplace $name has no source in extraKnownMarketplaces; relying on the built-in catalog"
      ;;
    plugin)
      echo "plugins: installing $name"
      # No -y, deliberately — see the header.
      "$claude_bin" plugin install "$name" </dev/null || {
        echo "plugins: $name did not install unattended; run 'claude plugin install $name' and read what it asks"
        status=1
      }
      ;;
  esac
done <<< "$plan"

exit $status

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
# It also RECONCILES VERSIONS, because installing is not staying in sync. Each
# machine gets whatever the marketplace was serving the day it installed, and
# nothing reconciles them afterwards: on 2026-09-18, hours after both boxes were
# set up, frontend-design was ea0a38e1d671 here and c447c3207a42 there, and
# token-optimizer 5.11.23 against 5.13.16 (#860).
#
# 🔴 Converging on LATEST is the only convergence on offer — there is no way to
# ask for a specific version. `claude plugin install` takes no --version flag,
# and `claude plugin list --json --available` carries no version field and omits
# anything already installed, so a version cannot even be COMPARED before
# acting. The only question the CLI answers is "update it and see": `claude
# plugin update <id> --json` reports `updateOutcome` as `updated` or
# `up_to_date`, with oldVersion and newVersion. So the two machines are in sync
# within one sync interval of each other rather than pinned to a reviewed
# version.
#
# Usage:
#   plugins-sync.sh              install anything missing, then update to latest
#   plugins-sync.sh --check      report what is MISSING, exit 1 if any; touches
#                                nothing and reaches no network — it is what
#                                install.sh calls on the hook path. 🔴 It cannot
#                                see version drift: that needs a marketplace
#                                refresh, which is a network call. The staleness
#                                clock in install.sh is what catches it
#   plugins-sync.sh --no-update  install what is missing and stop there
set -uo pipefail

check_only=false
do_update=true
for arg in "$@"; do
  case "$arg" in
    --check)     check_only=true ;;
    --no-update) do_update=false ;;
  esac
done

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

status=0

if $check_only; then
  if [ -z "$plan" ]; then
    echo "plugins: all enabled plugins installed"
    exit 0
  fi
  printf '%s\n' "$plan" | while IFS=$'\t' read -r kind name _; do
    echo "plugins: missing $kind $name"
  done
  # `market-unknown` is not missing work — it is a marketplace that ships with
  # Claude Code. Counting it would make --check fail forever on a machine with
  # nothing to do, and install.sh spawns a background run on every failure.
  printf '%s\n' "$plan" | grep -qv '^market-unknown' || exit 0
  exit 1
fi

if [ -z "$plan" ]; then
  echo "plugins: all enabled plugins installed"
else
  echo "plugins: $(printf '%s\n' "$plan" | grep -c .) item(s) to install"
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
fi

$do_update || exit $status

# Versions. Refresh the catalogs first — `plugin update` resolves "latest" from
# the local marketplace clone, so without this it would keep reporting
# up_to_date against whatever was cloned on install day.
echo "plugins: refreshing marketplaces"
"$claude_bin" plugin marketplace update </dev/null || {
  echo "plugins: marketplace refresh failed; skipping the version pass"
  exit 1
}

wanted="$(python3 - "$settings" <<'PY2'
import json, sys
try:
    with open(sys.argv[1]) as f:
        s = json.load(f)
except (OSError, ValueError):
    s = {}
for name, on in s.get("enabledPlugins", {}).items():
    # `@synced` plugins come from the claude.ai account and are not ours to move.
    if on and not name.endswith("@synced"):
        print(name)
PY2
)"

while read -r id; do
  [ -n "$id" ] || continue
  out="$("$claude_bin" plugin update "$id" --json </dev/null 2>&1)" || {
    echo "plugins: update $id failed: $(printf '%s' "$out" | tail -1)"
    status=1
    continue
  }
  printf '%s' "$out" | python3 -c '
import json, sys
raw = sys.stdin.read().strip().splitlines()
line = raw[-1] if raw else ""
try:
    r = json.loads(line)
except ValueError:
    print("plugins: update returned no JSON: %s" % line[:120]); sys.exit(0)
outcome = r.get("updateOutcome")
if outcome == "updated":
    print("plugins: %s %s -> %s" % (r.get("pluginId"), r.get("oldVersion"), r.get("newVersion")))
elif outcome == "up_to_date":
    print("plugins: %s at %s" % (r.get("pluginId"), r.get("newVersion")))
else:
    print("plugins: %s %s — %s" % (r.get("pluginId"), outcome, r.get("message", "")[:120]))
'
done <<< "$wanted"

exit $status

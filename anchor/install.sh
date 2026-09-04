#!/usr/bin/env bash
# Install the anchor front door and its units on a fresh anchor.
#
# Run it ON anchor, from a checkout of this repo. It copies rather than
# symlinks the unit files, because systemd refuses to follow a symlink out of
# ~/.config/systemd/user for a unit it is asked to enable.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
units="$HOME/.config/systemd/user"

mkdir -p "$HOME/anchor-hub" "$units"
install -m 0644 "$here/hub.mjs" "$HOME/anchor-hub/hub.mjs"
install -m 0644 "$here"/systemd/*.service "$units/"

systemctl --user daemon-reload
# anchor-studio serves artifacts that `pnpm studio` produces. On a fresh box
# run that once first, or the unit starts and serves an empty gallery:
#   cd ~/code/diagrammo/dgmo-mcp && pnpm studio   # ctrl-c once it says ready
systemctl --user enable --now anchor-hub.service anchor-docs.service \
  anchor-site.service anchor-api.service anchor-console.service \
  anchor-studio.service anchor-editor.service
loginctl enable-linger "$USER"

echo
echo "Units:"
systemctl --user is-active anchor-hub anchor-docs anchor-site anchor-api anchor-console \
  anchor-studio anchor-editor

# The proxy mappings persist by themselves once set: every line below uses
# --bg, and Tailscale documents that such a configuration resumes after a
# reboot. They are re-applied here anyway because the command is idempotent
# and a fresh box has none.
#
# Public port = local port + 10000. Proxy port = local port + 20000. The
# public port must NOT equal the local one: tailscaled's own listener would
# then look like a busy port to Vite, and the dev server would slide to the
# next one, leaving the proxy pointing at nothing.
#
# 18789 is OpenClaw, which is NOT a Diagrammo service and has no unit here --
# it brings its own. The mapping still belongs in this loop, because the
# listener on the other end of it is one of the hub's proxies.
for pair in 4321 4330 5173 5190 8787 4347 18789; do
  tailscale serve --bg --https=$((pair + 10000)) "http://localhost:$((pair + 20000))"
done

echo
tailscale serve status

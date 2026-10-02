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
# OpenClaw's Cloudflare MCP servers run through this, so a lapsed login fails in
# the gateway log instead of opening a Chromium tab every heartbeat. The
# servers' "command" in ~/.openclaw/openclaw.json must point at it.
mkdir -p "$HOME/.local/bin"
install -m 0755 "$here/bin/mcp-remote-headless" "$HOME/.local/bin/mcp-remote-headless"
install -m 0644 "$here"/systemd/*.service "$units/"
install -m 0644 "$here"/systemd/*.timer "$units/"

systemctl --user daemon-reload

# Display blanking. Omarchy 4 has no display-off step of its own: its idle
# service (omarchy-shell) reads only `screensaver` and `lock` from
# ~/.config/omarchy/shell.json, so the monitor otherwise stays lit all night
# showing the lock screen. hypridle supplies the missing timer and nothing else
# -- no lock_cmd, because locking stays with omarchy-system-lock.
#
# The package is not installed here: this script runs no sudo. Install it with
#   sudo pacman -S --needed hypridle
# 🔴 Hyprland 0.56.2 takes a Lua dispatch API. `hyprctl dispatch dpms off` --
# the form in every hypridle guide -- fails with a Lua parse error and blanks
# nothing. hypridle.conf uses hl.dsp.dpms({action = "..."}) instead.
if command -v hypridle >/dev/null; then
  mkdir -p "$HOME/.config/hypr"
  install -m 0644 "$here/hypridle.conf" "$HOME/.config/hypr/hypridle.conf"
  systemctl --user enable --now hypridle.service
else
  echo "hypridle absent; run 'sudo pacman -S --needed hypridle' then re-run this script"
fi

# Remote desktop: the Mac views this screen with TigerVNC (README has why not
# Screen Sharing). Bound to the Tailscale address only.
# 🔴 Screen Sharing speaks RFB 3.3 to a non-Apple server, and 3.3 carries only
# classic VNC auth: one password, no username, 8 characters, DES. With no auth
# it would not connect at all; with PAM or Apple Diffie-Hellman neatvnc logged
# "Authentication required, but not supported for RFB 3.3" (both 2026-10-02).
# So allow_broken_crypto is on and the password is generated once, kept only in
# ~/.config/wayvnc/config (0600), never in this repo. The tailnet is the real
# gate. enable_auth refuses to start without the TLS and RSA keys even so.
# Same no-sudo rule as hypridle:
#   sudo pacman -S --needed wayvnc
if command -v wayvnc >/dev/null; then
  vnc="$HOME/.config/wayvnc"
  mkdir -p "$vnc"
  [ -f "$vnc/tls_key.pem" ] || openssl req -x509 -newkey ec \
    -pkeyopt ec_paramgen_curve:secp384r1 -sha384 -days 3650 -nodes \
    -keyout "$vnc/tls_key.pem" -out "$vnc/tls_cert.pem" -subj /CN=anchor
  [ -f "$vnc/rsa_key.pem" ] || openssl genrsa -traditional -out "$vnc/rsa_key.pem" 4096
  chmod 600 "$vnc/tls_key.pem" "$vnc/rsa_key.pem"
  pw=$(sed -n 's/^password=//p' "$vnc/config" 2>/dev/null || true)
  [ -n "$pw" ] || pw=$(LC_ALL=C tr -dc 'a-km-zA-HJ-NP-Z2-9' </dev/urandom | head -c 8)
  printf '%s\n' enable_auth=true allow_broken_crypto=true relax_encryption=true \
    "password=$pw" \
    "private_key_file=$vnc/tls_key.pem" "certificate_file=$vnc/tls_cert.pem" \
    "rsa_private_key_file=$vnc/rsa_key.pem" > "$vnc/config"
  chmod 600 "$vnc/config"
  systemctl --user enable --now wayvnc.service
else
  echo "wayvnc absent; run 'sudo pacman -S --needed wayvnc' then re-run this script"
fi

# anchor-studio serves artifacts that `pnpm studio` produces. On a fresh box
# run that once first, or the unit starts and serves an empty gallery:
#   cd ~/code/diagrammo/dgmo-mcp && pnpm studio   # ctrl-c once it says ready
# 🔴 anchor-console.service is deliberately NOT in this list, and its unit file
# is kept only so the decision can be reversed in one commit. The console it
# served on :5190 could never be signed into: Cloudflare's bot check
# (Turnstile) issues a token only for a hostname on the `diagrammo-signin`
# widget's allow list, `anchor.tailb10eb2.ts.net` is not on it, and Demian
# declined to add it on 2026-09-09 (diagrammo/diagrammo#753) because every
# device that can reach this box is already on the tailnet. The front page
# links console.diagrammo.app instead. Re-adding it means adding that hostname
# in the Cloudflare dashboard FIRST -- the sign-in is dead without it.
# Session compaction, daily. OpenClaw's own maintenance evicts on age, count and
# disk budget but has no concept of context LENGTH, so nothing else shrinks a
# session that is merely long (#878).
systemctl --user enable --now openclaw-compact-sweep.timer
# Leaked plugin captures, hourly. OpenClaw 2026.9.5 leaves ~341 MB in /tmp per
# isolated run and /tmp's per-user quota fills silently (openclaw#156571).
systemctl --user enable --now openclaw-tmp-reaper.timer
# Lapsed MCP logins, daily at 03:05. mcp-remote-headless keeps a lapsed login
# from opening tabs, which also hides it; this files it as a `Your turn` issue
# so the 03:55 morning message carries it.
systemctl --user enable --now openclaw-mcp-login-check.timer

systemctl --user enable --now anchor-hub.service anchor-docs.service \
  anchor-site.service anchor-api.service \
  anchor-studio.service anchor-editor.service
loginctl enable-linger "$USER"

echo
echo "Units:"
systemctl --user is-active anchor-hub anchor-docs anchor-site anchor-api \
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
for pair in 4321 4330 5173 8787 4347 18789; do
  tailscale serve --bg --https=$((pair + 10000)) "http://localhost:$((pair + 20000))"
done

echo
tailscale serve status

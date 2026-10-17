#!/bin/bash
# eagle-zoom: Hyprland plugin that makes Ctrl + two-finger scroll zoom the screen
# (macOS Accessibility Zoom). Hyprland binds cannot see touchpad scroll; see
# main.cpp and dotfiles issue #10 (2026-10-17).
# Run as the user, no sudo:
#     ~/code/dotfiles/eagle/zoom/install.sh
# Rerun after every Hyprland update: the plugin is tied to the exact Hyprland
# commit and dependency versions (__hyprland_api_get_client_hash in PluginAPI.hpp) and refuses to
# load into any other. Undo with --uninstall (then remove the hl.plugin.load line
# from ~/.config/hypr/input.lua).
set -euo pipefail

here="$(dirname "$(readlink -f "$0")")"
dest="$HOME/.local/lib/hyprland/eagle-zoom.so"

if [[ ${1:-} == --uninstall ]]; then
  hyprctl plugin unload "$dest" >/dev/null 2>&1 || true
  rm -f "$dest"
  echo "removed $dest"
  exit 0
fi

for dep in g++ make pkg-config; do
  command -v "$dep" >/dev/null || { echo "missing $dep"; exit 1; }
done
pkg-config --exists hyprland || { echo "hyprland headers missing (pacman -S hyprland provides them)"; exit 1; }

build="$(mktemp -d)"
trap 'rm -rf "$build"' EXIT
make -C "$here" BUILD="$build" >/dev/null
install -Dm644 "$build/eagle-zoom.so" "$dest"
echo "installed $dest"

# Load into the running compositor when there is one. Never hot-unload a loaded
# copy: dlclose of this plugin crashed Hyprland on 2026-10-16 (dotfiles #12).
if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] && hyprctl version >/dev/null 2>&1; then
  if hyprctl plugin list 2>/dev/null | grep -qF "$dest"; then
    echo "an older build is already loaded; log out and back in to pick up this one"
  else
    hyprctl plugin load "$dest"
  fi
fi

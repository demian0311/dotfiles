#!/bin/bash
# Hide the Limine boot menu on eagle. Run in a real terminal AS THE USER (sudo prompts inside):
#   ~/code/dotfiles/eagle/tuneup/limine-hide-menu.sh
# Output is also written to /tmp/limine-hide-menu.log.
#
# Limine 12.8.0 picks the menu timeout in this order (common/menu.c + common/lib/bli.c, read 2026-10-16):
#   1. LoaderConfigTimeoutOneShot  firmware var, `systemctl reboot --boot-loader-menu=N`, one boot only
#   2. `timeout:` key in /boot/limine.conf, if present (`0` = instant boot, no key can interrupt)
#   3. LoaderConfigTimeout         firmware var, `bootctl set-timeout N`, persistent
# So the config file must carry NO active `timeout:` line, or the firmware setting is ignored.
# Firmware value 0 = "menu-hidden": blank screen for 0.5 s (MENU_HIDDEN_TIMEOUT_MS), any key opens
# the menu. Survives omarchy-refresh-limine (it restores Omarchy's `#timeout: 3`, commented out)
# and kernel updates, so this needs running once, not after every refresh.
#
# Undo:            sudo bootctl set-timeout 5
# Show menu once:  sudo systemctl reboot --boot-loader-menu=10   (this REBOOTS immediately)
set -euo pipefail
exec > >(tee /tmp/limine-hide-menu.log) 2>&1
[[ $EUID -eq 0 ]] && { echo "run as the user, not root; sudo is called inside"; exit 1; }

sudo sed -i -E '/^timeout:/d' /boot/limine.conf
sudo bootctl set-timeout 0

echo "limine.conf active timeout lines: $(sudo grep -cE '^timeout:' /boot/limine.conf || true)   (expect 0)"
v=/sys/firmware/efi/efivars/LoaderConfigTimeout-4a67b082-0a4c-41cf-b6c7-440b29bb8c4f
echo "firmware LoaderConfigTimeout: $(tail -c +5 "$v" | tr -d '\0')   (expect 0)"
echo "Now reboot with:  systemctl reboot   (no flags)"

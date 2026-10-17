#!/bin/bash
# Run in a real terminal AS THE USER (yay refuses root; sudo prompts inside):
#   ~/code/dotfiles/eagle/tuneup/install.sh
# Root-level fixes from the 2026-10-16 eagle health audit. Each step is idempotent.
#   mbpfan        userspace fan daemon for applesmc; stock SMC curve left the fan at
#                 1168 rpm with the package at 90 C. Config: /etc/mbpfan.conf
#                 (defaults low 63 / high 66 / max 86 C).
#   rtkit         grants PipeWire realtime priority; without it the journal shows
#                 "RTKit error: ServiceUnknown" and audio stutters under load.
#   fstrim.timer  weekly SSD trim; was disabled and btrfs has no discard option.
#   limine        hide the boot menu via firmware variable: limine-hide-menu.sh (same dir).
#                 Survives omarchy-refresh-limine. Measured 3.3 s loader with the stock menu.
# Idle discharge baseline on battery, Chromium closed, before this ran: not measured.
set -euo pipefail
[[ $EUID -eq 0 ]] && { echo "run as the user, not root (yay)"; exit 1; }

yay -S --needed --noconfirm rtkit mbpfan

sudo systemctl enable --now rtkit-daemon.service mbpfan.service fstrim.timer
systemctl --user restart pipewire.service pipewire-pulse.service wireplumber.service

"$(dirname "$(readlink -f "$0")")/limine-hide-menu.sh"

sleep 5
echo "rtkit:   $(systemctl is-active rtkit-daemon.service)"
echo "mbpfan:  $(systemctl is-active mbpfan.service), fan $(cat /sys/devices/platform/applesmc.768/fan1_input) rpm, package $(( $(cat /sys/class/thermal/thermal_zone1/temp) / 1000 )) C"
echo "fstrim:  $(systemctl is-enabled fstrim.timer)"
echo "profile: $(powerprofilesctl get)"

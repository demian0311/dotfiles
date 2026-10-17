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
#   limine        menu timeout 1 s (unset = Limine default, measured 3.3 s loader).
#                 omarchy-refresh-limine resets /boot/limine.conf; rerun this after it.
# Idle discharge baseline on battery, Chromium closed, before this ran: not measured.
set -euo pipefail
[[ $EUID -eq 0 ]] && { echo "run as the user, not root (yay)"; exit 1; }

yay -S --needed --noconfirm rtkit mbpfan

sudo systemctl enable --now rtkit-daemon.service mbpfan.service fstrim.timer
systemctl --user restart pipewire.service pipewire-pulse.service wireplumber.service

if sudo grep -qE '^#?timeout:' /boot/limine.conf; then
  sudo sed -i -E 's/^#?timeout:.*/timeout: 1/' /boot/limine.conf
else
  sudo sed -i '1i timeout: 1' /boot/limine.conf
fi

sleep 5
echo "rtkit:   $(systemctl is-active rtkit-daemon.service)"
echo "mbpfan:  $(systemctl is-active mbpfan.service), fan $(cat /sys/devices/platform/applesmc.768/fan1_input) rpm, package $(( $(cat /sys/class/thermal/thermal_zone1/temp) / 1000 )) C"
echo "fstrim:  $(systemctl is-enabled fstrim.timer)"
echo "limine:  $(sudo grep -E '^timeout:' /boot/limine.conf)"
echo "profile: $(powerprofilesctl get)"

#!/bin/bash
# Run in a real terminal: sudo ~/code/dotfiles/eagle/upower/install.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
install -m 0755 "$here/eagle-upower-sanity" /usr/local/bin/eagle-upower-sanity
install -m 0644 "$here/eagle-upower-sanity.service" /etc/systemd/system/eagle-upower-sanity.service
install -m 0644 "$here/eagle-upower-sanity.timer" /etc/systemd/system/eagle-upower-sanity.timer
install -m 0644 "$here/70-eagle-upower-sanity.rules" /etc/udev/rules.d/70-eagle-upower-sanity.rules
install -m 0755 "$here/95-eagle-upower-sanity" /usr/lib/systemd/system-sleep/95-eagle-upower-sanity
systemctl daemon-reload
udevadm control --reload
systemctl enable --now eagle-upower-sanity.timer
EAGLE_DELAYS=0 /usr/local/bin/eagle-upower-sanity
echo "timer: $(systemctl is-active eagle-upower-sanity.timer), upower: $(systemctl is-active upower)"

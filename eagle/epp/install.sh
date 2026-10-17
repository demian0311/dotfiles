#!/usr/bin/env bash
# Run as root in a real terminal: sudo bash ~/code/dotfiles/eagle/epp/install.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
install -m 0755 "$here/eagle-epp" /usr/local/bin/eagle-epp
install -m 0644 "$here/eagle-epp.service" /etc/systemd/system/eagle-epp.service
install -m 0644 "$here/eagle-epp.timer" /etc/systemd/system/eagle-epp.timer
install -m 0644 "$here/70-eagle-epp.rules" /etc/udev/rules.d/70-eagle-epp.rules
systemctl daemon-reload
udevadm control --reload
systemctl enable --now eagle-epp.timer
/usr/local/bin/eagle-epp
echo "timer: $(systemctl is-active eagle-epp.timer), profile: $(powerprofilesctl get), epp: $(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference)"

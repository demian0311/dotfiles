#!/bin/bash
# Run in a real terminal: sudo ~/code/dotfiles/eagle/sleep/install.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
install -m 0755 "$here/80-eagle-lid-hibernate" /usr/lib/systemd/system-sleep/80-eagle-lid-hibernate
install -m 0644 "$here/30-lid-hibernate.conf" /etc/systemd/logind.conf.d/30-lid-hibernate.conf
# HUP reloads logind config; a restart would kill the graphical session.
systemctl kill -s HUP systemd-logind
sleep 1
echo "HandleLidSwitch: $(busctl get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager HandleLidSwitch)"

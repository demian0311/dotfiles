#!/bin/bash
# User-level, no root: ~/code/dotfiles/eagle/brightness/install.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
install -Dm 0755 "$here/eagle-power-brightness" ~/.local/bin/eagle-power-brightness
install -Dm 0644 "$here/eagle-power-brightness.service" ~/.config/systemd/user/eagle-power-brightness.service
systemctl --user daemon-reload
systemctl --user enable eagle-power-brightness.service
systemctl --user restart eagle-power-brightness.service
echo "service: $(systemctl --user is-active eagle-power-brightness.service)"

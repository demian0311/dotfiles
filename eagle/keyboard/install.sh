#!/bin/bash
# Software debounce for eagle's butterfly keyboard (MacBookPro14,1), which
# double-types; macOS masks it, applespi/libinput/Hyprland do not. Dotfiles
# issue #7, 2026-10-16.
# Run in a real terminal AS THE USER (makepkg refuses root; sudo prompts inside):
#     ~/code/dotfiles/eagle/keyboard/install.sh
# Undo with:
#     ~/code/dotfiles/eagle/keyboard/install.sh --uninstall
# Installs: the debounced package (pkg/PKGBUILD), a systemd drop-in that
# attaches it to the applespi keyboard at boot (debounced.conf +
# eagle-debounced-attach), and a libinput quirk so touchpad disable-while-typing
# still pairs (local-overrides.quirks). Log out and back in after installing:
# libinput reads quirks only when Hyprland starts.
set -euo pipefail
[[ $EUID -eq 0 ]] && { echo "run as the user, not root (makepkg)"; exit 1; }

here="$(dirname "$(readlink -f "$0")")"
quirks=/etc/libinput/local-overrides.quirks
start='# >>> eagle keyboard debounce >>>'
end='# <<< eagle keyboard debounce <<<'
dropin=/etc/systemd/system/debounced.service.d/eagle.conf
attach=/usr/local/libexec/eagle-debounced-attach

if [[ ${1:-} == --uninstall ]]; then
  sudo systemctl disable --now debounced.service || true
  sudo rm -f "$dropin" "$attach"
  sudo rmdir --ignore-fail-on-non-empty /etc/systemd/system/debounced.service.d 2>/dev/null || true
  if [[ -f $quirks ]] && sudo grep -qF "$start" "$quirks"; then
    sudo sed -i "/^$start\$/,/^$end\$/d" "$quirks"
    [[ -s $quirks ]] || sudo rm -f "$quirks"
  fi
  sudo systemctl daemon-reload
  sudo pacman -Rns --noconfirm debounced || true
  echo "removed. Log out and back in to drop the quirk."
  exit 0
fi

if ! pacman -Q debounced &>/dev/null; then
  ( cd "$here/pkg" && makepkg -si --needed --noconfirm )
fi

sudo install -Dm755 "$here/eagle-debounced-attach" "$attach"
sudo install -Dm644 "$here/debounced.conf" "$dropin"

sudo install -d -m 0755 /etc/libinput
if [[ -f $quirks ]] && sudo grep -qF "$start" "$quirks"; then
  sudo sed -i "/^$start\$/,/^$end\$/d" "$quirks"
fi
if [[ -s $quirks ]]; then
  printf '\n' | sudo tee -a "$quirks" >/dev/null
  sudo tee -a "$quirks" <"$here/local-overrides.quirks" >/dev/null
else
  sudo install -m 0644 -o root -g root "$here/local-overrides.quirks" "$quirks"
fi
sudo chmod 0644 "$quirks"

sudo systemctl daemon-reload
sudo systemctl enable --now debounced.service
sleep 2
"$here/test-keyboard-debounce" || true
echo "Now log out and back in, then run: $here/test-keyboard-debounce"

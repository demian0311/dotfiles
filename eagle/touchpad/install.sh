#!/bin/bash
# Tag the applespi keyboard as internal so libinput enables disable-while-typing
# on the touchpad. Run once, as root, on eagle:
#     sudo bash ~/code/dotfiles/eagle/touchpad/install.sh
# Then log out and back in: libinput reads quirks only when Hyprland starts.
# Uninstall with:
#     sudo bash ~/code/dotfiles/eagle/touchpad/install.sh --uninstall
set -euo pipefail
(( EUID == 0 )) || { echo "run with sudo" >&2; exit 1; }

here="$(dirname "$(readlink -f "$0")")"
target=/etc/libinput/local-overrides.quirks
start='# >>> eagle touchpad dwt >>>'
end='# <<< eagle touchpad dwt <<<'

if [[ ${1:-} == --uninstall ]]; then
  if [[ -f $target ]] && grep -qF "$start" "$target"; then
    sed -i "/^$start\$/,/^$end\$/d" "$target"
    [[ -s $target ]] || rm -f "$target"
    echo "removed the eagle section from $target. Log out and back in to apply."
  else
    echo "nothing to remove."
  fi
  exit 0
fi

install -d -m 0755 /etc/libinput
if [[ -f $target ]] && grep -qF "$start" "$target"; then
  # Replace the existing section so re-running picks up edits.
  sed -i "/^$start\$/,/^$end\$/d" "$target"
fi
if [[ -s $target ]]; then
  printf '\n' >>"$target"
  cat "$here/local-overrides.quirks" >>"$target"
else
  install -m 0644 -o root -g root "$here/local-overrides.quirks" "$target"
fi
chmod 0644 "$target"

echo "installed into $target."
echo "Now log out and back in, then run: $here/test-touchpad-dwt"

---
name: eagle-keyboard-debounce
description: eagle's butterfly keyboard double-types; fixed with the debounced daemon via dotfiles/eagle/keyboard; socket-path trap and AUR checksum drift
metadata:
  type: project
---

eagle (MacBookPro14,1, 2017 second-generation butterfly keyboard) double-types. It is the
hardware defect Apple ran a repair programme for; macOS masks it in software, Linux does not:
`applespi` has no debounce parameter, libinput debounces mouse buttons only, Hyprland repeat
was at the Omarchy default. Diagnosed 2026-10-16, dotfiles issue #7.

**Fix (landed 2026-10-16, commit 23c0a8c; installed and running on eagle, verified 2026-10-17):**
`~/code/dotfiles/eagle/keyboard/install.sh`, run as the user in a real terminal. It builds
`debounced` from a pinned-commit PKGBUILD, installs a systemd drop-in that attaches the daemon
to the applespi keyboard at boot, and adds a libinput quirk so touchpad disable-while-typing
pairs with the `debounced-virtual-keyboard` uinput device. Verify with
`eagle/keyboard/test-keyboard-debounce`.

**Landmines:**
- `debouncectl` picks its socket from `XDG_RUNTIME_DIR`. The system unit has none, so the daemon
  listens on `/tmp/debounced.sock`; a user shell would look in `/run/user/$UID` and silently
  spawn a second, user-owned daemon. Always `sudo env -u XDG_RUNTIME_DIR debouncectl status`.
- The daemon attaches to nothing on its own; `debouncectl start <dev> <ms>` must follow every
  start. The drop-in's `ExecStartPost` does that after waiting for the socket.
- `yay -S debounced` fails validation: codeberg regenerates archive tarballs, so the AUR
  sha256 drifted (content was byte-identical to tag v2.2). The dotfiles PKGBUILD pins the
  commit instead.
- 🔴 Never run the daemon with `-v`: verbose mode syslogs every key name, and on 2026-10-17 the
  lock-screen password was found in the system journal (dotfiles #14; fix commit 9f5ebba, journal
  purged by `~/fix-debounced-logging.sh`). Raw capture when needed, root only:
  `libinput debug-events --device /dev/input/event4`, never to a persistent log.
- Keystroke stall of 2026-10-17 (dotfiles #13) was NOT the daemon: keys reach it on time; the
  focused app (lock screen after display-off, Claude Code TUI in its first ~8 s) was not drawing
  yet, stretched by the 1.1 GHz power-saver clock cap.

Related: [[eagle-touchpad-dwt-quirk]] (same quirks file, now two sections).

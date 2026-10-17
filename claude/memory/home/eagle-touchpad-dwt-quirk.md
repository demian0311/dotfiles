---
name: eagle-touchpad-dwt-quirk
description: "eagle's touchpad disable-while-typing never paired because the applespi keyboard reports vendor 0; local libinput quirk fixes it. Diagnosed 2026-10-16."
metadata:
  node_type: memory
  type: project
  originSessionId: d6e8d981-4308-45b1-9ab0-a69b28a10b78
  modified: 2026-10-17T04:28:40.800Z
---

On eagle (2016+ MacBook Pro, applespi driver) Hyprland's `disable_while_typing = true` did nothing: libinput 1.31.3 pairs touchpad and keyboard for DWT only when the keyboard carries `AttrKeyboardIntegration=internal` (`tp_want_dwt`), and that tag comes only from a quirk. The shipped `[Apple Internal Keyboard (SPI)]` quirk matches vendor 0x05AC; the applespi keyboard reports vendor 0x0000, so nothing matched. Evidence was the Hyprland log (it carries libinput debug output): zero `palm: dwt activated with` lines and zero `palm detected (typing)` over ~1100 touches, while `palm detected (touch size)` fired normally.

Fix: `dotfiles/eagle/touchpad/` — `install.sh` (root) writes a marker-delimited section into `/etc/libinput/local-overrides.quirks` matching `MatchName=Apple SPI Keyboard` on `MatchBus=spi`; `test-touchpad-dwt` (user) greps the current Hyprland log for the pairing line. Quirks load only when Hyprland starts, so a re-login follows every install. Tracked as the DWT pairing failure (dotfiles #6).

**Why:** the symptom looked like a config problem but the config was right; the proof had to come from libinput's own debug lines, which Hyprland already logs — no root or `libinput debug-events` needed.

**How to apply:** when a touchpad setting "has no effect" on Hyprland, grep `$XDG_RUNTIME_DIR/hypr/*/hyprland.log` for the libinput debug lines before touching config. Remove the override once libinput ships a vendor-0 applespi keyboard quirk or applespi reports 0x05AC. DWT still lets a palm that was already resting before typing move the pointer; only touches that begin during typing are ignored. See [[omarchy-privilege-escalation]] for why install.sh is handed back rather than run here, and [[libinput-3fg-drag-eats-4fg-swipe]] for the other eagle touchpad note.

---
name: libinput-3fg-drag-eats-4fg-swipe
description: "On eagle, three-finger drag swallowed every four-finger workspace swipe because tap-to-click was off; libinput's no-tap fast path cannot see a fourth finger. Fix 2026-10-17: tap on, drag on, tap-and-drag off."
metadata:
  type: project
---

**Symptom (eagle, 2026-10-16):** `drag_3fg = 1` plus `hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })` in `~/.config/hypr/input.lua`: the swipe never fired. Hyprland log showed `[4fg] ... GESTURE_STATE_3FG_DRAG`.

**Cause (libinput 1.31.3 `src/evdev-mt-touchpad-gestures.c`):** with tap-to-click OFF, three active fingers go straight to `GESTURE_STATE_3FG_DRAG_OR_SWIPE_START` (`!tp->tap.enabled && nfingers == finger_count`). That state debounces finger-count changes for `DEFAULT_GESTURE_SWITCH_TIMEOUT` (100 ms); the drag-or-swipe decision fires at `DRAG_3FG_OR_SWIPE_TIMEOUT` (80 ms) on a 5 mm move threshold. A fourth finger landing ~20 ms after the first three is counted at 100 ms, after the button is already pressed. All constants are `#define`s; no quirk or Hyprland option reaches them. With tap ON, three fingers sit in `GESTURE_STATE_UNKNOWN`, which does not debounce, so a fourth finger resets detection and the 4fg swipe takes the normal path; 3fg motion still reaches the drag via `tp_gesture_detect_motion_gestures`.

**Fix (2026-10-17, verified with `hyprctl getoption`):** `tap_to_click = true`, `drag_3fg = 1`, `tap_and_drag = false`. The first attempt (2026-10-16) was `drag_3fg = 0`, which merely dropped the drag. Diagnosis filed as the drag/swipe coexistence issue (dotfiles #9). Tap was off because thumb brushes on the large pad clicked; if that returns, the lever is a thumb-size quirk, not tap.

**How to apply:** grep `$XDG_RUNTIME_DIR/hypr/*/hyprland.log` for `gesture: \[Nfg\]` before touching config; it carries libinput's debug lines without input-group access. Related: [[eagle-touchpad-dwt-quirk]].

---
name: unknown-pleasures-screensaver
description: Custom Joy Division "Unknown Pleasures" braille screensaver replacing Omarchy's stock one.
metadata:
  type: project
---

Built 2026-09-01. Replaces Omarchy's stock TTE screensaver with an animated braille
ridgeline homage to the 1979 Joy Division sleeve; traces are born at the bottom and
drift upward, each occluding the ones behind it (painter's algorithm over a 2x4
braille sub-pixel canvas).

- `~/.local/share/unknown-pleasures/bin/unknown-pleasures` — Python renderer
  (`--selftest` with `SS_COLS`/`SS_ROWS`/`SS_FRAMES` dumps a static frame for tuning).
- `~/.local/share/unknown-pleasures/bin/omarchy-screensaver` — wrapper that shadows
  the packaged command; `OMARCHY_SCREENSAVER=stock` falls back to stock.
- PATH hook appended to `~/.config/hypr/hyprland.lua` — see [[omarchy-command-override-path]].

**Why:** the user wanted the sleeve as a screensaver; Omarchy exposes no screensaver
command setting, only branding text.

Traces run flat at the far left and right, and stacked flat lines read as
stair-steps, so as of 2026-09-05 the ink there is blended back toward the theme
background: `edge_fade()` gives each column a smoothstepped visibility level and
`build_palette()` returns a 2D `[visibility][depth]` escape table. Fully invisible
at the screen edge, full strength by ~13% in.

**How to apply:** to revert, delete the Lua block in `hyprland.lua` and the
`~/.local/share/unknown-pleasures` directory. Look-and-feel knobs live in `Field.__init__`
(ridge spacing, amplitude, scroll speed, plot proportions) and `make_ridge` (pulse count,
noise, envelope). `OMARCHY_SCREENSAVER_EDGE_FADE` sets the fade margin as a fraction of
screen width per side (default `0.15`, `0` disables); widen it toward `0.25` for a more
vignetted plot.

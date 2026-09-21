---
name: omarchy-command-override-path
description: How to shadow a packaged omarchy-* command for Hyprland-spawned processes (PATH order gotcha).
metadata:
  type: project
---

Dropping a replacement `omarchy-*` script in `~/.local/bin` does NOT override the
packaged command for anything Hyprland launches. `/usr/share/omarchy/default/bash/env-bootstrap`
*appends* `~/.local/bin` (system binaries deliberately keep precedence), and
`/usr/share/omarchy/default/hypr/envs.lua` *prepends* `$OMARCHY_PATH/bin` to the
session PATH, so `/usr/share/omarchy/bin/<cmd>` and `/usr/bin/<cmd>` both win.

**Why:** Omarchy's idle service hardcodes `omarchy-launch-screensaver`, which in turn
hardcodes `-e omarchy-screensaver`; PATH is the only hook, and there is no config
key or hook event for either.

**How to apply:** put the override in its own directory (one command per dir, minimal
blast radius) and prepend that dir in `~/.config/hypr/hyprland.lua` with
`hl.env("PATH", ...)`, rebuilding the list so `$OMARCHY_PATH/bin` stays second.
`hyprctl reload` re-applies it; verify with a probe script run via
`hyprctl dispatch "hl.dsp.exec_cmd([[...]])"` that prints `$PATH`, since a plain
Bash-tool shell has a different PATH and no `HYPRLAND_INSTANCE_SIGNATURE`
(recover it from `ls /run/user/1000/hypr/`). Live example: [[unknown-pleasures-screensaver]].

---
name: anchor-omarchy-branding
description: "This machine's Omarchy branding is rebranded to the hostname ANCHOR; how to regenerate or revert it"
metadata: 
  node_type: memory
  type: project
  originSessionId: 1f5df510-614b-4bba-b288-e457f2fc8501
  modified: 2026-09-01T02:24:06.354Z
---

The Omarchy desktop on host `anchor` is rebranded from OMARCHY to **ANCHOR** across
the screensaver, the SDDM login theme, and the Plymouth boot splash (done 2026-08-31).
The lock screen has no logo, and the About window deliberately keeps the stock Omarchy
icon — a wide wordmark there leaves a dead column and shoves fastfetch's info blocks
far right.

**Why:** the Omarchy logo is a hand-drawn pixel face on a 15-unit grid, not a system
font, and it only ships glyphs for O M A R C H Y — so "ANCHOR" needed an N drawn to
match. That reconstruction is not something to redo from scratch.

**How to apply:** everything lives under `~/.config/omarchy/branding/`:
- `tools/mkwordmark` sets any word in the typeface (`--ascii` for screensaver art,
  `--svg` for the logo). `mkwordmark --check` asserts the pipeline still reproduces
  the shipped OMARCHY logo byte-for-byte — run it first if anything looks off.
- `tools/omarchy-font.json` holds the seven glyphs lifted off the grid; adding a
  letter means hand-drawing its cell rows there.
- `stock/` holds the original artwork for reverting.
- `hooks/post-update.d/anchor-branding.hook` reinstalls the login and boot logos,
  which belong to the `omarchy-settings` package and get reverted by updates.

The Plymouth logo is baked into the initramfs, so changing it needs `limine-mkinitcpio`
(this box builds a UKI — `mkinitcpio -P` fails with "No presets found").
See [[omarchy-customization-prefs]].

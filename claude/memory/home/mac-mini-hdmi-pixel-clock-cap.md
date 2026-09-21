---
name: mac-mini-hdmi-pixel-clock-cap
description: Demian's Omarchy desktop is a Macmini6,2 whose HDMI port is capped at a 165 MHz pixel clock; the LG 2560x1080 ultrawide runs natively only via a 50 Hz reduced-blanking modeline in monitors.lua.
metadata:
  type: project
---

The main Omarchy machine ("anchor") is a **Mac mini Late 2012 (Macmini6,2)** with
Intel HD 4000 (i915, card1). Ivy Bridge HDMI is capped at a **165 MHz TMDS clock**,
so i915 filters out every higher mode on `HDMI-A-3`.

The display is an **LG 34" ultrawide, native 2560x1080**. Its EDID-preferred mode
is 2560x1080@60, which even with CVT reduced blanking needs **181.25 MHz** — over
the cap. So it is filtered out, the display falls back to 1920x1080, and the panel
stretches that across 21:9 (everything ~32% too wide).

**60 Hz at 2560x1080 is impossible on this port.** Even minimal blanking needs
htotal*vtotal <= 2,750,000 to fit under 165 MHz, and 2560 active columns alone
exceed that. Max achievable refresh at this resolution is ~56 Hz.

**Working fix (applied 2026-08-30):** a CVT reduced-blanking modeline at 50 Hz /
151.1 MHz in `~/.config/hypr/monitors.lua`:

```lua
hl.monitor({
  output = "HDMI-A-3",
  mode = "modeline 151.10 2560 2608 2640 2720 1080 1083 1093 1111 +hsync -vsync",
  position = "0x0", scale = 1,
})
```

Applies on `hyprctl reload`; no reboot needed. Test one live with
`hyprctl eval 'hl.monitor({...})'` — note **`hyprctl keyword` does NOT work** on
this build ("keyword can't work with non-legacy parsers. Use eval."), because
Omarchy configures Hyprland in Lua.

**What did NOT work:** the kernel cmdline `video=HDMI-A-3:2560x1080MR@50`. The
`R` (reduced-blanking) flag was not honored — the kernel computed full CVT
blanking (htotal 3300, 185.6 MHz) and logged
`i915: [drm] User-defined mode not supported: "2560x1080"`. That drop-in
(`/etc/limine-entry-tool.d/monitor-mode.conf`) was **deleted on 2026-08-30** and
the UKI rebuilt, so don't go looking for it — the modeline above is the only fix
in play.

Demian is fine with 50 Hz here — this box is for coding, not gaming — so don't
push the adapter as a fix unless asked. The clean hardware fix remains the
**Thunderbolt port** — it carries DisplayPort,
which is not subject to the HDMI cap, and supports the full 2560x1080@60 via an
active Mini-DisplayPort-to-HDMI adapter.

Boot config on this machine is **Limine with UKI enabled**: kernel cmdline drop-ins
go in `/etc/limine-entry-tool.d/*.conf` as `KERNEL_CMDLINE[default]+=" ..."`, then
`limine-update` rebuilds. See [[omarchy-privilege-escalation]].

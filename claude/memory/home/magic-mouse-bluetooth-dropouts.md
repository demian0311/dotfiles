---
name: magic-mouse-bluetooth-dropouts
description: Demian's Bluetooth Magic Mouse 2 on anchor drops every 20-45 min with HIDP GET_REPORT timeouts; unrelated to USB/camera work, but looks like a system fault.
metadata:
  type: project
---

`anchor` has **two** Magic Mice, which makes "my mouse stopped working" ambiguous:

- **USB Magic Mouse** `05AC:0269` at `1-2.2`, on the LED Cinema Display's hub. Stable.
- **Bluetooth Magic Mouse 2** `05AC:030D`, `D8:30:62:42:EA:B0`, named **"Demian Mouse"**,
  paired to the BRCM20702 adapter on bus 4 (`4-1.8.1.3`). **This is the one that drops.**

In `hyprctl devices` they are three separate names, and an `hl.device{}` block
naming one does nothing for the other mouse:

| Mouse | Hyprland device name |
|---|---|
| USB Magic Mouse | `apple-inc.-magic-mouse` (pointer), `apple-inc.-magic-mouse-1` (touch surface) |
| BT Magic Mouse 2 | `demian-mouse` |

`~/.config/hypr/input.lua` loops over all three so both mice get natural scroll,
flat accel and `sensitivity = -0.3`. Settings that "don't apply" are usually
scoped to the mouse that isn't in hand.

**Symptom:** it disconnects and re-pairs every ~20-45 minutes. Each drop is preceded
by bluetoothd giving up:

```
bluetoothd: profiles/input/device.c:hidp_report_req_timeout()
            Device D8:30:62:42:EA:B0 HIDP GET_REPORT request timed out
```

Observed 2026-09-16 at 20:06, 21:14, 21:19, 21:29 — roughly hourly for hours.
The `magicmouse` driver sends GET_REPORT to switch the device into multi-touch
mode and the mouse does not answer in time, so the link is torn down.

**It is NOT caused by USB bandwidth or camera work.** This came up twice while
fixing [[apple-display-isight-bandwidth]] and looked both times like collateral
damage. It is not: the Bluetooth adapter is on bus 4, not the display hub, and
drops were already happening at 19:41 and 20:06, before any changes were made.
Check the timestamps against `journalctl -u bluetooth` before blaming anything else.

**Not yet diagnosed.** Leading suspects, untested:
1. The BT controller `4-1.8.1.3` shows `power/control=auto` with
   `autosuspend_delay_ms=2000`, even though `/etc/modprobe.d/omarchy-usb-autosuspend.conf`
   sets `options usbcore autosuspend=-1`. Something re-enables it per-device.
   Try `control=on` via a udev rule.
2. Low mouse battery (couldn't read it — `upower` shows nothing while disconnected;
   check while connected).
3. 2.4 GHz WiFi coexistence — the Broadcom `wl` driver on `wlp2s0` throws
   `wl_notify_scan_status` / `Scan_results error (-22)`, once at 21:15:55, seconds
   after a mouse drop. These Macs share the BT/WiFi radio.

---
name: omarchy-idle-timing-needs-shell-restart
description: Changing idle.screensaver/idle.lock in shell.json requires `omarchy restart shell`; hot-reload silently leaves the idle monitor disarmed.
metadata:
  type: project
---

Verified 2026-09-05 on Omarchy 4.0.1-1. `~/.config/omarchy/shell.json` hot-reloads
bar layout fine, but the `idle` block is a trap: the shell picks up the new *values*
(`omarchy-shell idle status` reports them correctly) while the Quickshell `IdleMonitor`
keeps its old registration and never re-arms. After an idle edit on 2026-09-04, the box
went 25.5 h without a single `idle-monitor: idle` event; a fresh shell on the identical
config armed in exactly 60 s.

**How to apply:** always run `omarchy restart shell` after editing `idle`, then confirm
with `journalctl --user -b | grep "omarchy idle"` that an `idle-cycle-start` appears.

Two more things worth remembering:

- **Display-off is not configurable.** It is hardcoded to lock time + 5 s
  (`/usr/share/omarchy/shell/plugins/lock/Service.qml` — `idleBlankTimer` interval 5000,
  armed by `beginLock()`, runs `omarchy-brightness-display off`). Nothing blanks the
  screen at the screensaver stage, so `idle.lock` alone governs when the panel goes dark.
- **The lock timer only stays armed while a screensaver window exists**
  (`shell/plugins/services/idle/Service.qml`, `handleScreensaverWindowClosed` /
  `handleActiveSignal`). Because `screensaver` < `lock`, the screensaver launches at the
  instant idle begins and must survive the whole gap; if it exits, `cancelIdleCycle` runs
  and the lock and blank never happen. Relevant given [[unknown-pleasures-screensaver]].

All of this is diagnosable over SSH: `omarchy-restart-shell` and `omarchy-shell` derive
the Hyprland signature and `WAYLAND_DISPLAY` from the runtime dir, `hyprctl monitors -j`
exposes `dpmsStatus`, and SSH input does not count as compositor activity. There is no
remote unlock, though — the lock IPC offers only lock/isLocked/status/preview.

**Update 2026-09-05 (later):** the display-off note above is confirmed correct —
`omarchy-brightness-display off` is a DPMS call (`hl.dsp.dpms({ action = "disable" })`,
`/usr/bin/omarchy-brightness-display` line 62), not a backlight change, so `grep -ri dpms
/usr/share/omarchy/` misses it entirely. Do not conclude from that grep that Omarchy has
no display-off step.

Observed failure: after the 08:46:50 lock, `lockRequested`/`armBlankTimer` should have
blanked at 08:46:55 (lock/Service.qml:135-136, `idleBlankTimer` interval 5000 at :415),
but `dpmsStatus` stayed `true` for the next 25 minutes. `runBlank()` emits no `logEvent`,
so nothing in the journal says whether it ran. Suspects, both unproven: the
`Date.now() - armedAt > interval + 2000` guard at :423 re-arming forever if the QML timer
fires late, or a repeated `onWakeRequested` (:283) restarting the countdown.

**Resolved 2026-09-05 09:41.** `~/.config/hypr/hypridle.conf` does the blanking and
**works** — fired at 09:11:17, dispatch returned ok, panel stayed off. Now set to
`timeout = 1805` (= `idle.lock` 1800 + 5 s) so blanking never precedes the lock; it was
900 s, which left a 15-minute window where a dark screen woke to an unlocked desktop.
Keep the two in sync if `idle.lock` changes. Autostart was added as
`o.launch_on_start("hypridle")` in `~/.config/hypr/autostart.lua`.

**Corrected 2026-09-17: that autostart line was wrong — removed.** The packaged
`/usr/lib/systemd/user/hypridle.service` is enabled by preset and already starts
hypridle at login, so the Lua line started a *second* copy. The loser logged
`Another service is already providing the org.freedesktop.ScreenSaver interface`
and could no longer receive app inhibit/uninhibit calls over D-Bus. Verify with
`pgrep -a hypridle` — there must be exactly one. Do not re-add the autostart line.

Two gotchas when restarting hypridle by hand from an agent/SSH shell: it needs
`WAYLAND_DISPLAY`, `HYPRLAND_INSTANCE_SIGNATURE`, `XDG_RUNTIME_DIR` and `DISPLAY` in its
environment or it exits instantly and silently, and `systemd-run --scope` inherits the
calling shell's stdio, so redirecting to /dev/null loses all its journal logging. Use
`systemd-run --user --unit=... --setenv=...` (a transient service) instead.


**Idle never firing at all means an inhibitor, not a timer.** Both consumers of the
compositor's idle signal respect inhibitors: the shell's `IdleMonitor` sets
`respectInhibitors: true` (`shell/plugins/services/idle/Service.qml:255`) and hypridle
honors the Wayland and D-Bus ones. One app wake lock therefore silences the screensaver,
the lock *and* the blank together, and the symptom is total journal silence —
`onIsIdleChanged` only logs transitions, so an inhibited session logs nothing at all
rather than logging a refusal. Seen 2026-09-16: no `idle-monitor: idle` for 8.5 h with
the Zoom web client (`chromium --app=https://app.zoom.us/wc/home`) left open over a live
ffmpeg camera bridge. Hyprland neither logs inhibitors nor exposes any way to list them,
so this is diagnosable only by elimination — rule out input-device churn in the system
journal (the BT Magic Mouse reconnects; see [[magic-mouse-bluetooth-dropouts]]), then look
at which GUI apps were open.

---
name: eagle-power-brightness
description: eagle's panel brightness (33/80/100%) and power profile (power-saver on battery, balanced on AC) are set by one user service on power-state change; look here first if brightness or performance "jumps on its own".
metadata:
  type: project
---

Shipped 2026-10-16, dotfiles commit 7cb9aab, source `eagle/brightness/`. User unit `eagle-power-brightness.service` (graphical-session.target) runs `~/.local/bin/eagle-power-brightness`.

- battery 33%, AC charging (incl. "Not charging") 80%, AC + BAT0 status Full 100%.
- Acts only on state transitions plus once at session start, so manual changes stick.
- Wakes on `udevadm monitor` power_supply events and polls every 30s; acpi-sbs may not emit an event on Charging→Full.
- Verified on battery (36%→33%) and by the user on plug-in.
- Bash landmine hit while building: `$(<file 2>/dev/null)` returns EMPTY — the extra redirect disables the `$(<file)` shortcut.

Log: `journalctl --user -t eagle-power-brightness`. Related: [[eagle-upower-sanity]].

2026-10-16 22:34, dotfiles commit 037d9c4: the same service now also runs `powerprofilesctl set power-saver|balanced` on each transition (polkit allow_active covers a systemd --user unit; verified via `systemd-run --user`). The audit behind it: package 90 C with the fan at 1168 rpm, 38 W on battery, rtkit missing, fstrim.timer off. Root-level fixes (mbpfan, rtkit, fstrim.timer, Limine timeout 1 s) are in `eagle/tuneup/install.sh`, run as the user in a terminal; whether it has been run is not recorded here. Audit page: https://claude.ai/artifact/LeG6Z9ktXxq3dFBxBgzKSw. Related: [[eagle-lid-suspend]], [[eagle-wifi-boot-off]].

2026-10-16 22:42: `eagle/tuneup/install.sh` RAN and was verified live at 22:43. mbpfan 2.4.0 active in manual fan mode (85 C → 6500 rpm, 64 C → ~2100 rpm within 10 s); rtkit granted 4 PipeWire data-loop threads RR priority, 0 "RTKit error" since; fstrim.timer enabled; limine timeout 1. Open: `ADP1/online`=1 while BAT0 Discharging at 9–16 W since the 22:38 boot (so the profile stays balanced on battery) — weak charger or stale ACPI AC flag, not yet asked. GPE17 still ~49/s; untested.

2026-10-16 22:47, dotfiles commit 40af819: the charger was a low-power iPad USB-C one. Adapter online + BAT0 `Discharging` now counts as battery (power-saver, 33%); "Not charging" still counts as charging. Verified live: profile flipped to power-saver on restart; net drain still ~0.8 A (~9 W) with a Claude session running, so that charger cannot fill the battery under load.

**Limine menu (2026-10-16 22:50):** `install.sh` no longer writes `timeout:` into `/boot/limine.conf`; it calls
`eagle/tuneup/limine-hide-menu.sh`, which deletes that key and runs `bootctl set-timeout 0`. Reason, read from
Limine 12.8.0 source: a `timeout:` key in the config file beats the persistent `LoaderConfigTimeout` variable, so
the earlier `timeout: 1` edit silently disabled the firmware fix. Firmware `0` = menu-hidden (0.5 s blank, any key
opens the menu) and survives `omarchy-refresh-limine`. `systemctl reboot --boot-loader-menu=10` reboots at once
and FORCES the menu for that boot; it killed five Claude sessions when run by mistake. Issue: dotfiles #8.

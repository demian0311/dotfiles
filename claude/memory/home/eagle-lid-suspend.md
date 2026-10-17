---
name: eagle-lid-suspend
description: "eagle (MacBookPro14,1) deep suspend hangs ~40s after boot, passed 2+ min after; lid=hibernate (safe) as of 2026-10-16 21:05"
metadata:
  node_type: memory
  type: project
  originSessionId: 7495f42e-72e4-4794-8a55-f4b1bcc590ec
  modified: 2026-10-17T01:56:30.625Z
---

2026-10-16: a script set `MemorySleepMode=s2idle` + lid=suspend-then-hibernate. Closing the lid hung eagle in s2idle (kernel log ends at `PM: suspend entry (s2idle)`, no exit), so a hard reboot was needed. This MacBook supports only `deep`. Never use s2idle here.

Fix in progress: `~/.local/bin/lid-sleep-test` (run as the user in a real terminal; it uses sudo). It sets lid=lock, removes the s2idle drop-in, installs `/usr/lib/systemd/system-sleep/eagle-modules` (unloads facetimehd and brcmfmac around suspend), runs one RTC self-waking deep suspend, and switches lid=suspend only if `PM: suspend exit` appears.

2026-10-16 19:58: `lid-sleep-test` ran; log ended at the step 3 warning and eagle rebooted 20:00. Deep suspend hangs too, even with facetimehd/brcmfmac unloaded. Next: `~/.local/bin/lid-hibernate-test` (checks resume_offset vs `btrfs inspect-internal map-swapfile -r`, hibernates once, sets lid=hibernate only on `hibernation exit`). Omarchy hibernation was already wired: swapfile 15.5G, resume= on cmdline, boot log shows `PM: Image not found (code -22)` = resume path probed.

2026-10-16 20:08: hibernate test passed (resume ~3 min incl. user); lid=hibernate now. Resume asks two passwords: LUKS, then the Omarchy lock screen.

2026-10-16 20:17: staged pm_test (freezer/devices/platform) run: freezer and devices came back, `platform` hung (forced reboot 20:19). So deep suspend dies in late/noirq device suspend or the ACPI platform hooks, not in ordinary driver suspend. Lid stayed hibernate.

Next: `~/.local/bin/sleep-platform-test` (3 runs, picks its phase itself): setup adds `/etc/limine-entry-tool.d/pstore-debug.conf` (efi_pstore on) + reboot; run arms panic-on-lockup + panic=10 auto-restart, pm_async=0, runs platform stage; read copies /sys/fs/pstore to `~/.local/state/sleep-platform-pstore/` and logs the last `PM: calling` line. Empty pstore after a power-button restart = no watchdog fired, CPU wedged in firmware. Remove pstore-debug.conf + limine-update when done.

2026-10-16 20:31: sleep-platform-test run 2 came back OK (`PM: suspend exit` in journal). Only change from the 20:17 hang: pm_async=0 (plus watchdog sysctls, which change nothing on success). Lead: async device suspend race. One pass is not proof. Script restored pm_async=1/panic=0; pstore-debug.conf is still installed. Next: `~/.local/bin/sleep-deep-test` (real S3 via `rtcwake -m mem -s 20`, pm_async=0, watchdog armed; rerun after a restart to read pstore into `~/.local/state/sleep-deep-pstore/`).

2026-10-16 20:35: sleep-deep-test PASSED: real S3 (`Waking up from system sleep state S3`, timekeeping suspended 18.7 s) with pm_async=0 and facetimehd/brcmfmac unloaded. Fix = pm_async=0 persistent via `~/.local/bin/sleep-apply-fix` (written 20:40, not yet run): tmpfiles `/etc/tmpfiles.d/eagle-pm-async.conf`, removes pstore-debug.conf + limine-update, lid=suspend in `/run/systemd/logind.conf.d/90-lid-test.conf` (runtime, so a hang falls back to hibernate), writes 30-lid.conf=suspend only after `PM: suspend exit`. Lid still hibernate; eagle-modules hook still installed.

2026-10-16 20:41: FIXED. sleep-apply-fix ran; real lid close slept S3 27.6 s and woke clean. Live state verified 20:42: logind HandleLidSwitch=suspend (30-lid.conf), pm_async=0 (tmpfiles, applies at boot — not yet seen across a reboot), pstore-debug.conf removed. If lid sleep hangs again, first check `cat /sys/power/pm_async` is 0.

2026-10-16 20:49: REGRESSED. First boot with only the persistent config (pm_async=0 via tmpfiles, verified 0 in the next boot). Lid closed 37 s after login; journal ends at `PM: suspend entry (deep)`; power button needed. All three S3 successes (20:31, 20:35, 20:41) had `pm_print_times=1` + `pm_debug_messages=1` set by the test scripts; this hang had neither. Lead: the debug printk slows suspend and hides a race, so pm_async=0 may be a red herring. cs8409 sound probe was identical in both boots. User was testing whether sound returns after suspend; still unanswered.

2026-10-16 ~20:58: wrote `~/.local/bin/sleep-debug-fix` (not yet run). Run 1: lid=hibernate in 30-lid.conf, `/etc/tmpfiles.d/eagle-pm-debug.conf` sets pm_print_times=1 + pm_debug_messages=1, then reboot. Run 2+: runtime lid=suspend in /run, one lid close, speaker-test; saves lid=suspend after 3 passes. State in `~/.local/state/sleep-debug-fix.state`; a `pending` line from an older boot = that close hung.

**After a forced reboot, read `~/.local/state/lid-sleep-test.log` first.** If its last line is the step 3 warning, deep suspend hangs too. The lid is still lock-only, so it is safe. Hibernate was never tested. The Omarchy NVMe fix (d3cold_allowed=0 on 01:00.0) is active.

Every test script must print, before the screen goes black: what the run is for, the possible outcomes, and a clock-time deadline after which to hold the power button. Then it waits for Enter. The user was frustrated on 2026-10-16 when a script gave none of this.

Each failed test costs the user a hard reboot plus a new session. Make every test self-recovering and logged to disk. Related: [[eagle-wifi-boot-off]], [[eagle-mbp-sound-camera]].

2026-10-16 21:01: sleep-debug-fix lid test 1 HUNG with pm_print_times=1 + pm_debug_messages=1 + pm_async=0 all on (journal ends `PM: suspend entry (deep)`). Debug printk is NOT the fix. Lid back on hibernate (30-lid.conf; /run override gone after reboot). New lead, from boot timestamps: both hangs (20:49, 21:01) came ~40 s after boot; all three passes came 2+ min after boot. Suspect a driver still initializing (facetimehd firmware, brcmfmac, cs8409) when suspend starts. Untested. Sound-after-resume still unanswered.

2026-10-16 21:22: sleep-debug-fix lid test 2 HUNG, 18.5 min after boot (boot 21:04, lid 21:22:34, journal ends `PM: suspend entry (deep)`; power button gave a fresh boot 21:24). The "~40 s after boot" lead is DEAD. Tally: lid-driven S3 1 pass (20:41, slept 27.6 s) / 3 hangs; rtcwake S3 2/2 pass (~20 s). Journal cannot tell a suspend hang from a resume failure, since journald is frozen at entry. New lead, untested: short sleeps (≤~30 s) survive, longer ones do not. Lid on reboot = hibernate (30-lid.conf); /run override gone.

2026-10-16 21:44: keyboard dead on 4-5 boots after the 21:36 hang (`systemctl suspend` from user@1000, 2.5 min after a resume; journal ends `PM: suspend entry (deep)`). Those boots left NO journal (21:36:43 → 21:43:06 gap), so they never got past the LUKS prompt. Every boot that did reach the journal probed `Apple SPI Keyboard` in the initramfs ~2 ms after `Run /init`; applespi/intel_lpss_pci/spi_pxa2xx_platform are in `macbook_spi_modules.conf`. Lead: a hung S3 leaves the SPI keyboard (via LPSS/SMC) wedged across restarts until power drains or SMC reset. Unconfirmed: whether the keyboard was also dead at the Limine menu.

2026-10-16 ~21:55: user confirmed the keyboard was dead at the Limine menu too, so the controller is wedged below Linux. That rules out the initramfs. Wrote `~/.local/bin/suspend-off`, ran 2026-10-16 ~22:00, block active. It installs `/etc/systemd/sleep.conf.d/eagle-no-suspend.conf` (AllowSuspend=no plus the two derived modes) and checks logind CanSuspend=no (systemd 261 reports disabled-by-config as "no"; "na" means hardware unsupported) and CanHibernate=yes. `--undo` removes the file. Recovery: hold power 10 s, wait 30 s; then the non-T2 SMC reset (left Shift+Control+Option+power, 10 s). Any future S3 test must run `suspend-off --undo` first.

2026-10-16 22:15: double password on hibernate resume DIAGNOSED. The 22:03 fix (eagle-sleep-monitor replacing the PrepareForSleep monitor) was aimed at the wrong trigger. The lock comes from the Hyprland switch bind `switch:on:Lid Switch` → `omarchy-system-lid-close` → `omarchy-system-lock` (`/usr/share/omarchy/default/hypr/bindings/utilities.lua:34`), which fires on the lid event itself, 80 ms before logind says "Hibernating..." (journal 22:05:18.808 Lid closed → 22:05:19.001 omarchy-shell lock-requested). PrepareForSleep then finds the session already secure. Fix candidates: `hl.unbind("switch:on:Lid Switch")` + rebind to `omarchy-hyprland-monitor-clamshell` only, in `~/.config/hypr/bindings.lua`. eagle-sleep-monitor stays: it hands back to the packaged monitor if suspend is ever re-enabled, and locks when a hibernate aborts.

2026-10-16 22:13: lid rebind applied in `~/.config/hypr/bindings.lua` (hl.unbind + o.bind to `omarchy-hyprland-monitor-clamshell`, locked=true). `hyprctl reload` ok; `hyprctl binds -j` shows one `switch:on:Lid Switch` entry (Lua arg changed 154→64, so the default was replaced). Not yet tested with a real lid close. Check after a resume: `journalctl --user --since "<lid time>" | grep lock-requested` must be empty.

2026-10-16 22:27: keyboard status re-checked. No new dead-keyboard boot since the 21:43 boot. Two lid-close hibernates since the fix (22:05:18 → resumed 22:06:54; 22:14:48 → resumed 22:16:53) both came back with the keyboard working, and `journalctl --user --since 22:14 | grep -c lock-requested` = 0, so the lid rebind (no double password) is verified. logind CanSuspend=no, CanHibernate=yes. The keyboard problem is PREVENTED (no S3, so nothing can wedge the SMC), not fixed; the S3 hang itself is still undiagnosed.

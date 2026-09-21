---
name: anchor-hdd-head-parking-fixed
description: anchor's Load_Cycle_Count is a lifetime average trap - the parking was fixed 2026-09-05 and the rate is now ~0.04/h; don't re-diagnose it.
metadata:
  type: project
---

anchor's internal drive (APPLE HDD HTS541010A9E662, `/dev/sda`, serial J58000BTHN1ZMF)
carries Load_Cycle_Count 937,545 at Power_On_Hours 32,012 — normalized 7/100 against a
~600,000 rating. **Dividing those two gives ~29 parks/hour and that number is wrong as a
diagnosis**: it is the average across the drive's whole life, most of it spent inside a
MacBook on Apple's default aggressive APM. The wear metric is permanently spent and cannot
recover; platters are clean (0 reallocated, 0 pending, 0 uncorrectable as of 2026-09-20).

The actual parking was diagnosed and fixed **2026-09-05**: `/etc/udev/rules.d/69-hdparm-apm.rules`
pins `hdparm -B 254` on that serial, on `add|change`. Measured 2026-09-20 by differencing the
count in that rule's own comment (937,530) against a live smartctl read (937,545): **15 cycles
over 366 hours = 0.04/hour**. At the 29.3/h reading the drive would have taken ~10,700 more.

**Why:** the lifetime-average trap reads as an active emergency and invites a second fix on top
of a working one. The drive does honour APM writes — `hdparm -I` echoes back `Advanced power
management level: 254`, so the setting is confirmed live, not merely requested.

**How to apply:** before touching APM on this machine, difference two timestamped
Load_Cycle_Count reads; never divide the cumulative count by power-on hours. Samples append to
`/var/log/hdd-park-samples.tsv`. Resume-from-suspend was the one real gap in the udev rule and
was closed 2026-09-20 with `/etc/systemd/system-sleep/hdd-apm` (re-applies APM 254 on `post`,
logs to the journal under tag `hdd-apm`); dry-run verified, a real suspend/resume was not.
All root work here goes back to the user as a script — see [[omarchy-privilege-escalation]].
Same drive, same machine as [[anchor-mac-mini-hdd-bottleneck]].

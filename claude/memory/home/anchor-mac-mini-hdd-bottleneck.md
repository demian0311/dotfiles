---
name: anchor-mac-mini-hdd-bottleneck
description: anchor is a 2012 Mac mini on a 5400 RPM HDD; that disk, not CPU or RAM, is the bottleneck, and it makes dev-server cold starts 35-82s.
metadata:
  type: project
---

`anchor` is a **Mac mini 6,2 (Late 2012)** — i7-3720QM, 16 GB RAM, HD 4000 —
booting off an **APPLE HDD HTS541010A9E662, a 5400 RPM 2.5" Travelstar**, with
LUKS + btrfs (`compress=zstd:3`) on top. Only ~30 GB of 930 GB is used.

**The disk is the bottleneck for everything.** Measured 2026-09-05:

| Service | Cold start to first accept |
|---|---|
| `anchor-docs` (Astro dev) | **82 s** |
| `anchor-site` (Astro dev) | 35 s (warm cache; worse cold) |
| `anchor-editor` (`vite preview`, prebuilt) | 0.4 s |

**Why this matters:** it kills socket activation as a way to reclaim RAM from the
idle dev servers. The two services worth reclaiming (~600 MB each) are exactly the
two with unacceptable cold starts; the two that start instantly only hold ~100 MB
each. Tried and reverted socket activation on `anchor-docs` for this reason — do
not re-propose it without an SSD first.

There is no memory pressure to solve anyway: ~6 GB available and only ~310 MB of
the 15.5 GB zram in use.

**A SATA SSD is the single highest-value change to this box** and would cut those
cold starts roughly 10x. Space is not a constraint; seeks are.

Gotchas found while working here:
- `anchor-docs` and `anchor-studio` bind **`::1` only**, not `127.0.0.1`. Probe
  both families — `anchor-hub`'s `probe()` already does, deliberately.
- `anchor-hub`'s `probe()` opens a TCP connection to each service port, so any
  socket-activated service would be woken just by loading the hub page.
- Ports: `tailscale serve` exposes port+10000, `anchor-hub` proxies port+20000
  to rewrite the Host header Vite insists on.

See [[omarchy-privilege-escalation]].

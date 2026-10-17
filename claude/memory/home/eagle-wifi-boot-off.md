---
name: eagle-wifi-boot-off
description: eagle 2026-10-16 — three Wi-Fi faults (NM state file, card probe failure on warm reboot, iwd detour); NetworkManager is the stack; wifi-rescue is the recovery.
metadata:
  type: project
---

eagle (MacBook Pro, BCM4350 14e4:43a3 brcmfmac at 0000:02:00.0) Wi-Fi faults found 2026-10-16:

1. **NM state file had Wi-Fi off since install.** Journal tell: `rfkill: Wi-Fi disabled by radio killswitch; disabled by state file`. Fixed by drop-in `/etc/systemd/system/NetworkManager.service.d/wifi-on.conf` (rfkill unblock pre, `nmcli radio wifi on` post), staged from `~/.local/bin/wifi-boot-fix`. Verified after reboot 16:48.
2. **Card fails to probe on some warm reboots** (2 of 15 boots that day): kernel `brcmf_chip_recognition: MMIO read failed: 0xffffffff` / `brcmf_pcie_probe: failed 14e4:43a3`. No NM/iwd change can fix it. Mitigation: `wifi-card-check.service` runs `/usr/local/sbin/wifi-card-check` (source `~/.local/bin/wifi-card-check`) before NM — PCI remove + rescan up to 3x. **Unverified against a real failure** as of 2026-10-16. Cold power-on is the fallback.
3. **iwd detour.** At 18:23 another session swapped NM for iwd after misreading fault 2. That broke the bar icon (Quickshell.Networking reads NM over D-Bus only). Also iwd's `/usr/lib/systemd/network/80-iwd.link` (NamePolicy=keep) keeps the interface as `wlan0` instead of `wlp2s0`, and the 0311 NM profile was bound to `wlp2s0`, so NM would not auto-connect. Reverted 18:5x via `~/.local/bin/wifi-switch-to-nm` (self-reverting), which also cleared `connection.interface-name` on all Wi-Fi profiles. State verified 2026-10-16: NM active+enabled, iwd installed but disabled, wlan0 connected to 0311.

Recovery for the user: `wifi-rescue` (re-probes the card, restarts NM, falls back to iwd).
Bar icon stays "offline" after any NM restart until `omarchy restart shell`. Ground truth: `omarchy-network-status --verbose`.
Related: [[omarchy-privilege-escalation]], [[eagle-mbp-sound-camera]].

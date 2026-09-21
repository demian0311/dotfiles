---
name: sessions-run-on-anchor-from-eagle
description: "Claude Code here runs on anchor (Mac mini desktop) over SSH from the laptop eagle; desktop/input changes on anchor don't reach the laptop."
metadata: 
  node_type: memory
  type: project
  originSessionId: fd120be1-2e7a-4203-916e-3bdf008fbcf2
  modified: 2026-09-11T01:46:27.049Z
---

Claude Code sessions in this home dir run on **anchor** (Macmini6,2, no trackpad, Hyprland on tty2), reached over SSH via Tailscale from the laptop **eagle** (Linux, 100.112.106.67). Other Tailscale peers: demian-personal-air (macOS, 100.122.168.53), globe, mac-hm32xj06n0.

As of 2026-09-10, eagle refuses SSH on port 22 (no sshd, no Tailscale SSH), so anchor cannot reach eagle's desktop.

**Why:** On 2026-09-10 I added macOS-style Control+scroll zoom to anchor's ~/.config/hypr/bindings.lua. The user tested it with "the trackpad on this laptop" (eagle) and nothing happened, because the change was on anchor.

**How to apply:** When the user talks about "this laptop", their trackpad, the screen in front of them, or input and gesture settings, check `hostname`/`$SSH_CONNECTION` first. Desktop changes made here apply only to anchor's own monitor, keyboard and mouse (the LG ultrawide, the Apple keyboard and HP mouse). Related: [[anchor-mac-mini-hdd-bottleneck]], [[mac-mini-hdmi-pixel-clock-cap]].

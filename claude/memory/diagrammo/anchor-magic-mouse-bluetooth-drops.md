---
name: anchor-magic-mouse-bluetooth-drops
description: "anchor's Magic Mouse drops over Bluetooth; cause is BCM20702 USB autosuspend, fix staged but never installed"
metadata: 
  node_type: memory
  type: project
  originSessionId: 87ba64c3-3a9d-476b-9694-c7df56b1f7b6
  modified: 2026-09-16T02:32:22.563Z
---

anchor's Apple Magic Mouse 2 (`D8:30:62:42:EA:B0`, paired as "Demian Mouse") does
not hold a Bluetooth link. Diagnosed 2026-09-15 from the journal: six HID
re-enumerations between 2026-08-30 and 2026-08-31, repeated
`HIDP GET_REPORT request timed out`, one `killing stalled connection`, and two
`Host is down (112)` retry storms — then two weeks of silence, i.e. it was
abandoned. It reproduced within 70 seconds of reconnecting on 2026-09-15.

Cause: the adapter is an Apple **BCM20702** (`05ac:828a`, behind hub `0a5c:4500`,
three hubs deep) with USB autosuspend left at `power/control = auto`, so the
radio idles down under a quiet HID link.

**Why:** the pairing is fine and `bluetoothctl connect` always succeeds, so this
looks solved until the link dies minutes later — the failure is in USB power
management, not in bluez or the pairing.

**How to apply:** the fix is a udev rule pinning
`ATTR{power/control}="on"` for `05ac:828a`, at
`/etc/udev/rules.d/50-bluetooth-no-autosuspend.rules`. It was **written but
never installed** — anchor has no graphical polkit agent (only `polkitd`), so an
agent cannot `pkexec`, and `sudo` needs a password; the user must run the install
themselves. Re-create the rule rather than hunting for it; it was staged in a
session scratchpad that is now gone. If timeouts persist after installing it,
the answer is a separate USB Bluetooth dongle — the BCM20702 has failure modes
autosuspend does not explain. Over the USB Lightning cable the mouse is a plain
wired mouse and none of this applies.

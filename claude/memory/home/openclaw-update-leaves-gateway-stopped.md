---
name: openclaw-update-leaves-gateway-stopped
description: Running update.run from the OpenClaw control UI can stop the gateway and never restart it; fix is a plain systemctl --user start.
metadata:
  type: project
---

On anchor, triggering an OpenClaw update from the control UI can leave the
gateway down. The logs show `update.run ... status=skipped` (nothing to
install), then `received SIGUSR1; restarting`, a clean shutdown, and
`[gateway] restart mode: managed update handoff owns successor` — the gateway
defers starting the successor to the update handoff, systemd stops the unit,
and nothing ever starts it again. `Restart=always` does not cover it because
this is an explicit stop, not a crash.

Observed 2026-09-09 on openclaw@2026.9.1.

**Why:** The symptom looks like the update moved the gateway to a new port, but
the port never changes and the install is not broken — the unit is simply
inactive.

**How to apply:** Check `systemctl --user status openclaw-gateway` first. If it
is `inactive (dead)` with `status=0/SUCCESS`, just run
`systemctl --user start openclaw-gateway` — no reinstall, no port hunting.
Port topology on this box: gateway listens on 127.0.0.1:18789, anchor-hub
proxies it on 127.0.0.1:38789, and `tailscale serve` exposes that as
https://anchor.tailb10eb2.ts.net:28789/. The hub landing page at
https://anchor.tailb10eb2.ts.net/ renders the card as "Ready" once it is up.
See [[anchor-mac-mini-hdd-bottleneck]].

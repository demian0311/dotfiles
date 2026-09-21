---
name: openclaw-mcp-oauth-crash-loop
description: "A stdio MCP server (mcp-remote) stuck on expired OAuth crash-loops the OpenClaw 9.3 gateway; symptom is a \"connected but unresponsive\" Control UI."
metadata: 
  node_type: memory
  type: project
  originSessionId: 0a03e6eb-7a2c-40d6-bed8-6f368f6b0deb
  modified: 2026-09-11T13:01:19.315Z
---

On 2026-09-11 (openclaw@2026.9.3) the gateway crash-looped for ~12 min. The
Control UI still loaded and the WebSocket still answered, so it looked "up but
unresponsive". Every hop (18789 → hub 38789 → tailscale 28789) returned 200.

Chain: an agent run starts the bundle MCP servers → `cf-observability`
(`mcp-remote https://observability.mcp.cloudflare.com/mcp`) finds its token
refresh failing, prints an OAuth URL, and waits for a browser → OpenClaw gives up
after `connectionTimeoutMs` 15s → 9.3's child cleanup throws
`service child cleanup identity lost: anchor channel closed without a matching
closing receipt` as an **unhandled rejection**, and the gateway exits 1. Restart
recovery resumes the interrupted session, and the loop repeats. After 3–4
unclean boots in 5 min, the restart-loop breaker trips. It suppresses Telegram
autostart and tombstones the interrupted sessions (including `agent:main:main`,
so the heartbeat fails with "ended during restart recovery. Use /new or /reset").

**Why:** The gateway process and ports look healthy; the only clue is
`journalctl --user -u openclaw-gateway` showing `[bundle-mcp] failed to start
server` right before `Unhandled promise rejection`.

**How to apply:** Probe the server by hand. Pipe an `initialize` JSON-RPC line
into `BROWSER=echo timeout 25 mcp-remote <url>`. "Please authorize this
client" means the OAuth is dead. Set `"enabled": false` on that entry under
`mcp.servers` in `~/.openclaw/openclaw.json`; it hot-reloads, no restart. Then run
`openclaw gateway call channels.start --params '{"channel":"telegram"}'` and
`/new` in the tombstoned sessions. Restarting Telegram alone is not enough.
On 2026-09-11, Telegram came back at 04:31, but `agent:main:main` stayed
tombstoned. Bob then silently ignored every DM: the logs show `dispatch failed:
SessionRestartRecoveryTombstoneError ... dead-lettered`. The fix is `/new` in the
Telegram DM. The gateway also has a `sessions.reset` method. To re-auth, run `mcp-remote <url>` on anchor
itself, because the callback is `localhost:<port>` on anchor. A remote browser
needs an SSH `-L` forward for that port. OAuth cache: `~/.mcp-auth/mcp-remote-v1/`.
`cf-graphql` shares the setup and was healthy at the time.
Related: [[openclaw-update-leaves-gateway-stopped]], [[openclaw-claude-cli-owner-check]].

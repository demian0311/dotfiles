---
name: mcp-child-timeout-crashes-gateway-9-3
description: "On OpenClaw 2026.9.3 a stdio MCP bridge that times out at startup takes the whole gateway down (\"service child cleanup identity lost\"); disable the server, don't just raise timeouts."
metadata: 
  node_type: memory
  type: project
  originSessionId: 8091204c-e69a-4e0f-8b0e-3d8d410ed487
  modified: 2026-09-11T10:49:44.092Z
---

Night of 2026-09-10/11: gateway crashed 17 times (00:12 → 04:26), every one within
milliseconds of `[bundle-mcp] failed to start server "cf-observability" … timed out`.
The cleanup of the timed-out child throws `service child cleanup identity lost: anchor
channel closed without a matching closing receipt` (`dist/child-*.mjs` `loseIdentity`)
as an **unhandled rejection → process exit 1**. Hourly crashes at :07 were the Outside
voices automation (`7 * * * *`) spawning the bridge; the clusters were restart recovery
re-running a session, which spawns the bridge again, and crashing ~17s after boot. That
burned the recovery budget and **tombstoned `agent:main:main`** (Telegram's route), so the
heartbeat and any Telegram DM fail with "ended during restart recovery. Use /new or /reset".
The 03:00 nightly gate died as "job interrupted by gateway restart".

This time the bridge hung because the grant really was dead: `4c540779…_tokens.json` frozen
at 23:07 while 20 fresh `code_verifier` files accumulated, and a hand probe got "Proactive
token refresh failed" → authorize URL. Unlike [[mcp-tool-absent-is-a-timeout]], the
token-file mtime not moving for hours while cf-graphql's refreshes is the tell.

**Why:** any hanging stdio MCP child is a gateway kill switch on 9.3, independent of cause.
**How to apply:** when the gateway crash-loops, grep the journal for `bundle-mcp] failed to
start` just before each `Unhandled promise rejection`. Mitigate with
`openclaw config set mcp.servers.<name>.enabled false` (hot-reloads); re-enable only after
a hand probe of the bridge returns tools. A hand-run `mcp-remote` is not a gateway child
and is safe to probe with. Mitigation applied 2026-09-11 04:31; backup
`~/.openclaw/openclaw.json.bak-cf-obs.1789122654`.

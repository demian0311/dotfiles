---
name: mcp-tool-absent-is-a-timeout
description: "An MCP tool missing from a child's toolset means the 1500ms catalog-list timeout fired, not that the server's OAuth grant died."
metadata: 
  node_type: memory
  type: reference
  originSessionId: 3556a5fe-bcd2-4189-b16b-5c84c1bf2d49
  modified: 2026-09-18T02:38:02.250Z
---

OpenClaw builds each child's MCP toolset under `BUNDLE_MCP_CATALOG_LIST_TIMEOUT_MS = 1500`
(`dist/agents/agent-bundle-mcp-runtime.js`). A cold `mcp-remote` stdio bridge needs ~3.7s to
answer `initialize` and ~7.0s to answer `tools/list`, so any child that spawns while no bridge
is already warm gets an empty catalog and the tool simply isn't there. `openclaw mcp probe`
uses the same 1500ms ceiling, so it reproduces the bug instead of measuring the server.

Raise it per server — this overrides the constant and applies without a gateway restart:

    openclaw config set mcp.servers.<name>.requestTimeoutMs 20000
    openclaw config set mcp.servers.<name>.connectionTimeoutMs 15000

Verified 2026-09-09 on `cf-observability`: probe went from "tool listing timed out after
1500ms" to "8 tools" in 9.8s. The OAuth grant was healthy throughout — its token file had
been refreshed one minute before the run that reported itself blind.

**A gateway restart reopens this at a much higher ceiling.** 2026-09-17: the gateway was
restarted 18:29 and took ~3 min to finish starting (slow SQLite transaction on the way up).
A session opening at 20:32 reported both Cloudflare servers `CONNECT_TIMEOUT` after
**30000ms** — far past the ~3.7s a cold bridge needs, so coldness alone does not explain it;
the bridges were contending with a gateway that was itself still settling. Five minutes later
`openclaw mcp probe cf-observability` answered *8 tools*, exit 0, and both token files in
`~/.mcp-auth/mcp-remote-v1/` carried a 20:07 mtime — the grants had refreshed cleanly on
their own. Nothing was wrong and nothing needed fixing.

So the per-server timeouts above did not eliminate the failure mode, they moved it: the
session-level connect attempt has its own 30s budget that a restart-adjacent bridge can still
miss. **The MCP servers are per-session, so one session's CONNECT_TIMEOUT says nothing about
the next session's** — a scheduled job that spawns its own session (the 05:00 digest) is not
blind merely because an interactive session was.

Same shape as [[find-is-bfs-not-gnu]]: a probe whose failure is indistinguishable from a
clean negative. Ask what it reports when the thing is *present* before trusting it about
absence. Token-file mtime is the only real evidence about a grant.

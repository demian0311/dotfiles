---
name: disabling-mcp-server-kills-its-grant
description: "Disabling an mcp-remote server in config starves its OAuth refresh, so the grant dies of disuse and re-enabling alone never fixes it — authorize first, enable second."
metadata: 
  node_type: memory
  type: reference
  originSessionId: d2c7f92b-4cbc-4826-9bad-a6851d935c40
  modified: 2026-09-17T10:37:55.476Z
---

An mcp-remote bridge refreshes its OAuth token only when it runs. Setting `enabled: false` on the server means no bridge ever starts, so nothing refreshes the grant and it expires from disuse. Re-enabling then makes the gateway spawn a bridge that blocks waiting for authorization — the hang associated with the 2026.9.3 `service child cleanup identity lost` crash. **So the mitigation for the crash is what kills the grant, and enabling before authorizing is the dangerous order.**

Measured 2026-09-16: `cf-observability` was disabled to stop that crash; its token file had not moved since 2026-09-10, while `cf-graphql`, left enabled, refreshed cleanly every morning. A hand-run bridge went straight to "Authentication required" with no successful refresh — which is the bar for telling Demian a browser consent is genuinely needed.

**Correct order, proven 2026-09-17:** run a bridge by hand to get a live authorize URL, have him open it on the host, confirm the grant by the token file's mtime moving (the browser's "Authorization successful" page is not evidence), then enable in config, then probe. Result was 8 tools exit 0, gateway 0 restarts, no crash signature.

**How to apply:** never claim a bridge is dead from a missing tool alone — see [[mcp-tool-absent-is-a-timeout]] for the timeout case, which looks identical. Check the token file's mtime against a sibling server's to tell a starved grant from a cold-start timeout. And never verify a hand-run bridge with `pgrep -f <url>`: the check's own command line contains the URL, so it matches itself and always reports alive. Use the listening callback port instead.

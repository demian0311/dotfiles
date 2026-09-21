---
name: openclaw-claude-cli-owner-check
description: "Since OpenClaw 2026.9.3 the claude-cli backend rejects a shell-script `claude` on the gateway PATH (\"cannot be bound to one durable absolute owner\"); fixed by ELF symlinks in ~/.local/share/pnpm."
metadata: 
  node_type: memory
  type: project
  originSessionId: d5154097-c1da-4a66-8ae6-255d569ca2e9
  modified: 2026-09-10T22:43:01.150Z
---

OpenClaw 2026.9.3 added an executable-owner check to the claude-cli backend. It
resolves bare `claude` on the gateway service PATH (config cannot override the
command) and accepts only a native ELF named `claude`, or a script inside the
`@anthropic-ai/claude-code` package tree. On anchor the service PATH used to
land on `~/.local/bin/claude`, the mise wrapper script, which fails with
`CLI backend claude-cli executable cannot be bound to one durable absolute owner`.
`~/.openclaw/bin/claude` is also a script, and it is not on the service PATH anyway.

Normal chats keep working; only setup-inference probes ("Ask OpenClaw" in the
Control UI) and update post-install verification fail. The 2026-09-10
9.1→9.3 update therefore ended with reason `managed-service-handoff-unsafe-recovery`
(`runtime-verification-failed`, updater exit 79). By design, that path leaves the
gateway stopped, and 9.1 can no longer open the migrated schema-16 state DB, so
rollback was impossible. The gateway came back on 9.3 at 16:23.

Fix (applied 16:27 by the OpenClaw agent Bob): symlinks
`~/.local/share/pnpm/claude` and `~/.local/share/pnpm/bin/claude` →
`~/.local/share/mise/installs/claude/latest/claude`. `~/.local/share/pnpm` is
ahead of `~/.local/bin` in the unit PATH.

**Why:** The failed-update banner blames the update, but the install is fine.
The real fault is which `claude` the service PATH finds.

**How to apply:** If the error comes back, check
`PATH=<unit PATH> which -a claude`; the first hit must resolve to the ELF.
After any PATH or symlink fix, **restart the gateway**. It caches executable
lookups in memory (`executable-path-*.mjs`, a 60s TTL that renews on every
hit), so a running gateway keeps the old answer. On 2026-09-10 it still failed
at 16:40, 13 minutes after the symlink went in, while a fresh process
resolved correctly. The
symlinks may disappear after pnpm or mise cleanup. Do not use a systemd drop-in
to override ExecStart; `Environment=` drop-ins are supported.
`openclaw models status --probe` refuses to run while the gateway is up. To
verify, use Ask OpenClaw and watch `journalctl --user -u openclaw-gateway`.
Related: [[openclaw-update-leaves-gateway-stopped]].

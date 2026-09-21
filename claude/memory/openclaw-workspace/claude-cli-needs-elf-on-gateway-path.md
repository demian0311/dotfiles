---
name: claude-cli-needs-elf-on-gateway-path
description: "Since OpenClaw 2026.9.3 the claude-cli backend refuses a shell-script `claude` on the gateway PATH (\"cannot be bound to one durable absolute owner\"); the mise shim is a script."
metadata: 
  node_type: memory
  type: project
  originSessionId: 0c82cf41-bc88-4feb-beb7-2114a07efc59
  modified: 2026-09-10T23:04:49.398Z
---

OpenClaw 2026.9.3 added an executable-identity check (`resolveCliExecutableIdentity` → `resolvePosixIdentity` in `dist/cli-auth-epoch-*.mjs`). It runs on auth-bound or tool-availability runs, e.g. the Control UI's `probe-setup-inference`. A `claude` that resolves to a `#!` script outside a package tree is UNBOUND, and the error is `CLI backend claude-cli executable cannot be bound to one durable absolute owner`. The gateway unit's PATH hit `~/.local/bin/claude`, which is the mise shim (a bash script), so every Control UI chat failed after the 9.1→9.3 update on 2026-09-10. Heartbeat/Telegram turns kept working because they don't go through that check.

Fix applied 2026-09-10 16:27 MDT: symlink `~/.local/share/pnpm/claude` → `~/.local/share/mise/installs/claude/latest/claude` (the ELF). `~/.local/share/pnpm` comes before `~/.local/bin` in the unit PATH. `realpath` is followed, so the basename `claude` matches `nativeExecutableNames` → `self-contained-executable`.

**It did not take effect in the running gateway.** A dashboard chat at 16:40 on the old pid still failed, even though an out-of-process test using that pid's startup environ bound fine. After a supervisor restart at 16:46 (not mine), the new gateway's claude children run with argv0 `~/.local/share/pnpm/claude`, so the spawn goes through the symlink. There's no identity memo (one caller, no cache); the path cache TTL is 60 s. The cause on the old process is unproven. Suspect runtime `process.env.PATH` mutation (`path-env-*.mjs`, `gmail-watcher-*.mjs` both assign it). `/proc/<pid>/environ` only shows startup env; the PATH of a live child is the truthful runtime sample.

**Why:** there is no `openclaw.json` key for the backend `command`. The docs say the gateway must find `claude` on PATH, or else you need a CLI backend plugin.

**How to apply:** if Control UI chats fail with that error again, run `readlink -f` on the first `claude` in a live gateway child's PATH. It must end at an ELF. After changing what's on PATH, expect to need a gateway restart. Related: [[gateway-unit-pins-pnpm-version-path]].

---
name: app-probe-worktree-shares-dgmo
description: a second diagrammo-app worktree linked to the same private dgmo checkout repoints its node_modules on install
metadata:
  node_type: memory
  type: feedback
  originSessionId: 15bcfeed-c20e-4e34-8f5e-a9c27be1b9ca
  modified: 2026-10-16T05:54:59.551Z
---

Never link two diagrammo-app worktrees' `packages/dgmo` to the same dgmo worktree. `pnpm install` in an app worktree walks `packages/dgmo` (workspace glob) and repoints that dgmo's `node_modules` into the installing worktree's `.pnpm`. Removing the second worktree then leaves 52 dangling links, and every test run in the first one is invalid.

**Why:** 2026-10-15 night slot 5 (#1211): a `diagrammo-app-probe-1211` at origin/main (for "before" screenshots) shared `~/.cache/bob/dgmo-1211` with the build worktree; its install ran while round-1 gate tests ran, and its removal broke the links. Caught by `find <dgmo>/node_modules -maxdepth 2 -xtype l | wc -l`; fixed by re-running `pnpm install` in the build worktree and re-running the round.

**How to apply:** a before/after probe gets its own dgmo worktree, or runs after the build's tests finish and is followed by a reinstall in the build worktree. Related: [[anchor-installed-launchers-drift]].

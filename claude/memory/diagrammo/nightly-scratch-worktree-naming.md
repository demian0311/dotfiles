---
name: nightly-scratch-worktree-naming
description: Never name a scratch dgmo/dgmo-content worktree <repo>-wt-issue-<n> in a nightly build — nightly-land.sh treats it as a repo of the row
metadata:
  node_type: memory
  type: feedback
  originSessionId: ffd45c04-890f-4f02-8b8b-7dddb3b091a7
  modified: 2026-10-15T07:31:41.981Z
---

In a nightly build slot, the diagrammo-app worktree needs its own dgmo and dgmo-content checkouts. On 2026-10-14 (lane B slot B5, the analytics opt-in row #1174) the content one was named `~/code/diagrammo/dgmo-content-wt-issue-1174`. `nightly-land.sh` globs every `*-wt-issue-<n>` under `~/code/diagrammo`, read it as a second repo of the row, "pushed" it (Everything up-to-date), and stopped before the app. Nothing broke; removing the worktree and re-running the land merged the app.

**Why:** the land script finds a row's repos by worktree name, not by the claim's `--repo` list.

**How to apply:** name the dgmo-content scratch worktree without the `-wt-issue-<n>` suffix — e.g. `~/code/diagrammo/dgmo-content-scratch-<n>` (it must be a `~/code/diagrammo` sibling, never `.gate-*` and never under `/tmp`: on 2026-10-15, slot B7, the #1039 build put it in `/tmp` and `test:gate` failed 6 files with `Denied ID /tmp/…?raw`, because `vitest.config.ts` `server.fs.allow` covers only the workspace and `packages/dgmo`). Put the dgmo one under `/tmp`. Remove both after the land. Related: [[installed-launchers-drift]].

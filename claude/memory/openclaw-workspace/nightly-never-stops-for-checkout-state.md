---
name: nightly-never-stops-for-checkout-state
description: "Owner ruling 2026-09-14 — dirty/uncommitted/diverged checkouts must never stop a nightly run; orphaned WIP gets committed, not asked about."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 88d07ae9-ca06-45a8-9e0e-2ef8b2f14f81
  modified: 2026-09-15T00:13:22.034Z
---

When uncommitted work is found sitting in a shared diagrammo checkout, land it
(review, tests, merge) rather than asking whose it is. And no checkout state may
ever stop a nightly run — the launchers read playbooks from `origin/main`, not the
working tree.

**Why:** Demian, 2026-09-14 18:12, on 660 lines of orphaned close-out changes:
"just commit and carry on, things like this should never stop a run ever." Asking
him was an engineering question dressed up as his call.

**How to apply:** Don't escalate "is this yours?" — land it. Treat any launcher
path that cancels a night over checkout state as a bug. Related:
[[unstaged-root-change-kills-nightly]].

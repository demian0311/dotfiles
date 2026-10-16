---
name: node-abort-nightly-vitest-root
description: node SIGABRT 2026-09-30 22:09 on anchor = V8 heap OOM from a nightly-issue-run agent running vitest with --root /
metadata:
  node_type: memory
  type: project
  originSessionId: 1516ca58-4c98-498e-b6b9-784c77a46d63
  modified: 2026-10-02T12:47:31.862Z
---

Crash PID 2559544, 2026-09-30 22:09:37 MDT (core written 22:14:02). Frame #4 `node::OOMErrorHandler`; main thread in `fs.scandir` callback, 4 libuv workers in `scandir`/`getdents64`. Cmdline `vitest run --root / /tmp/rev954/probe.test.ts`, cgroup `openclaw-gateway.service`. V8 heap limit ~4 GB (node 26.7.0 default); no kernel OOM.

Attribution (verified 2026-10-02): only OpenClaw job running then was cron `nightly-issue-run` (21:00–00:00, `~/.openclaw/state/openclaw.sqlite` → `cron_run_receipts`/`task_runs`). Issue #954 (dgmo screen-reader text summary) got three slices that night. `/tmp/rev954` = probe for #954 is INFERENCE — no log, transcript or db row contains "rev954"; tool commands of cron runs are not persisted anywhere found (`~/.diagrammo/nightly-issues/<date>/agent-slot-*.log`, `worker_session_tool_operations` empty).

Runbook `~/code/diagrammo/scripts/nightly-issue-run.md` (probe section ~L1100–1150) says probes run in worktrees cut from origin/main, saved to `$LOG_DIR/probe-<n>` — a /tmp probe with `--root /` violates it.

**Why:** next node crash in the openclaw cgroup, start at the cron tables, not session files (sessions dir stopped receiving transcripts after 2026-09-20).
**How to apply:** see [[rust-lld-sigbus-tmpfs-quota]] for the other agent-caused crash on anchor.

**Recurrence 2026-10-12 10:20:57 (verified 2026-10-15):** PID 2686433, same `OOMErrorHandler` abort, vitest 4.1.8 forks worker in `dgmo-wt-issue-1097`, unit `bob-bob-day-20261012-090000.service` (daytime bob-day run, not openclaw). Strings in the core: `/tmp/rev1097/cmp.test.ts` + `/tmp/rev1097/base/src/**` = the slot-3 reviewer's 768-render base-vs-branch jsdom comparison. It sits between review-bundle (10:14:21) and review reply (10:24:22) in `~/.diagrammo/bob-day/2026-10-12/`. Review still ended PASS and #1097 landed `d745f11f`, so nothing was lost. Reviewer reply does not mention the crash. Main thread was deep in JIT frames, not scandir, so `--root /` is NOT shown this time. /tmp/rev1097 already deleted. Pattern: reviewer/probe agents write ad-hoc vitest harnesses in /tmp and hit the ~4 GB default V8 heap.

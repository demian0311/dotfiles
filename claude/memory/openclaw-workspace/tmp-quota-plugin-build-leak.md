---
name: tmp-quota-plugin-build-leak
description: "\"Unknown system error -122\" on a subagent write is EDQUOT on /tmp — OpenClaw leaks /tmp/openclaw-plugin-build-* dirs (~341 MB each) until the tmpfs usrquota fills."
metadata:
  node_type: memory
  type: project
  originSessionId: 73fe31a9-4d6c-4a51-b7ee-889ce87d81dc
  modified: 2026-09-24T11:43:27.745Z
---

2026-09-24 05:37: both subagents spawned for the morning decisions died instantly with `Unknown system error -122, write` and no output. Errno 122 = EDQUOT. `/tmp` is tmpfs mounted `usrquota`; it held 12 leaked `openclaw-plugin-build-*` dirs (341 MB each, one per gateway plugin build/restart since 09-23 13:50) plus a 1.4 GB `openclaw-model-catalog-*` left by the 09-23 update. `df` showed 80% so it didn't look full — the per-user quota binds before the filesystem does.

Fix applied: removed the 10 oldest plugin-build dirs (lsof showed none open), kept the newest two. /tmp went 6.3G → 2.9G.

**Why:** `df` reads not-full while the quota rejects writes, and -122 surfaces as an opaque "Unknown system error".
**How to apply:** on -122, check `du -xsh /tmp/openclaw-*` first. Recurs until the leak is fixed upstream or a cleanup job exists. Related: [[auto-disabled-automation-is-silent]].

**Fixed locally 2026-09-24 05:52** — hourly user timer `openclaw-tmp-reaper.timer` (dotfiles `34c9b7a`, script `~/code/dotfiles/bin/openclaw-tmp-reaper`). Producer here is **one capture per isolated automation run** (03:20 and 03:35 jobs each left one; gateway pid unchanged since 09-23 13:50). Upstream: openclaw/openclaw#156571 (open, P0). 2026.9.6 ships #154324 (CLI runs) + #153468 (catalog after crash) + #155159 (reuse); #156427 (SDK imports re-staging) is NOT in 9.6. So 9.6 may not stop the isolated-run producer — keep the reaper until a week on a fixed release shows no new captures. Reaper never touches `openclaw-model-catalog-*` (live worker lazily imports from it) nor captures from the gateway's first 15 min. Deleting the 09-23 13:50-era captures caused no "Cannot find module" errors.

**9.6 update attempt 2026-09-24 06:06–06:19 ROLLED BACK** (run b541e334, chat-triggered update.run). Candidate doctor failed `authority-check-failed: Maximum call stack size exceeded` in update-history reconciliation → package rollback verified, gateway back on 2026.9.5 at 06:17, healthy. Upstream openclaw/openclaw#157011 (many reporters, steipete: fix lane opened 08:28Z — cycle-safe traversal + doctor repair). Reported workarounds: CLI-triggered `openclaw update --yes` from a shell sometimes passes; pinned manual `npm install -g` works — both forbidden to me via exec, so wait for the fix release and retry via update.run. Log: /tmp/openclaw-update-run-handoff-aKMnyT/handoff.log. /tmp 17% after; reaper enabled.

**Watcher 2026-09-24 06:56:** automation 8ed0fd57 ("Watch for OpenClaw update-rollback fix", cron 08/12/16/20 Denver, main systemEvent) — on a release > 2026.9.6 or #157011 closed with a released fix, runs update.run (Demian picked it 06:55), schedules a verify, removes itself. Silent otherwise. Hours avoid the 21:00–04:00 nightly window.

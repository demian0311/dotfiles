---
name: chrome-trap-tmp-quota
description: chrome-headless-shell SIGTRAP storm 2026-10-05 02:03–02:10 on anchor = /tmp usrquota exhausted during diagrammo nightly-gate test:e2e:web
metadata:
  type: project
---

2026-10-05 02:03–02:10 MDT: ~10 Playwright chrome-headless-shell (chromium_headless_shell-1223) processes trapped (int3 = Chromium CHECK/IMMEDIATE_CRASH), cgroup `openclaw-gateway.service`. Only job running: cron `nightly-gate` (02:00–02:11, step `test:e2e:web`, 4 workers, 8 failed). Log `~/.diagrammo/nightly/2026-10-05/logs/test-e2e-web.log` has 4× `FATAL:font_data_service_impl.cc:377 Check failed: : Disk quota exceeded (122)` at 02:06:19–22. Playwright passes `--disable-dev-shm-usage`, so Chrome shared memory goes to /tmp (tmpfs, `usrquota`). Earlier traps (Compositor thread, e.g. PID 1720410 at 02:04:20) logged no message; same quota cause is INFERENCE. No kernel OOM. /tmp at 5.6 G owned by demian afterwards; biggest: `/tmp/node-compile-cache` 2.5 G, `/tmp/playwright-transform-cache-1000`, agent probe dirs.

**Why:** third agent-caused crash from the /tmp quota; see [[rust-lld-sigbus-tmpfs-quota]], [[node-abort-nightly-vitest-root]].
**How to apply:** any Chrome/Playwright SIGTRAP storm on anchor → grep the gate log for `Disk quota exceeded` and check /tmp usage first.

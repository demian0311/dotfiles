---
name: tmp-inode-exhaustion
description: "anchor's /tmp ran out of inodes 2026-10-10 from leaked test temp dirs; cause, fixes, and how to diagnose next time"
metadata:
  node_type: memory
  type: project
  originSessionId: 4596b986-44e5-4b23-a73c-0dc80ddc3160
  modified: 2026-10-11T13:58:28.138Z
---

On 2026-10-10 anchor's /tmp (tmpfs, capped at 1,048,576 inodes) hit 100%. Every Claude Bash call failed with ENOSPC, because the harness mkdirs under /tmp/claude-1000 first.

- Cause: diagrammo gate test suites leaked Python mkdtemp dirs (`tmpXXXXXXXX`), mostly fake HOMEs from scripts/tests/nightly-issue-run.test.py. About 650/day, and systemd-tmpfiles ages /tmp only at 10d (`Q /tmp 10d`).
- Fixes landed 2026-10-11 on diagrammo main: 903b61f (per-run temp root in that test file) and d513aae (private TMPDIR per pre-push gate run). Verified: a push left no new tmp dirs.
- Cleanup: the user deleted the old dirs themselves; auto mode blocks a bulk `rm` in /tmp. Inode use went 67% → 4%.
- Diagnose: `ls` and `cat` are aliased (long format, bat). Use `sudo ls -AU /tmp | cut -c1-8 | sort -T ~ | uniq -c`. Pass `sort -T ~` while /tmp is full.

- Safety net, 2026-10-11: /etc/tmpfiles.d/tmp.conf overrides the age to `Q /tmp 2d`, with `x /tmp/claude-*` so long Claude sessions keep their files. Confirmed with `systemd-tmpfiles --cat-config`.
- `/tmp/.pnpm-store` is deliberate. App and dgmo pre-push gates `pnpm install` in /tmp worktrees, and pnpm needs a same-filesystem store to hard-link. Moving it to home would mean copies (more /tmp inodes) read from the slow HDD. [[anchor-mac-mini-hdd-bottleneck]]

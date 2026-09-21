---
name: anchor-installed-launchers-drift
description: Launchers in ~/.diagrammo/*.sh on anchor can be newer than main; diff before re-running a nightly installer
metadata: 
  node_type: memory
  type: project
  originSessionId: 88cdf8b2-49c0-4b3e-a51a-cf9e66b70bef
  modified: 2026-09-15T00:44:23.909Z
---

On 2026-09-14 the installed `~/.diagrammo/nightly-closeout.sh` was built from another session's uncommitted work, so it was newer than `scripts/install-nightly-issue-run.sh` on main. A full re-install would have silently rolled it back. The installers have no `anchor` wrapper on anchor itself (hostname `anchor`, no `bin/anchor`). Since the retro work, the issue-run installer falls back to running locally and has `--only retro`.

**Why:** installers rewrite every launcher they own, and `cron add --declaration-key` re-registers every job.

**Resolved 2026-09-14 18:44:** the stranded close-out work landed as `e8900c6`. A full install from `34a14b3` left all four launchers byte-identical to main. Since `34a14b3`, every launcher fetches and reads its playbook from a copy of `origin/main:scripts/` in its log dir (`origin-main/`), not from the working tree. A dirty or diverged root checkout is only recorded (`REFUSED` in pull.txt); it no longer cancels a night.

**How to apply:** before running `install-nightly-issue-run.sh` or `install-nightly-gates.sh`, extract each heredoc and diff it against the installed file. Install only the part you own if they differ. See [[nightly-retro-job]].

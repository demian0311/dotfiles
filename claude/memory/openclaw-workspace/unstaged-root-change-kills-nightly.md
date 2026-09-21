---
name: unstaged-root-change-kills-nightly
description: "Any unstaged change in ~/code/diagrammo aborts the whole nightly issue run, because pull.rebase=true makes the launcher's pull --ff-only refuse."
metadata: 
  node_type: memory
  type: project
  originSessionId: f107fa7a-1161-45ee-9b8a-de0506359425
  modified: 2026-09-12T03:34:36.600Z
---

`~/code/diagrammo` has `pull.rebase` true, so `git pull --ff-only` fails with
*"cannot pull with rebase: You have unstaged changes"* for ANY modified tracked
file — even one the incoming commits never touch. The nightly launcher reads that
as `root: REFUSED — the checkout could not fast-forward; the playbook may be
stale` and performs **nothing**: no claim, no build, no merge, for the whole night.

Happened 2026-09-11: close-out work left unstaged in the morning cost the 21:00
run its entire window (17 rows queued). Fixed by committing named paths and
pushing (`6b4ba72`), then relaunching with `openclaw cron run <job-id>` — there
is no `--force`; a bare `cron run` runs it now.

**Why:** the failure looks like repo divergence but is only dirtiness, and the
launcher cannot tell them apart.
**How to apply:** never leave the root checkout dirty past the evening; check
`git -C ~/code/diagrammo status --porcelain --untracked-files=no` before 21:00.
Untracked files are safe — see [[never-git-add-all-in-diagrammo-root]] for why
they must stay unstaged.

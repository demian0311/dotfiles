---
name: git-workflow
description: Where to do the work and how to land it — the free-vs-occupied check that decides between main and a worktree, what landing includes, leftover branches at session start, and why another session's work is not yours to advance. Load when starting work in a repo, choosing a branch or worktree, or finishing and landing a change. The two absolute prohibitions (never --amend, never checkout -- a tracked file) stay in CLAUDE.md and are not repeated here.
---

# Git — I drive it, the user never tracks a branch

The user is not a git specialist and does not want to be. They want work that doesn't
collide with other work, and when it's finished they want it on main and ready for the next
release — without holding any branch in their head. **Never ask them a branching, merging,
or cleanup question.** Decide, do it, report in one line.

## Choosing where to work — check first, every time

1. `git status --short` and `git branch --show-current` in the target repo.
2. **Repo is free** (clean tree, on main): work directly on main. No branch, no worktree.
3. **Repo is occupied** (dirty tree, or checked out on someone else's branch): create a
   worktree — `git worktree add ../<repo>-wt-<slug> -b <slug>` — and do all edits and
   commits through that path. Tell the user the path and branch in one line, then carry on.

## Landing is part of the task, not a follow-up

The moment work is verified:

- commit (explicit paths), then merge to main if it was on a branch, then push
- delete the branch and remove the worktree in the same breath — `git worktree remove <path>`
  then `git branch -d <slug>`
- **A finished task leaves nothing behind:** no branch, no worktree, no dirty tree, nothing
  unpushed

If the work genuinely must not ship yet, that is the ONE case where a branch survives a task
— and it comes with an explicit sentence saying so, why, and what would unblock it. Silence
plus a lingering branch is the failure mode.

## At session start, in a repo you're about to touch

If there are leftover branches or worktrees, say so in one line and offer to land or delete
them as a lettered choice. Don't launch an audit; don't ask them to decide anything they'd
need git knowledge to answer.

## Several sessions run at once

**Commit promptly.** A long-lived dirty tree is what another session's `git add -A` or
`git commit -a` sweeps up. Finish, commit, push — don't leave work sitting uncommitted across
turns.

Work owned by another session — its branch, its worktree, its uncommitted files — is not
yours to advance, deploy, or offer as a next step unless asked. Editing files it has not
touched is fine; staging its files is not.

---
name: memory-is-in-a-public-repo
description: Memory notes now live in the public dotfiles repo — what that means for writing them, and what the gitleaks guard does and does not catch.
metadata:
  type: feedback
---

**2026-09-21 (dotfiles #3):** memory moved out of `~/.claude/projects/<slug>/memory`
and into `claude/memory/<pool>/` in the dotfiles repo, symlinked back by
`claude/link-memory.sh`. That repo is **PUBLIC** — `visibility=PUBLIC`, public since
2014-01-24.

**Why:** memory was in no repo, so a worktree started blind and the second machine had
nothing. Reusing the repo that already self-syncs beat building a second mechanism.
See [[claude-code-context-budget]].

**How to apply — every note is now written for a public audience.**

- No credential, obviously. But also no *map* to one: `anchor-home-backups.md` was held
  back at `~/.claude/memory-local/` because it says where the restic passphrase lives and
  that only two copies exist. The index carries a line saying it exists.
- Hostnames, paths and machine names are already public in this repo; tailnet names are
  useless off the tailnet. Customer or employer specifics are not, and none are there today.
- 🔴 **A public git history cannot be un-published.** One bad commit is permanent.

🔴 **What the `gitleaks` pre-commit guard does NOT catch, measured 2026-09-21:**

- A synthetic **GitHub PAT** → refused. Good.
- A synthetic **AWS access-key id alone** → passed. The rule wants the secret key with it.
- `AKIAIOSFODNN7EXAMPLE` → passed; it is AWS's documented example and allowlisted.
- 🔴 **Prose is invisible to it.** "The passphrase lives at `~/.config/restic/password`
  and nowhere else" matches no rule. The one note that actually needed holding back would
  have sailed through.

The guard is a floor against pasted credentials, not a review. The review is reading the
note before writing it.

Pools are kept separate rather than merged: one pool would put every `MEMORY.md` line in
front of every session (~3k tokens), against ~1k per project.

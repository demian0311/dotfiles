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

🔴 **Pooling is OPT-IN since 2026-09-21 — a pool reaches this repo only if it is named
in `claude/memory/PUBLIC`.** `link-memory.sh` acts on whatever directory the session
happens to be in, so the original default published any project a session was opened in.
On the Mac that was **691 notes across ten projects**, 658 of them the whole Diagrammo
corpus — its private repo layout, Cloudflare setup, tracker, billing state and the
gitleaks findings. Measured, not inferred: the ungated script moved the notes in, renamed
the live 66 KB `MEMORY.md` to `.local` because the pool already held a 539 B one, then
failed its `rmdir` and left the directory with **no link and no notes**, so that project
would have read nothing at all. Listed today: `home`, `openclaw-workspace`, `dotfiles`.
Diagrammo and `Work` are deliberately not.

- **Adding a name is the publish.** Every note the pool holds and every note written into
  it afterwards, permanently.
- A pool already linked in but absent from the list prints `WARN` every run rather than
  being silently unlinked — unlinking would strip the other machine of notes it is using.
- ⚠️ `Work/anchor-omarchy-branding.md` was published before the gate existed and is still
  in the history.

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

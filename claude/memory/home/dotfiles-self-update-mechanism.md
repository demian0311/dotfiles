---
name: dotfiles-self-update-mechanism
description: Why install.sh --pull and plugins-sync.sh are shaped the way they are, and the three incidents that shaped them.
metadata:
  type: project
---

The dotfiles repo updates itself on unattended machines. The rules live in
`claude/CLAUDE.md` → *Where Rules Live*; this is the case file behind them.

**`install.sh --pull` added 2026-09-18** (dotfiles #859), because nothing else fetched
the repo on a machine nobody was sitting at. It spawns `claude/pull-dotfiles.sh`
detached — refuses a dirty tree, pulls `--ff-only`, re-runs `install.sh --quiet` if the
pull moved anything. Throttled to once per 15 minutes, logged to
`~/.claude/dotfiles-pull.log`. The spawn measured **127 ms** against the SessionStart
hook's 10-second timeout; blocking on the network there would have cost the re-link and
the settings repair on a slow connection, not just the update.

**Wired into both overlays 2026-09-20.** It was `settings.linux.json` only, on the
reasoning that the Mac is where edits originate and its tree is routinely dirty so the
guard would skip it anyway. True — but that makes it useless on a dirty tree rather than
harmful, and it earns its place on the occasions the tree is clean. Nothing blocked it
technically: `pull-dotfiles.sh` uses no bash-4 constructs, so it is safe on macOS's bash
3.2, and `settings-sync.py` already picks the overlay from `uname`.

**The disarm, observed on anchor 2026-09-18**, testing exactly that: a `git reset --hard`
below the commit that added the pull both deletes `pull-dotfiles.sh` and regenerates
`settings.json` without `--pull`, because the hook's command line comes out of the repo.
After that nothing fetches and nothing says so. A Mac also has to pull once by hand to
receive the change that makes it pull, since the fix cannot arrive by the mechanism it
installs.

**Plugin version reconciliation, 2026-09-18** (dotfiles #860). Having a plugin is not
being in sync: each machine gets whatever the marketplace served on install day, and
hours after both were set up `frontend-design` was `ea0a38e1d671` on one and
`c447c3207a42` on the other. There is no way to ask for a specific version —
`claude plugin install` has no `--version`, and `claude plugin list --json --available`
carries no version field and omits anything already installed, so a version cannot even
be compared before acting. The one question the CLI answers is "update it and see":
`claude plugin update <id> --json` returns `updateOutcome` as `updated` or `up_to_date`
with `oldVersion`/`newVersion`. So the machines converge on latest, not on a reviewed pin.
The catalog must be refreshed first — `plugin update` resolves "latest" from the local
marketplace clone, so without `claude plugin marketplace update` it reports `up_to_date`
forever against whatever was cloned on install day.

🔴 **`install.sh` spawns the background sync on the STALENESS CLOCK or a missing plugin —
`||`, never `&&`.** `--check` is local and cheap and can only see absence; gating on it
deadlocked the version pass, because a stale catalog reports everything present and so
nothing ever refreshed the catalog. Proved both ways on 2026-09-18.

**The live file wins a contested key, observed 2026-09-21.** `settings-sync.py` adopts
drifted top-level keys from `~/.claude/settings.json` into `settings.base.json` *before*
regenerating. So adding fourteen entries to an existing `skillOverrides` map in the base
was reverted on the next `install.sh` run: the live file still held the one-entry version,
that got adopted over the edit, and the run reported `adopt settings.json (skillOverrides
-> settings.base.json)` — which reads like success. Writing the change into the live file
first and then running `install.sh` carried it into the base correctly. Only a key the live
file does not have can be added from the base alone. The rule is in `claude/CLAUDE.md` →
*Where Rules Live*.

Related: [[cmux-rules-are-mac-only]], [[claude-code-context-budget]].

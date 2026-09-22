---
name: dotfiles-layout
description: Which file owns a durable fact and how the dotfiles machinery delivers it — the CLAUDE.md hierarchy, the generated settings.json and its overlays, the self-pull, the plugin version sync, and the public gist extracts. Load when adding or moving a rule, editing anything under ~/code/dotfiles, or debugging why a setting or plugin differs between machines. The one-line rule for choosing between a CLAUDE.md and a memory note stays in CLAUDE.md.
---

# Where Rules Live

- **`~/.claude/CLAUDE.md`** — how I work, everywhere. **The real file is
  `~/code/dotfiles/claude/CLAUDE.md`**; `~/.claude/CLAUDE.md` is an `@import` pointer written by
  `install.sh`. Edit the `dotfiles` path (the harness refuses to write through a symlink) and
  commit there; an uncommitted change is a change to the live config. `install.sh` runs on every
  SessionStart, so drift repairs itself.
- **`~/code/dotfiles/claude/CLAUDE.macos.md`** — imported by that pointer only on macOS. Anything
  that names cmux belongs here; it is dead weight anywhere else.
- **`~/code/dotfiles/agents/GLOBAL.md`** — the only file that reaches BOTH harnesses, imported
  above and read directly by Codex as `~/.codex/AGENTS.md`.
- **`<project>/CLAUDE.md`** — the map of that project: layout, workflows, release paths,
  project-wide conventions.
- **`<repo>/CLAUDE.md`** in a subdirectory — rules that only apply inside it. These load only when
  the work enters that subtree, so repo-specific detail belongs here, NOT in the project root file.
- **Memory** (`memory/` + `MEMORY.md`) — durable facts and decisions with a history. Not rules.

🔴 **`~/.claude/settings.json` is GENERATED, not a symlink.** It is `claude/settings.base.json`
(portable: permissions, `enabledPlugins`, `autoMode`, theme) merged with `claude/settings.macos.json`
or `claude/settings.linux.json` (hooks and `statusLine`, which differ per machine). Edit the **base**
or the **overlay**, never `~/.claude/settings.json`: the next `install.sh` regenerates it. The
overlays write paths as `{{HOME}}` and `{{REPO_ROOT}}`, substituted at install time.

- **A setting changed from inside a session is adopted, not lost.** `settings-sync.py` writes any
  drifted top-level key back into `settings.base.json` — that is how a plugin installed on one
  machine reaches the other. A key *deleted* from the live file is deliberately NOT adopted; remove
  it from the base by hand.
- 🔴 **Adoption runs BEFORE regeneration, so on a contested key the LIVE file wins.** Editing
  `settings.base.json` for a key `~/.claude/settings.json` already holds is silently reverted by the
  next `install.sh` — the sync adopts the live value over the edit and reports it as an `adopt` line
  that reads like success. Change such a key in the live file, then run `install.sh` to carry it into
  the base. Only a key the live file LACKS can be added from the base alone.
- **`enabledPlugins` is a declaration; `claude plugin install` is what makes it true.** That install
  state is per-machine and in no repo. `claude/plugins-sync.sh` closes the gap and also updates each
  plugin, since two machines that merely both have a plugin are not in sync. 🔴 It never passes `-y`
  — that flag accepts a *marketplace-declared command*, and an unattended `-y` would run whatever a
  catalog asked for, on every machine, with nobody watching.
- 🔴 **`install.sh --pull` is the only thing that fetches this repo on an unattended machine.** It
  spawns `claude/pull-dotfiles.sh` detached; that script refuses a dirty tree, pulls `--ff-only`, and
  re-runs `install.sh` itself if the pull moved anything. **The pull must never run inside
  `install.sh`** — bash reads a script incrementally, so a pull that rewrites the file mid-run can
  resume at the wrong byte offset. That is also why every line of `pull-dotfiles.sh` sits inside a
  `main()` called on its last line; do not hoist code out of it for tidiness.
- ⚠️ **A `git reset --hard` below the commit that added it DISARMS the pull**, after which nothing
  fetches and nothing says so. Recovery is one manual `git -C ~/code/dotfiles pull --ff-only`, then
  `./claude/install.sh`. The same command is what a machine needs once by hand to receive the change
  that makes it pull at all. See the memory note on the dotfiles self-update for the incidents.

**Which store owns a durable fact.** Ask one question: *does this tell a future session what to DO?*

- **Yes → it is a rule, and it goes in a CLAUDE.md.** Global if it holds everywhere, the repo's own
  file if it doesn't. Rules have to be in front of you before you act.
- **No, it records what happened → it is history, and it stays a memory note.** What shipped, what
  was decided and why, what something cost. A CLAUDE.md must never hold this: it goes stale in days
  and nothing there carries a date.
- **A note that caused a rule keeps the incident and links to the file.** The rule is the
  instruction; the note is the case file. "Why is this here" is what stops the next session deleting
  a rule it doesn't understand.
- **A lesson from a correction goes into memory** — never into a scratch file, a task note, or a
  comment in the code it concerns. Scratch files stop being read; memory is loaded every session.

When adding a rule, push it as far down as it applies. A rule in the wrong file is paid for on every
unrelated turn, and drifts because it sits far from what it describes. Don't duplicate across levels
— the lower file wins, so state it once.

🔴 **Four sections of this file are extracted into a PUBLIC gist and no edit reaches them** —
*Communication Style*, *Working With Me*, the claim-verification half of *Working Rules*, and
*Completion Summary*. `agents/PUBLISHING.md` has the mapping and the push commands; read it before
editing any of the four.

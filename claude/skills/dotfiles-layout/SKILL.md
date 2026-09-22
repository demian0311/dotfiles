---
name: dotfiles-layout
description: Which file owns a durable fact and how the dotfiles machinery delivers it — the CLAUDE.md hierarchy, the generated settings.json and its overlays, the self-pull, the plugin version sync, and the public gist extracts. Load when adding or moving a rule, editing anything under ~/code/dotfiles, or debugging why a setting or plugin differs between machines. The one-line rule for choosing between a CLAUDE.md and a memory note stays in CLAUDE.md.
---

# Where rules live, and how dotfiles delivers them

- 🔴 **Four sections of `claude/CLAUDE.md` are mirrored in a PUBLIC gist and no edit reaches
  them.** *Communication Style*, *Working With Me*, the claim-verification half of *Working
  Rules* and *Completion Summary* are extracted, de-personalised, into
  `agents/WORKING-RULES.md`. Changing one of those sections leaves the public copy saying the
  old thing, with nothing to say so. The gist, the second extract and the two push commands
  are in `agents/GLOBAL.md` → *Published extracts*.

- **`~/.claude/CLAUDE.md`** — how I work, everywhere. **The real file is
  `~/code/dotfiles/claude/CLAUDE.md`**; `~/.claude/CLAUDE.md` is a generated pointer holding
  one `@import` per platform file. Edit the `dotfiles` path (the harness refuses to write
  through a symlink) and commit there; an uncommitted change is a change to the live config.
  `claude/install.sh` restores it and runs on every SessionStart, so drift repairs itself.
  - 🔴 **`~/.claude/settings.json` is GENERATED, not a symlink — changed 2026-09-18 (#857).**
    It is `claude/settings.base.json` (portable: permissions, `enabledPlugins`, `autoMode`,
    theme) merged with `claude/settings.macos.json` or `claude/settings.linux.json` (hooks and
    `statusLine`, which are not the same on two machines). Edit the **base** or the
    **overlay**, never `~/.claude/settings.json`: the next `install.sh` regenerates it. The
    overlays write paths as `{{HOME}}` and `{{REPO_ROOT}}`, substituted at install time.
  - **A setting changed from inside a session is adopted, not lost.** Claude Code rewrites the
    live file when the theme, the model or an installed plugin changes; `settings-sync.py`
    reads it first and writes any drifted top-level key back into `settings.base.json`. That is
    how a plugin installed on one machine reaches the other. A key *deleted* from the live file
    is deliberately NOT adopted; remove it from the base by hand. ⚠️ It cannot tell a choice
    from an accident, and a machine that has not pulled yet is stale by definition — read
    `git diff claude/settings.base.json` after every `adopt settings.json`.
  - 🔴 **Nothing else FETCHES this repo on a machine nobody is sitting at, so `install.sh
    --pull` does — added 2026-09-18 (#859).** It spawns `claude/pull-dotfiles.sh` detached;
    that script refuses a dirty tree, pulls `--ff-only`, and re-runs `install.sh --quiet`
    itself if the pull moved anything. Throttled to once every 15 minutes, logged to
    `~/.claude/dotfiles-pull.log`. Wired into BOTH overlays since 2026-09-20. 🔴 **A Mac has to
    pull ONCE BY HAND to receive the change that makes it pull** —
    `cd ~/code/dotfiles && git pull --ff-only && ./claude/install.sh`.
    - 🔴 **The pull must never run inside `install.sh` itself.** Bash reads a script
      incrementally, so a pull that rewrites the file mid-run can resume at the wrong byte
      offset — which is also why every line of `pull-dotfiles.sh` sits inside a `main()` called
      on its last line. Do not hoist code out of it for tidiness.
    - The spawn is measured at **127 ms** against the SessionStart hook's 10-second timeout.
    - ⚠️ **A `git reset --hard` below that commit DISARMS it**, because the hook's command line
      comes out of the repo. Recovery is one manual `git -C ~/code/dotfiles pull --ff-only`.
  - **`enabledPlugins` is a declaration, and `claude plugin install` is what makes it true.**
    That install state is per-machine and in no repo. `claude/plugins-sync.sh` closes the gap;
    `install.sh` runs it detached and at most once every six hours. 🔴 It never passes `-y` —
    that flag accepts a *marketplace-declared command*.
    - 🔴 **It reconciles VERSIONS too, and converging on LATEST is the only convergence on
      offer — 2026-09-18 (#860).** There is no way to ask for a specific version;
      `claude plugin update <id> --json` returns `updateOutcome` with `oldVersion`/`newVersion`.
    - 🔴 **The catalog must be refreshed first** (`claude plugin marketplace update`), or
      `plugin update` reports `up_to_date` forever against the day-one clone.
    - 🔴 **install.sh spawns the background sync on the STALENESS CLOCK or a missing plugin —
      `||`, never `&&`.** Gating on `--check` deadlocked the version pass.
- **`<project>/CLAUDE.md`** — the map of that project: layout, workflows, release paths,
  project-wide conventions.
- **`<repo>/CLAUDE.md`** in a subdirectory — rules that only apply inside it. These load only
  when the work enters that subtree, so repo-specific detail belongs here, NOT in the project
  root file.
- **Memory** (`memory/` + `MEMORY.md`) — durable facts and decisions with a history.

## Why the split is by KIND, not by discipline

This exists because both stores were taking rules: of ~103 rules stated in both, **41 had
drifted apart**, in both directions — memory claiming `dgmo --json` was safe while the file
said it writes a PNG, the file trusting a build hook the note said never to trust. A periodic
de-duplication sweep repairs the copies and not the cause.

- **A note that caused a rule keeps the incident and links to the file.** The rule is the
  instruction; the note is the case file. "Why is this here" is what stops the next session
  deleting a rule it doesn't understand.
- When adding a rule, push it as far down as it applies. A rule in the wrong file is paid for
  on every unrelated turn, and drifts because it sits far from what it describes. Don't
  duplicate across levels — the lower file wins, so state it once.

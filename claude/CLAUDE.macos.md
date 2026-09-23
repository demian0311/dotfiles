# Mac-only rules

Imported by `~/.claude/CLAUDE.md` only on macOS, because everything here is
about cmux and cmux exists on no other machine. `install.sh` picks the file from
`uname`; anchor gets no second import at all.

## The cmux sidebar row

Labelling rules are in `agents/GLOBAL.md`, imported everywhere. What is left
here is what must never be done by hand.

🔴 **The row's COLOUR and every PILL belong to the hook or daemon that writes
them — never set one by hand.** A manual colour or pill is a state claim the next
writer overwrites, and while it stands it lies. Change the meaning by editing the
writer (`~/code/dotfiles/claude/`, `~/code/dotfiles/bin/`), never the row.

🔴 **A cmux automation can never be a LaunchAgent.** The socket is `cmuxOnly` and
refuses anything launchd starts, so such an agent runs on schedule and silently
achieves nothing. Extend `cmux-mem --daemon`, which `.zshrc` starts behind a
pidfile; never write a plist.

🔴 **Never schedule follow-up work from a Mac session. Leave it to bob's workflow
on `anchor`.** The Mac sleeps, closes and restarts, so a job scheduled there fails
silently. Claude Code's `CronCreate` and `ScheduleWakeup` die with the session.
Adding an ad-hoc openclaw automation is also out of band: it duplicates a pipeline
that already exists.
- **Put the "check back later" in the tracker instead.** Give the row the right
  board status, and comment what to check and what counts as done. Bob's nightly
  jobs already surface every Needs your check / Your turn row in the 03:55
  Telegram message (`docs/agents/nightly-pipeline.md` in `~/code/diagrammo`).
- **If bob's workflow should do something new, change bob:** edit the pipeline, or
  raise it with bob on anchor. Don't bolt a job on beside it.
- A new standalone or recurring automation needs a stated reason the pipeline
  can't cover, and the user's agreement.
- The cmux daemon above is the one exception, because it drives this Mac's own UI.

Decided 2026-09-23.

**Which writer owns which colour and which pill, why a `claude_code` pill needs
repairing after cmux overwrites it, where a non-Claude context bar has to live,
and why all four tools stay read-only about sessions: the `workspace-label`
skill.**

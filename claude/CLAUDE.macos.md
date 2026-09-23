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

🔴 **The Mac is not for automation — anything scheduled runs on `anchor`.** The
Mac sleeps, closes and restarts, so a job there fails silently. That covers
anything that has to happen later without the user: a follow-up check, a
reminder, a recurring sweep. It goes on anchor as an openclaw automation
(`ssh anchor 'openclaw automations add …'`, with `--at` for one-shots and
`--announce --channel telegram --to <chat>` so the result reaches the user),
or into bob's nightly pipeline. Never use a Claude Code `CronCreate` or
`ScheduleWakeup` for this: both live in one session's memory and die with it.
The cmux daemon above is the one exception, because it exists to drive this
Mac's own UI. Decided 2026-09-23.

**Which writer owns which colour and which pill, why a `claude_code` pill needs
repairing after cmux overwrites it, where a non-Claude context bar has to live,
and why all four tools stay read-only about sessions: the `workspace-label`
skill.**

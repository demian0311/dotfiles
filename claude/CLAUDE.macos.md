# Mac-only rules

Imported by `~/.claude/CLAUDE.md` only on macOS, because everything here is
about cmux and cmux exists on no other machine. `install.sh` picks the file from
`uname`; anchor gets no second import at all.

## The cmux sidebar row

Labelling rules are in `agents/GLOBAL.md`, imported everywhere so Codex gets the
same ones. What is left here is what must never be done by hand.

🔴 **The row's COLOUR and every PILL belong to the hook or daemon that writes
them — never set one by hand.** A manual colour or pill is a state claim the next
writer overwrites, and while it stands it lies. Change the meaning by editing the
writer (`~/code/dotfiles/claude/`, `~/code/dotfiles/bin/`), never the row.

🔴 **A cmux automation can never be a LaunchAgent.** The socket is `cmuxOnly` and
refuses anything launchd starts, so such an agent runs on schedule and silently
achieves nothing. Extend `cmux-mem --daemon`, which `.zshrc` starts behind a
pidfile; never write a plist.

**Which writer owns which colour and which pill, why a `claude_code` pill needs
repairing after cmux overwrites it, where a Codex context bar has to live, why
the `codex` placeholder comes from the daemon rather than a hook, and why all
four tools stay read-only about sessions: the `workspace-label` skill.**

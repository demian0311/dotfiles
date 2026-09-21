# Mac-only rules

Imported by `~/.claude/CLAUDE.md` only on macOS, because everything here is
about cmux and cmux exists on no other machine. `install.sh` picks the file from
`uname`; anchor gets no second import at all.

## Workspace Label (cmux sidebar)

The labelling rules themselves are in `agents/GLOBAL.md` (imported everywhere,
and Codex reads it too). What is here is the part specific to THIS harness's
hooks: which of them paints what, and what must never be painted by hand.

**`/clear` makes the label stale by definition.** A `SessionStart:clear` hook
(`~/.claude/cmux-relabel-on-clear.sh`) resets it to `clear` and reminds me to set
the real one. After a clear the job is to *name* the new thread, never to leave
the previous thread's label standing. The 🔴 "check it at every stop" rule lands
on the `report` and `pick` beats of the nine.

**The row COLOUR is not mine to set — hooks own it, and it means session state:**

| Colour | State | Set by |
|---|---|---|
| yellow `#c9a227` | a Claude session with nothing in it — fresh, or just `/clear`-ed | `~/.claude/cmux-session-start.py` (SessionStart: startup, clear) |
| green `#5b9357` | an agent is working | `cmux-throbber.py start` (UserPromptSubmit) |
| red `#c0504d` | stopped: waiting on you | `cmux-throbber.py stop` (Stop) |
| blue `#3b6ea5` | no Claude in this workspace, just a terminal | `cmux-session-end.py`, and `.zshrc`'s `_cmux_row_idle` precmd |

🔴 **Never run `workspace-action --action set-color` by hand** — a manual colour
is a state claim that the next hook overwrites, and while it stands it lies.
Change the meaning by editing the hook (all four live in `~/code/dotfiles/claude/`,
symlinked into `~/.claude/`), never the row.

🔴 **The same goes for every hook- or tool-owned PILL.** Setting or clearing one
by hand is the same mistake as a manual row colour.

| Pill | Owned by | Carries |
|---|---|---|
| `claude_code` | `cmux-throbber.py`, `cmux-session-start.py` — **and cmux itself** | the context bar |
| `mem` | `bin/cmux-mem` | each workspace's size, plus a headroom warning |
| `tidy` | `bin/cmux-tidy` | dev servers listening with nobody connected |
| `agents` | `bin/cmux-agents` | which agent is running, and a Codex session's context bar |

🔴 **cmux writes `claude_code` ITSELF, so a pill on that key never has the last
word** — it replaces the value on a lifecycle change or clears the pill outright,
wiping whatever the hooks just painted. `bin/cmux-agents` repairs it on a 20s
pass. Anything else built on that key needs the same treatment, or its own key.

🔴 **A Codex row's context bar lives on the `agents` key, NOT on cmux's own
`codex` key** — cmux rewrites its own agent keys on a lifecycle change, so the
only bar that survives is one on a key nothing else writes.

🔴 **A cmux automation can never be a LaunchAgent.** The socket is `cmuxOnly` and
refuses anything launchd starts, so such an agent runs on schedule and silently
achieves nothing. Access is inherited at spawn, not checked live, so a loop
started from a shell survives being orphaned to PID 1 — which is why
`cmux-mem --daemon` is launched from `.zshrc` behind a pidfile and drives
`cmux-tidy` itself. To schedule something against cmux, extend that daemon; never
write a plist.

🔴 **`bin/cmux-agents` places the `codex` placeholder label from the DAEMON, not
from a Codex hook** — a Codex hook only runs once a person has TRUSTED it in that
agent's own interface, and cmux launches Codex with
`--dangerously-bypass-hook-trust`, so ours would run inside cmux and silently not
run outside it.

All four tools stay read-only about SESSIONS — none ever closes one, because
choosing which session dies is the user's call.

---
name: workspace-label
description: The cmux sidebar row in full — the workspace label (why the handle is required and how it was verified, what makes a good label, placeholder labels that mean "name this thread", the incident behind checking it at every stop) and who paints the rest of the row (which hook owns which colour, which tool owns which pill, why a `claude_code` pill gets overwritten, why a cmux automation can never be a LaunchAgent). Load when renaming a workspace, when a rename fails, when deciding what to call the current thread, or before writing anything that sets a row colour, a status pill, or a scheduled cmux job.
---

Two sections, both moved out of the always-loaded instructions so the verification detail and
the incidents survive the trim. The instruction to set and re-check the label stays in
`agents/GLOBAL.md`; the prohibition on painting a row by hand stays in `claude/CLAUDE.macos.md`.
Everything below is the text as written when it lived there.

# Workspace label (cmux sidebar)

Several sessions run side by side and the sidebar label is how the user finds the
right one. **The session owns its own label** — cmux ships AI auto-naming and it is
deliberately off, so a label nobody sets stays whatever stale string was there.

```bash
cmux workspace rename "$CMUX_WORKSPACE_ID" --title "cloud limits"
```

🔴 **The handle is required.** `cmux workspace rename` does NOT default to the
calling session's workspace the way `env`/`reconnect`/`disconnect` do — bare, it
fails with `could not resolve workspace handle`. `$CMUX_WORKSPACE_ID` is in the
environment of every process cmux launched and is the authoritative answer to
"which workspace am I"; the sidebar's visible selection is not, and neither is the
pane header.

- Set it **as soon as the subject is clear** — usually right after the first
  substantive prompt, before the work starts. Not at the end.
- 🔴 **Re-set it when the thread changes, and CHECK IT AT EVERY STOP.** A workspace
  that started on release notes and is now debugging a Worker gets renamed; a label
  describing finished work is worse than a generic one. The check belongs to the
  beats that already interrupt the user — `report` and `pick` — because "when the
  thread changes" is a condition nobody notices while following the thread.
- **2–4 words, lowercase, what the work is about** — `cloud limits`,
  `obsidian live links`, `event-line dates`. Never a verb phrase (`fixing the parser`),
  never a tool or slash-command name, never `new`/`clear`/a bare repo name that
  doesn't distinguish it from the other sessions in the same repo.
- The label names the *work*, not the state — status is what the sidebar's own
  indicators are for.
- **A placeholder label is an instruction, not a name.** A fresh or just-cleared
  session gets renamed to `clear` automatically, precisely because at that moment
  the subject is known to be unknown. Seeing one means naming this thread is the
  FIRST job of the turn.
- Skip silently if `cmux` isn't on PATH or the call fails; it is never worth a retry or
  a mention. On anchor it never is.
- Rename only your own workspace. Another session's label belongs to that session.

# The rest of the sidebar row — who paints what

Also moved here from the global instructions, for the same reason: these rules only
fire when something is about to write to a cmux row, which is a rare and recognisable
moment. What stays resident in `claude/CLAUDE.macos.md` is the prohibition alone.

**`/clear` makes the label stale by definition.** A `SessionStart:clear` hook
(`~/.claude/cmux-relabel-on-clear.sh`) resets it to `clear` and reminds me to set the
real one. After a clear the job is to *name* the new thread, never to leave the
previous thread's label standing.

**The row COLOUR is not mine to set — hooks own it, and it means session state:**

| Colour | State | Set by |
|---|---|---|
| yellow `#c9a227` | a Claude session with nothing in it — fresh, or just `/clear`-ed | `~/.claude/cmux-session-start.py` (SessionStart: startup, clear) |
| green `#5b9357` | an agent is working | `cmux-throbber.py start` (UserPromptSubmit) |
| red `#c0504d` | stopped: waiting on you | `cmux-throbber.py stop` (Stop) |
| blue `#3b6ea5` | no Claude in this workspace, just a terminal | `cmux-session-end.py`, and `.zshrc`'s `_cmux_row_idle` precmd |

🔴 **Never run `workspace-action --action set-color` by hand** — a manual colour is a
state claim that the next hook overwrites, and while it stands it lies. Change the
meaning by editing the hook (all four live in `~/code/dotfiles/claude/`, symlinked
into `~/.claude/`), never the row.

🔴 **The same goes for every hook- or tool-owned PILL.** Setting or clearing one by
hand is the same mistake as a manual row colour.

| Pill | Owned by | Carries |
|---|---|---|
| `claude_code` | `cmux-throbber.py`, `cmux-session-start.py` — **and cmux itself** | the context bar |
| `mem` | `bin/cmux-mem` | each workspace's size, plus a headroom warning |
| `tidy` | `bin/cmux-tidy` | dev servers listening with nobody connected |
| `agents` | `bin/cmux-agents` | which agent is running, and a non-Claude session's context bar |

🔴 **cmux writes `claude_code` ITSELF, so a pill on that key never has the last
word** — it replaces the value on a lifecycle change or clears the pill outright,
wiping whatever the hooks just painted. `bin/cmux-agents` repairs it on a 20s pass.
Anything else built on that key needs the same treatment, or its own key.

🔴 **A non-Claude row's context bar lives on the `agents` key, NOT on cmux's own
per-agent key** — cmux rewrites its own agent keys on a lifecycle change, so the only
bar that survives is one on a key nothing else writes.

🔴 **A cmux automation can never be a LaunchAgent.** The socket is `cmuxOnly` and
refuses anything launchd starts, so such an agent runs on schedule and silently
achieves nothing. Access is inherited at spawn, not checked live, so a loop started
from a shell survives being orphaned to PID 1 — which is why `cmux-mem --daemon` is
launched from `.zshrc` behind a pidfile and drives `cmux-tidy` itself. To schedule
something against cmux, extend that daemon; never write a plist.

All four tools stay read-only about SESSIONS — none ever closes one, because choosing
which session dies is the user's call.

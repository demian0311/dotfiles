---
name: workspace-label
description: The cmux sidebar workspace label in full — why the handle is required and how it was verified, what makes a good label, placeholder labels that mean "name this thread", the incident behind checking it at every stop, and what Codex's sandbox permits. Load when renaming a workspace, when a rename fails, or when deciding what to call the current thread.
---

The instruction to set and re-check the label is in the global instructions. This is the whole
section as written, kept here so the verification detail and the incidents survive the trim —
nothing below was edited.

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
  never a tool or slash-command name, never `new`/`clear`/`codex`/a bare repo name that
  doesn't distinguish it from the other sessions in the same repo.
- The label names the *work*, not the state — status is what the sidebar's own
  indicators are for.
- **A placeholder label is an instruction, not a name.** A fresh or just-cleared
  session gets renamed to one automatically — `clear` in Claude Code, `codex` in
  Codex — precisely because at that moment the subject is known to be unknown.
  Seeing one means naming this thread is the FIRST job of the turn.
- Skip silently if `cmux` isn't on PATH or the call fails; it is never worth a retry or
  a mention. On anchor it never is.
- **Codex's sandbox permits this, and a read-only session does not.** Reaching cmux
  means reaching a unix socket, which rides on the same switch as network access:
  under `workspace-write` with `network_access = true` the rename works; under
  `read-only`, or with network off, it fails with `Operation not permitted`.
- Rename only your own workspace. Another session's label belongs to that session.

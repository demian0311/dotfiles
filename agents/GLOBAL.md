# Global rules — every coding agent, every session

🔴 **Shared by every coding agent, not just one.** Claude Code imports this file from
`claude/CLAUDE.md`; Codex reads it directly as `~/.codex/AGENTS.md`, where it is the *only*
global instruction file it gets. So never name a tool that exists in one harness and not the
other without saying which — a rule the reader cannot act on is worse than no rule.

**This file is the only place a rule can reach BOTH harnesses**, which is why it holds more
than its original subject. It was `presenting-options.md` until 2026-08-25 and held only the
question-asking rules; the workspace label moved in the same day, from `claude/CLAUDE.md`,
because Codex never reads that file and the project one is truncated at 32 KB — far short of
where a rule buried in a 70 KB `CLAUDE.md` would sit. Anything else that both harnesses must
obey belongs here too, under its own heading rather than folded into a neighbour's.

# Presenting options — how Demian wants to be asked and told

These rules WIN even when a workflow, skill, or BMAD step presents its questions as prose or
inline "[1]/[2]" text. Reformat such questions to comply before asking.

## Asking questions

- **A lettered list is the default form** — options and next steps in conversation are letters,
  in recommendation order, so the user replies with one character:
  - 🟢 A) Recommended option
  - 🟡 B) Neutral/viable option
  - 🔴 C) Not recommended option
- **The harness's structured picker is for what a lettered list cannot do**: several decisions at
  once, multi-select, or options that need side-by-side previews to compare. It is
  `AskUserQuestion` in Claude Code and `request_user_input` in Codex. Recommended option first,
  "(Recommended)" appended to its label. Do NOT reach for it when presenting a decision at the
  end of a piece of work — that is a lettered list.
- NEVER ask prose "A or B?" / "X, or would you rather Y?" questions. Every multi-option choice
  becomes a lettered list or the structured picker — the user answers with one letter or a click,
  never a sentence.
- **Numbers in documents, letters in conversation**, both always in recommendation order, best
  first. A mockup, doc or issue numbers its options **1, 2, 3**; conversation letters them
  **A, B, C** with the 🟢/🟡/🔴 scheme. Two alphabets so a reference is never ambiguous about
  which one it points at.
- Never label options, variants or scenarios with greek letters (α/β/γ/Δ/Σ) — plain numbers or
  letters, in tables, headers and prose alike.
- One decision per question. Don't bundle multiple asks into one paragraph.
- Minimize required typing. "Other" is always available for freeform, so don't pre-solicit prose.
- Any confirmation prompt for a command that will recur offers *"Yes, and add to permissions"* as
  a listed option upfront. If chosen, persist it: in Claude Code use the `update-config` skill to
  add a wildcard pattern (`Bash(git diff*)`) under `permissions.allow`; in Codex append a
  `prefix_rule(pattern=[...], decision="allow")` line to `~/.codex/rules/default.rules`.

## Next steps — always ranked, never prose

Every "what's next" is a lettered list in priority order, same scheme as above. Never a
paragraph, never an unordered pile, never "you could also...".

- 🟢 **A)** — the recommended next step. Always first. Exactly one green.
- 🟡 **B)**, **C)**, … — viable, in descending priority.
- 🔴 **Z)** — options to recommend against, last. Include only when the user is likely to consider
  one; say why not in the same line.

Rules:
- One line each: what to do + why, ≤ ~15 words of rationale. No sub-bullets.
- Letters run in sequence with no gaps; priority order IS letter order.
- One step, one letter. Don't bundle "A) do X and Y and Z".
- The user replies with a single letter. Anything requiring a sentence back is a malformed list.
- Applies to next steps, recommendations, remaining-work lists, and triage output — not just
  end-of-task summaries.

**Stay in the current thread of work.** Next steps continue what we are actually doing. Do NOT
surface unrelated initiatives, other sessions' in-flight branches, or backlog items that merely
happen to be open — the user is mid-thought on one thing, and a menu of everything else derails
it. A step from outside the thread appears only if the user asks, or if the current work genuinely
blocks on it (say which). When the thread is finished and there is nothing left in it, say so
plainly instead of manufacturing options.

🔴 **Every step says whether it CONTINUES the current work or leaves it** — the reader cannot tell
from the text alone, and being unsure which they are answering is the failure this fixes. A step
that carries on with what we are already doing opens with `Continue <the thing> — `; a step that
departs opens by naming where it goes. Both forms still gloss any identifier, so it is
`Continue the agent-only dev-server deadline (#363) — time a cold start`, never `Continue #363`.

- Say it even when **every** option continues the same work. That is exactly the case that reads
  as a menu of departures, because a four-option list looks like four directions whatever the
  options say.
- The prefix is not a substitute for the thread rule above. Departures still only appear when
  asked for or genuinely blocking; this makes the ones that survive legible.
- Observed 2026-08-19: four next-steps options, all four of them moves on the same issue, and the
  user asked whether to pick a letter or to say "let's do 363" — the list had given no way to tell
  those were the same answer.

🔴 **An identifier never travels alone, here or anywhere else.** Every issue, PR, story, epic,
ticket or migration number carries a parenthetical saying what it is, and **the thing comes
first**: `the npm token expiry (#218)`, never `#218 — the npm token expiry`. The tell is a bullet
or sentence whose first token is an identifier; if the eye lands on the number before it lands on
any words, rewrite it. A bare number inside a link is the same violation wearing a link, so the
link text is the description too.

# Workspace label (cmux sidebar)

Several sessions run side by side and the sidebar label is how the user finds the
right one. **The session owns its own label** — cmux ships AI auto-naming and it is
deliberately off (decided 2026-08-05, and its machinery is Claude-only in the binary
regardless), so a label nobody sets stays whatever stale string was there.

```bash
cmux workspace rename "$CMUX_WORKSPACE_ID" --title "cloud limits"
```

**The handle is required.** `cmux workspace rename` does NOT default to the calling
session's workspace the way `env`/`reconnect`/`disconnect` do — bare, it fails with
`could not resolve workspace handle`. `$CMUX_WORKSPACE_ID` is in the environment of
every process cmux launched, agent included, and is the authoritative answer to "which
workspace am I"; the sidebar's visible selection is not, and neither is the pane
header. Verified 2026-08-05.

- Set it **as soon as the subject is clear** — usually right after the first
  substantive prompt, before the work starts. Not at the end.
- **Re-set it when the thread changes, and CHECK IT AT EVERY STOP.** A workspace that
  started on release notes and is now debugging a Worker gets renamed; a label
  describing finished work is worse than a generic one. 🔴 The check belongs to the
  beats that already interrupt the user — reporting, and asking them to pick — because
  "when the thread changes" is a condition nobody notices while following the thread.
  Observed 2026-08-16: a session set `cross space search` at its first prompt and kept
  it through three further subjects, finishing on folder copying, while the user was
  reading that sidebar to work out which of eight sessions was which. Free to fix, and
  half a session of confusion not to.
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
  a mention.
- ⚠️ **In Codex the rename is currently BLOCKED by the sandbox** — measured 2026-08-25:
  a command run under `workspace-write` cannot connect to cmux's unix socket
  (`Operation not permitted, errno 1`), while the same command under
  `danger-full-access`, or with `--allow-unix-socket /Users/demian/.local/state/cmux`,
  succeeds. The persistent config that grants it was not established; until it is, a
  Codex session's rename fails silently and the placeholder below is what actually
  keeps that row honest. Try the rename anyway — it costs one call and works the day
  the setting lands.
- Rename only your own workspace. Another session's label belongs to that session.

# Global rules — every session

Imported by `claude/CLAUDE.md`. Holds what the public extract `agents/OPTION-GLYPHS.md` is cut
from; that extract is a COPY, and `agents/PUBLISHING.md` has the mapping and the push. Every
other global rule goes in `claude/CLAUDE.md`; anything Mac-only in `claude/CLAUDE.macos.md`.

# Presenting options — how Demian wants to be asked and told

These rules WIN even when a workflow, skill, or BMAD step presents its questions as prose or
inline "[1]/[2]" text. Reformat such questions to comply before asking.

## Asking questions

- **A lettered list is the default form** — options and next steps in conversation are letters,
  in recommendation order, so the user replies with one character:
  - 🟢 A) Recommended, continuing the task at hand
  - 🟡 B) Viable, also continuing the task at hand
  - 🔵 C) Recommended, but a DEPARTURE — toward a different goal than the one we are on
  - 🟣 D) Viable, also a departure
  - 🔴 E) Not recommended, whichever kind it is
- **The harness's structured picker is for what a lettered list cannot do**: several decisions at
  once, multi-select, or options that need side-by-side previews to compare. It is the
  `AskUserQuestion` tool, recommended option first, with "(Recommended)" appended to its label.
  Do NOT reach for it when presenting a decision at the end of a piece of work — that is a
  lettered list.
- NEVER ask prose "A or B?" / "X, or would you rather Y?" questions. Every multi-option choice
  becomes a lettered list or the structured picker — the user answers with one letter or a click,
  never a sentence.
- **Numbers in documents, letters in conversation**, both always in recommendation order, best
  first. A mockup, doc or issue numbers its options **1, 2, 3**; conversation letters them
  **A, B, C** with the 🟢/🟡/🔵/🟣/🔴 scheme. Never greek letters for options, variants or scenarios.
- One decision per question. Don't bundle multiple asks into one paragraph.
- Minimize required typing. "Other" is always available for freeform, so don't pre-solicit prose.
- A confirmation prompt for a command that will recur offers *"Yes, and add to permissions"* as a
  listed option upfront, and persisting it is in the `presenting-options` skill.

## Next steps — always ranked, never prose

Every "what's next" is a lettered list in priority order, same scheme as above. Never a
paragraph, never an unordered pile, never "you could also...".

🔴 **Produce them by default — never ask permission to produce them.** A message that stops
and carries no list is malformed, whatever beat it belongs to. "Say the word and I'll put
options against it", "shall I work that up?", "let me know if you want me to go further" are
the exact shape this forbids: each spends a round trip to learn something the list itself
would have said. Write it and let it be rejected. This outranks any workflow, skill or beat
that says to hold options back for a later message.

The one thing that is not a list is a genuine fork the options cannot express. That is a
**question**, asked outright in the lettered form or the structured picker — never a bare
offer to continue.

Two tiers, twice — once for steps that CONTINUE the work we are on, once for steps that DEPART
toward a different goal. Red spans both.

|  | Continues the work | Departs from it |
|---|---|---|
| **Recommended** | 🟢 | 🔵 |
| **Viable** | 🟡 | 🟣 |
| **Advise against** | 🔴 | 🔴 |

- 🟢 **A)** — the recommended next step, continuing the work we are on. **At most one green**, and
  first whenever it exists.
- 🟡 — also continuations, viable, in descending priority.
- 🔵 — the recommended **departure**: something the agent proposes, a neighbouring problem it
  noticed, anything outside the current thread. **At most one blue.**
- 🟣 — also departures, viable, in descending priority.
- 🔴 — advise against, last, whichever direction it is. Say why not in the same line, and include
  one only when the user is likely to consider it. **Red wins**: a departure the agent advises
  against is red, not purple.

**Order is 🟢 · 🟡 · 🔵 · 🟣 · 🔴**, and priority order is still letter order. Two exceptions, both
the case where no continuation can be recommended: **the thread is finished** (no green — the
blue leads, with one line above saying the thread is done rather than dressing a departure up as
progress), and **the work is BLOCKED on a departure** (that blue leads, ahead of every
continuation, and says what it unblocks).

Rules:
- One line each: what to do + why, ≤ ~15 words of rationale. No sub-bullets.
- Letters run in sequence with no gaps; priority order IS letter order.
- One step, one letter. Don't bundle "A) do X and Y and Z".
- The user replies with a single letter. Anything requiring a sentence back is a malformed list.
- Applies to next steps, recommendations, remaining-work lists, and triage output — not just
  end-of-task summaries.

**Stay in the current thread of work.** Next steps continue what we are actually doing. Do NOT
surface unrelated initiatives, other sessions' in-flight branches, or backlog items that merely
happen to be open. A step from outside the thread appears only if the user asks, or if the
current work genuinely blocks on it (say which). When the thread is finished and there is nothing
left in it, say so plainly instead of manufacturing options.

🔴 **Every step says whether it CONTINUES the current work or leaves it.** A continuation is
green or yellow and opens with `Continue <the thing> — `; a departure is blue or purple and
opens by naming where it goes; a red takes whichever opening fits. **The colour carries the
direction, the prose carries the identity**, and the identifier rule in `claude/CLAUDE.md` →
*Communication Style* applies: `Continue the agent-only dev-server deadline (#363) — time a
cold start`, never `Continue #363`. A step whose colour and opening disagree is malformed. Say it
even when **every** option continues the same work — that is exactly the case that reads as a
menu of departures. **What counts as a departure and the two blue-leading lists: the
`presenting-options` skill.**

# Workspace label (cmux sidebar)

Several sessions run side by side and the sidebar label is how the user finds the right one.
Nothing sets it but the session itself — cmux's AI auto-naming is deliberately off.

```bash
cmux workspace rename "$CMUX_WORKSPACE_ID" --title "cloud limits"
```

- **The handle is required** — bare, the command fails with `could not resolve workspace
  handle`. `$CMUX_WORKSPACE_ID` is the authoritative answer to "which workspace am I"; the
  sidebar's visible selection is not, and neither is the pane header.
- **2–4 words, lowercase, what the work is about.** Never a verb phrase, never a tool or
  slash-command name, never `new`/`clear`/a bare repo name. The label names the
  *work*, not the state.
- **Set it as soon as the subject is clear** — right after the first substantive prompt.
- 🔴 **Re-set it when the thread changes, and CHECK IT AT EVERY STOP** — at reporting, and
  when asking the user to pick. "When the thread changes" is a condition nobody notices while
  following the thread, so it has to ride on the beats that already interrupt.
- **A placeholder label is an instruction, not a name.** A fresh or just-cleared session is
  renamed to `clear` automatically. Seeing one means naming this thread is the FIRST job of
  the turn.
- Skip silently if `cmux` isn't on PATH or the call fails. Rename only your own workspace.

**Why the handle behaves that way, and the incident behind the check-at-every-stop rule:
the `workspace-label` skill.**

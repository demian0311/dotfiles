# Global rules — every session

Imported by `claude/CLAUDE.md`. What belongs here is what the public extract
`agents/OPTION-GLYPHS.md` is cut from: how options, next steps and the workspace label are
presented. Every other global rule goes in `claude/CLAUDE.md`; anything Mac-only belongs in
`claude/CLAUDE.macos.md`, which is imported only on macOS.

## Published extracts

Two de-personalised files in `agents/` are mirrored to a public gist. They are COPIES, so no
edit reaches them automatically, and four sections of `claude/CLAUDE.md` are among their
sources. `agents/PUBLISHING.md` has the mapping, the push commands and the de-personalising
rules — read it before editing either extract or any section that feeds one.

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
  **A, B, C** with the 🟢/🟡/🔵/🟣/🔴 scheme. Two alphabets so a reference is never ambiguous about
  which one it points at.
- Never greek letters (α/β/γ/Δ/Σ) for options, variants or scenarios — plain numbers or letters.
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
would have said, and the list is cheap to write and free to ignore. Write it and let it be
rejected. This outranks any workflow, skill or beat that says to hold options back for a
later message. Observed 2026-09-21 — a diagnosis that ended by offering to spend the next
beat instead of spending it.

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

**Order is 🟢 · 🟡 · 🔵 · 🟣 · 🔴**, and priority order is still letter order. Green and yellow say
*stay on this task*, blue and purple say *leave it*, red says *do not do this* whichever direction
it points. Two exceptions, both the case where no continuation can be recommended: **the thread is
finished** (no green — the blue leads, with one line above saying the thread is done rather than
dressing a departure up as progress), and **the work is BLOCKED on a departure** (that blue leads,
ahead of every continuation, and says what it unblocks).

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
that carries on with what we are already doing is green or yellow and opens with
`Continue <the thing> — `; a step that departs is blue or purple and opens by naming where it
goes. A red takes whichever opening fits the direction it points. **The colour carries the
direction, the prose carries the identity** — so the colour is what says continue-or-depart at a
glance, and the words still have to name the thing and gloss any identifier: it is
`Continue the agent-only dev-server deadline (#363) — time a cold start`, never `Continue #363`.
A step whose colour and opening disagree is malformed.

Say it even when **every** option continues the same work — that is exactly the case that reads as
a menu of departures. **What counts as a departure, the two blue-leading lists, and why this rule
exists: the `presenting-options` skill.**

🔴 **An identifier never travels alone, here or anywhere else.** Every issue, PR, story, epic,
ticket or migration number carries a parenthetical saying what it is, and **the thing comes
first**: `the npm token expiry (#218)`, never `#218 — the npm token expiry`. The tell is a bullet
or sentence whose first token is an identifier; if the eye lands on the number before it lands on
any words, rewrite it. A bare number inside a link is the same violation wearing a link, so the
link text is the description too.

# Workspace label (cmux sidebar)

Several sessions run side by side and the sidebar label is how the user finds the right one,
and nothing sets it but the session itself — cmux's AI auto-naming is deliberately off, so a
label nobody sets stays whatever stale string was there.

```bash
cmux workspace rename "$CMUX_WORKSPACE_ID" --title "cloud limits"
```

- **The handle is required** — bare, the command fails with `could not resolve workspace
  handle`. `$CMUX_WORKSPACE_ID` is the authoritative answer to "which workspace am I"; the
  sidebar's visible selection is not, and neither is the pane header.
- **2–4 words, lowercase, what the work is about.** Never a verb phrase, never a tool or
  slash-command name, never `new`/`clear`/a bare repo name. The label names the
  *work*, not the state.
- **Set it as soon as the subject is clear** — right after the first substantive prompt, not
  at the end.
- 🔴 **Re-set it when the thread changes, and CHECK IT AT EVERY STOP** — at reporting, and
  when asking the user to pick. "When the thread changes" is a condition nobody notices while
  following the thread, so it has to ride on the beats that already interrupt.
- **A placeholder label is an instruction, not a name.** A fresh or just-cleared session is
  renamed to `clear` automatically, because at that
  moment the subject is known to be unknown. Seeing one means naming this thread is the FIRST
  job of the turn.
- Skip silently if `cmux` isn't on PATH or the call fails. Rename only your own workspace.

**Why the handle behaves that way, and the incident behind the check-at-every-stop rule:
the `workspace-label` skill.**

---
name: presenting-options
description: The full reasoning behind the lettered option format — what counts as a departure, the two lists that open with blue, why the continue-or-depart prefix exists, the two-alphabet rule, and the incidents that produced each. Load when unsure whether a step is a continuation or a departure, when a list has no green, or when writing guidance about how options are presented. The rules that fire on every message are in the global instructions; this is the copy of record.
---

The global instruction file carries the rules that fire on every message. This is the whole
section as written, kept here so the reasoning and the incidents behind each rule survive the
trim — nothing below was edited.

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
- Never label options, variants or scenarios with greek letters (α/β/γ/Δ/Σ) — plain numbers or
  letters, in tables, headers and prose alike.
- One decision per question. Don't bundle multiple asks into one paragraph.
- Minimize required typing. "Other" is always available for freeform, so don't pre-solicit prose.
- Any confirmation prompt for a command that will recur offers *"Yes, and add to permissions"* as
  a listed option upfront. If chosen, persist it with the `update-config` skill: a wildcard
  pattern (`Bash(git diff*)`) under `permissions.allow`.

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

**Order is 🟢 · 🟡 · 🔵 · 🟣 · 🔴**, and priority order is still letter order. Two exceptions, both
being the case where no continuation can be recommended:

- **The thread is finished.** There is no green; the list opens with the blue, and one line above
  it says the thread is done rather than dressing a departure up as progress.
- **The work is BLOCKED on a departure.** That blue leads, ahead of every continuation, and says
  what it unblocks — it is the only thing that can actually be done next.

The colours are not one axis. Green and yellow say *stay on this task*, blue and purple say *leave
it*, red says *do not do this* whichever direction it points.

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

# Presenting options — how Demian wants to be asked and told

🔴 **Shared by every coding agent, not just one.** Claude Code imports this file from
`claude/CLAUDE.md`; Codex reads it directly as `~/.codex/AGENTS.md`, where it is the *only*
global instruction file. So never name a tool that exists in one harness and not the other
without saying which — a rule the reader cannot act on is worse than no rule.

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

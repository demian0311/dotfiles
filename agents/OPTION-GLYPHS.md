# Coloured glyphs for agent output

A small convention for two things coding agents do badly: offering you a list of next
steps, and showing you how far along a job is.

Two problems it fixes.

**You can't tell which suggestions continue your work.** An agent finishes a task and
offers four things to do next. Two carry on with what you were doing; two are the agent
wandering off toward something it noticed. They look identical, so you read all four
carefully to work out which is which — every single time.

**Progress is invisible.** A checklist rendered with `- [ ]` or ballot boxes is legible
but recessive. Posted mid-message it reads as ordinary bullets, so you can't tell at a
glance whether a job is barely started or nearly done.

The fix is two glyph systems that never overlap: **circles mean priority, squares mean
progress.** Shape separates them, so colour is free to mean something different in each.

## What it looks like

Next steps, after finishing a piece of work:

> - 🟢 **A)** Continue the export dialog — add the copy-link button we scoped.
> - 🟡 **B)** Continue the export dialog — write the test for the expiry path.
> - 🔵 **C)** The stale share links nobody cleans up — worth a separate pass.
> - 🔴 **Z)** Rewrite the dialog in the new framework — big, and nothing forces it yet.

You reply with one character. The colour tells you, before you read a word, that A and B
keep you where you are and C leaves.

A job in flight:

```
Migrate the billing tables

  🟩 Snapshot production
  🟩 Write the backfill script
  🟨 Run it against staging
  ⬜ Notify the finance team — they asked to be told after cutover, not before
  🟥 Run against production
  🟥 Drop the old columns
```

Mostly red means barely started. Mostly green means nearly done. One yellow, always.

---

Everything below this line is the rule itself. Paste it into your `CLAUDE.md`,
`AGENTS.md`, or whatever your agent reads as standing instructions.

## Presenting options and next steps

Every "what's next", every set of choices, is a **lettered list in priority order** — never
a paragraph, never an unordered pile, never "you could also…". The reader replies with a
single character. Anything that needs a sentence back is a malformed list.

Two tiers, twice — once for steps that CONTINUE the work we are on, once for steps that
DEPART toward a different goal. Red spans both.

|  | Continues the work | Departs from it |
|---|---|---|
| **Recommended** | 🟢 | 🔵 |
| **Viable** | 🟡 | 🟣 |
| **Advise against** | 🔴 | 🔴 |

- 🟢 **A)** — the recommended next step, continuing the work we are on. **At most one
  green**, and first whenever it exists.
- 🟡 — also continuations, viable, in descending priority.
- 🔵 — the recommended **departure**: something the agent proposes, a neighbouring problem
  it noticed, anything outside the current thread. **At most one blue.**
- 🟣 — also departures, viable, in descending priority.
- 🔴 — advise against, last, whichever direction it points. Say why not on the same line,
  and include one only when the reader is likely to consider it. **Red wins**: a departure
  the agent advises against is red, not purple.

**Order is 🟢 · 🟡 · 🔵 · 🟣 · 🔴**, and priority order is letter order. Two exceptions, both
being the case where no continuation can be recommended:

- **The thread is finished.** There is no green; the list opens with the blue, and one line
  above it says the thread is done rather than dressing a departure up as progress.
- **The work is BLOCKED on a departure.** That blue leads, ahead of every continuation, and
  says what it unblocks — it is the only thing that can actually be done next.

The colours are not one axis. Green and yellow say *stay on this task*, blue and purple say
*leave it*, red says *do not do this* whichever direction it points.

More rules:

- One line each: what to do, plus why, in roughly fifteen words. No sub-bullets.
- Letters run in sequence with no gaps.
- One step, one letter. Don't bundle "A) do X and Y and Z".
- Applies to next steps, recommendations, remaining-work lists and triage output — not just
  end-of-task summaries.

### Stay in the current thread

Next steps continue what we are actually doing. Do NOT surface unrelated initiatives or
backlog items that merely happen to be open — the reader is mid-thought on one thing, and a
menu of everything else derails it. A step from outside the thread appears only if they ask
for it, or if the current work genuinely blocks on it (say which). When the thread is
finished and nothing is left in it, say so plainly instead of manufacturing options.

Zero blues and purples is therefore the normal case. The colours exist to make the
departures that *do* survive that filter legible, not to invite more of them.

### Colour carries the direction, prose carries the identity

Every step says whether it continues the work or leaves it, in words as well as colour —
the colour is what's readable at a glance, and it's the half that survives being skimmed.

- A step that carries on is green or yellow and opens with `Continue <the thing> — `.
- A step that departs is blue or purple and opens by naming where it goes.
- A red takes whichever opening fits the direction it points.
- A step whose colour and opening disagree is malformed.

The prose does the thing colour can't: it names the subject. **An identifier never travels
alone** — every issue, PR, ticket or migration number carries a short phrase saying what it
is, and the thing comes first. So it is `Continue the token expiry bug (#218) — reproduce
it against staging`, never `Continue #218`, and never `#218 — the token expiry bug`. If the
eye lands on a number before it lands on any words, rewrite it. A bare number inside a link
is the same mistake wearing a link, so the link text is the description too.

### What actually counts as a departure

One test, and it is about the reader rather than the code: **would this step get the
thing they asked for finished?** If yes it continues, whatever file it touches. If no it
departs, however closely related it looks.

The boundary is drawn by the request, not by what the code has in common. Fixing one
flaky test and fixing the four siblings that share its bad pattern are the same *kind* of
work and two different *pieces* of work — so if the ask named one test, the siblings are
a departure. A good one, worth offering. But the reader gets to decline it without
feeling they have refused the repair they actually asked for.

**Departures — these leave the thread, however tempting:**

- A defect noticed in neighbouring code while working on this one.
- The same defect elsewhere, when the request named one place.
- A refactor the fix makes tempting. "While we're in here" is the sound of a departure.
- Missing tooling the work exposed — no fixture, no local runner, no way to reproduce.
- A naming or design problem you hit on the way through.
- Documenting or announcing what was just built, when nobody asked for docs.
- Something the reader raised earlier in the session and has since moved past.

**Continuations — these look like departures and aren't:**

- Writing the test for the code just written.
- Updating the document that describes the behaviour just changed.
- Committing, merging, deleting the branch, deploying. Landing is part of the task, not a
  follow-up to offer back.
- Re-running the thing under the conditions that produced the original failure.
- Clearing up debris this work itself created.

All five colours, on one flaky test in a checkout flow:

> - 🟢 **A)** Continue the flaky checkout test — swap the two-second sleep for a wait on the button becoming enabled.
> - 🟡 **B)** Continue the flaky checkout test — run it two hundred times under load to confirm the flake is gone.
> - 🔵 **C)** The same sleep pattern in four sibling tests — they will flake next.
> - 🟣 **D)** The two-core CI runner — it is what makes these tests marginal in the first place.
> - 🔴 **E)** Move the suite onto a different test runner — weeks of work, and the runner isn't at fault.

That is a fuller list than most. Two continuations and nothing else is the common shape.

### The two lists that open with blue

**The thread is finished.** Say so on the line above, rather than dressing a departure up
as progress:

> That is the whole of the import bug; nothing is left in it.
>
> - 🔵 **A)** The duplicate-detection pass the importer skips — noticed while reading it.
> - 🟣 **B)** The importer's errors quote internal table names — small, separate cleanup.

**The work is blocked on a departure.** That blue leads, ahead of every continuation, and
says what it unblocks — it is the only thing that can actually be done next:

> - 🔵 **A)** Seed data for the staging database — nothing in the refund flow can be tested until it exists.
> - 🟡 **B)** Continue the refund flow — the last two branches can be written blind, then tested once A lands.

## Progress checklists

Any multi-step process — three or more steps, or anything spanning more than one turn —
shows a checklist, so what's done and what's left is visible without asking.

```
Migrate the billing tables

  🟩 Snapshot production
  🟩 Write the backfill script
  🟨 Run it against staging
  ⬜ Notify the finance team — they asked to be told after cutover, not before
  🟥 Run against production
  🟥 Drop the old columns
```

- 🟩 done · 🟨 doing it right now · 🟥 still to do · ⬜ dropped or blocked
- **The colours track completeness, not severity.** A checklist starts all 🟥 and ends all
  🟩 — red means outstanding, never *wrong*, so a freshly posted list full of red is the
  normal opening state and reads as work ahead rather than failure.
- ⬜ is the one state outside that progression, which is why it's the recessive glyph: a
  dropped or blocked step isn't work in flight and shouldn't compete for the eye with the
  🟥s that still need doing.
- Exactly one 🟨 at a time. Nothing is "in progress" while something else is.
- One line per step, phrased as the action. No sub-bullets, no status prose.
- Post it when the work starts and re-post it as states change. A stale checklist is worse
  than none.
- A dropped or blocked step becomes ⬜ and **stays on the list**, with the reason on the
  same line after an em dash. Silently vanishing steps read as completed. Don't strike the
  text as well — the square already says it, and struck text is harder to read for the one
  line that most needs reading.
- ⬜ is the only state that carries a reason, and it always carries one. "⬜ Drop the old
  columns" alone tells the reader nothing about whether they now have to do it themselves.
- **Every line is a step.** ⬜ is not a slot for a note, a heading or an aside — a checklist
  carrying information that isn't a piece of work stops being scannable as progress.

## Why squares and circles, and one thing to watch

The two systems share a colour vocabulary, so **shape has to be what separates them**. A
square is always progress, a circle is always priority, and the two never appear in the
same list. Reusing circles for both would make a half-finished task and a low-priority
suggestion look identical.

Colour means emoji, unavoidably: rendered markdown in a terminal has no way to tint a text
glyph, so every coloured marker is a wide emoji. That's fine, with one caveat worth knowing
before you substitute anything.

**All markers in one column must come from the same Unicode width class**, or the column
stops lining up. The five circles and the four squares here are all East Asian Width `W`,
so every row indents identically. Mixing is the hazard, not width itself — drop a single
narrow text glyph (`☑`, `▸`, `✔`) into a column of emoji and that row shifts by a cell.
Two tempting monochrome alternatives fail this quietly: `● ◐ ○ ✗` and `■ ◧ □ ▨` each mix
`Ambiguous` with `Neutral`, which renders single-width in a Western locale and double-width
in a CJK-configured one. Check any substitute with:

```python
import unicodedata
[unicodedata.east_asian_width(c) for c in "🟩🟨🟥⬜"]   # all 'W' — safe
```

---

*Extracted from a personal agent instruction file, 2026-09-20. Public domain — take it,
change the colours, argue with the ordering rules.*

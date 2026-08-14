---
name: solve
description: The nine-beat workflow for solving a problem or addressing an issue - describe, look, diagnose, options, pick, build, verify, land, report. Load it whenever a message DESCRIBES a problem, friction, bug, idea or observation rather than instructing a build; also on "/solve", "work this properly", or when handed an issue to work. Holds the gate rules, the express lane, what diagnose must draw, the replay format every stop opens with, and when to escalate to grilling.
---

# Solving a problem

Loaded because a message described something rather than instructing a build.
`CLAUDE.md` → Working With Me holds the trigger; this holds the procedure.

## The nine beats

| # | Beat | Who | Produces |
|---|---|---|---|
| 1 | `describe` | user | The problem. No verb required |
| 2 | `look` | me | Read, grep, fan out agents, run things. **Read-only** |
| 3 | `diagnose` | me | Root cause with evidence, **drawn** (below). Files an issue |
| 4 | `options` | me | 2-4 real ones, numbered, best first. Mockup if user-visible |
| 5 | **`pick`** | user | **The gate.** Only place a "go" is required |
| 6 | `build` | me | Full autonomy, checklist visible, no check-ins |
| 7 | `verify` | me | Run it, read output, show the failure if there is one |
| 8 | `land` | me | Commit, merge, push, worktree gone |
| 9 | `report` | me | Replay, how to see it, ranked next steps |

## Gate rules

- 🔴 **`pick` and `report` are the ONLY interruptions.** Before the gate:
  autonomous because reading is reversible. After it: autonomous because the
  decision is made. An unplanned stop needs a decision that genuinely cannot be
  inferred, and takes `pick`'s shape.
- **`diagnose` lands as its own message**, before anything is spent on
  `options`. Cheapest exit: "that's not what's happening" costs one sentence
  there, four discarded options and a rendered mockup anywhere later.
- **`pick` may return "neither".** All options can be wrong. Not a failed beat -
  go back to `diagnose` or `options` with the corrected premise and iterate.
- **A second problem found during `build` restarts at `describe`.** Name it in
  `report`; never fix it in passing.
- **Governs non-code work too** - docs, releases, research, planning. "The docs
  are stale" is a description and often ends at `diagnose`.

## Express lane

Message already an instruction → `describe` through `pick` collapse, start at
`build`. Beats engage only for a *description*.

- Trigger is **inferred OR declared**. Read the shape; take an explicit "just do
  it" / "implement it" as the same signal. Neither outranks the other.
- Unclear → it is a description.
- Say in one line that the lane was taken and what is about to be built.

## `diagnose` draws

Prose root cause = a claim taken on trust. A picture can be disagreed with in a
second. At least one diagram; more than one is normal - structure says what the
pieces are, sequence says what they did in what order.

| Fault is | Draw |
|---|---|
| Structural - which subsystems, files, functions | Architecture diagram, failing element marked |
| Interaction - wrong order, missing hop, uncalled path | Sequence, annotated with what breaks **and where** |
| Visible to someone using the product | User journey, **before and after** |
| Quantity - how much, how many, what share | Bar (separate things), treemap (parts of a whole), pie, line |

`options` inherits it: an option clearer as a picture gets a picture, so two
architectures or two journeys sit side by side.

🔴 **`diagnose` files an issue on the project's tracker.** The diagnosis plus
its evidence IS the issue body, so the thinking survives "not now". This is the
**one** write permitted before the gate; `look` and the rest of `diagnose` stay
read-only. File it, give the number, continue to `options`.

## Every stop opens with a replay

At the top of the message, above everything - at `pick`, at `report`, at any
unplanned stop:

> Every beat so far, in order, **one line each**. Up to three bullets where a
> beat genuinely produced more than one thing. Very brief. Then the decision or
> the report.

- Covers **every** beat, never only those since the last stop. The person
  re-entering the conversation is exactly the one without that context.
- `report` closes as it opens: replay → how to see it → next steps. The last
  message has to read on its own a week later.

## Escalating to grilling

Use the `grilling` skill when `diagnose` reveals a **tree** of interlocking
decisions rather than a single fork. It is not a stress-test of a
recommendation - it is a multi-round interview that discovers the decision tree,
working a frontier of decisions whose prerequisites are settled. It produces the
options; it does not check them. So it sits **between `diagnose` and
`options`**.

- 🔴 **Never a default.** Grilling stops the user every round; the nine beats
  stop them twice. Opposite instincts. Offer it in the `diagnose` message -
  "six hanging decisions here, not one - grill it?" - and let them accept.
- **Number the questions, letter the choices inside them.** The skill numbers
  `Q1`/`Q2`; conversation options are lettered. Different objects, both apply.
- It runs its own reconnaissance between rounds (sub-agents find facts, never
  the user), so it interleaves with `look` rather than following it.

**The tell that it was needed and skipped:** requirements arriving one message
at a time, each invalidating part of what was already built. That is a frontier
that was never asked.

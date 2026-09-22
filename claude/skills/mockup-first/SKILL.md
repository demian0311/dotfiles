---
name: mockup-first
description: What a mockup must contain and how to build one — the five required parts, the mechanics, and the rule that a mockup is built BEFORE writing prose about a design. Load when ideating, shaping a flow, designing UX, or working through non-trivial architecture. A project may override the medium; Diagrammo commits dated pages to its docs site instead of publishing Artifacts.
---

# Mockup first

Any time we're ideating, shaping a flow, designing UX, or working through non-trivial
architecture — **build an HTML mockup early**, before writing prose about it. Don't ask
permission, don't wait for the design to settle; the mockup is how it settles. Paragraphs
describing an interface are the failure mode this replaces.

Every mockup carries, in order:

1. **An obvious title** — names the thing, plus a date. Someone opening it cold knows what
   it is.
2. **The problem** — 2–3 sentences. What breaks today, for whom, at what moment.
3. **The experience or architecture** — the walkthrough: what the user does, what they see,
   what the system does. For architecture, same shape — request → hop → store → response.
4. **Options, side by side** — 2–4 real alternatives, not one design plus strawmen. Each
   gets a name, a rendered mockup, and its trade-off in a line. Say which is recommended and
   why, using the 🟢/🟡/🔵/🟣/🔴 scheme.
5. **Open questions** — what the mockup doesn't answer.

Mechanics:

- Write to the session scratchpad, publish with the **Artifact** tool (load the
  `artifact-design` skill first). Self-contained, no external assets, theme-aware.
- **Ephemeral by default** — nothing committed. If one earns permanence, link its URL from
  wherever the work is tracked. A project may override both the medium and this commit rule
  in its own `CLAUDE.md`; where it does, follow it — Diagrammo, for one, commits mockups as
  dated pages in a local-only docs site instead of publishing Artifacts.
- Interactive beats static when the point is a flow — clickable steps, toggled states, real
  before/after. A picture of an idea is worth less than a thing you can poke.
- Real content and real product copy, never lorem ipsum. Verify any domain syntax against
  that project's spec.
- **Every label passes the cold-read test.** A tired stranger reading it alone must know
  what the thing is, what clicking it does, and what it costs. If it needs an explainer
  sentence underneath, rewrite the label instead of adding the note. Use the user's own
  words — ask, prompt, diagram, draw, review — never coined nouns like phrase, corpus,
  harness, pipeline, judge, baseline. This governs UI, mockups and docs alike.
- Iterate in place: same file path, republish, same URL.
- **Open it before handing it over.** A mockup nobody rendered is prose with extra steps —
  view it yourself, then tell the user the exact path to view it too.
- **Disposable by default.** Delete it once the decision lands somewhere real; version
  control keeps the history. A pile of surviving mockups means something needed deleting.

---
name: nightly-morning-review-page
description: Owner 2026-09-14 — the nightly pipeline is improved iteratively over many mornings, not fixed in one session; the ecosystem-docs nightly section is his daily reasoning surface.
metadata:
  type: feedback
---

Demian, 2026-09-14 18:26–18:29: wants a per-night report and a dgmo trend chart (issues done, end state of every row) in `diagrammo-ecosystem-docs`, with a landing page, kept up to date automatically. *"this nightly run is something that's important but ... we can't just brute force it in 1 session to get it right. so i'll need to reason about this in a good way every morning."*

**Why:** single-session pushes to fix the pipeline keep dying or overreaching (e.g. the 09-10 turn-split WIP left in `stash@{1}`); he wants steady, comparable evidence to decide on each morning.

**How to apply:** keep each pipeline change small and file follow-ups rather than grow a session. Record failures in a fixed, countable shape (category, stage, evidence file) so the landing page can show recurring patterns across nights. Point morning reports at that landing page. Related: [[cli-jsonl-8mb-turn-cap]], [[nightly-never-stops-for-checkout-state]].

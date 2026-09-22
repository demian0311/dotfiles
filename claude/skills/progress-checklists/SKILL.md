---
name: progress-checklists
description: The coloured-square checklist shown during any multi-step process — the four glyphs, what each means, the East-Asian-width rule that keeps the column aligned, and how a dropped step is recorded. Load when posting or updating a progress checklist, or when deciding which glyph a step has taken.
---

# Progress checklists

Any multi-step process — 3+ steps, or anything spanning more than one turn — shows a
checklist, so what's done and what's left is visible without asking. **It uses coloured
SQUARES; the 🟢/🟡/🔵/🟣/🔴 circles mean *priority* in a Next-steps list.** Shape is what
separates the two systems, not colour — a square is always progress, a circle is always
priority, and the two never appear in the same list.

```
Audit and split the instruction files

  🟩 Audit workspace CLAUDE.md
  🟩 Migrate generic rules to global
  🟨 Reconcile memory vs CLAUDE.md
  ⬜ Fold in the archived rules — the archive was deleted last month
  🟥 Commit across three repos
  🟥 Push main branches
```

- 🟩 done · 🟨 doing it right now · 🟥 still to do · ⬜ dropped or blocked
- **The colours track completeness, not severity.** A checklist starts all 🟥 and ends all
  🟩 — red means outstanding, never *wrong*, so a freshly posted list full of red is the
  normal opening state and reads as work ahead rather than failure. ⬜ is the one state
  outside that progression, which is why it is the recessive glyph: a dropped or blocked
  step is not work in flight and should not compete for the eye with the 🟥s that still
  need doing
- 🔴 **All four must come from the SAME width class or the column stops lining up** —
  these four are all East Asian Width `W`, so every row indents identically. Mixing is the
  hazard, not width itself: never drop a text glyph (☑, ▸, ✔) into the column, and never
  swap one square for a differently-shaped emoji. The old ballot boxes ☑ ▸ ☐ ☒ were the
  previous set and are all `W`'s opposite, `N` — a single one left behind knocks its row
  out by a cell. Checked with `unicodedata.east_asian_width` 2026-09-20
- Exactly one 🟨 at a time. Nothing is "in progress" while something else is
- One line per step, phrased as the action. No sub-bullets, no status prose
- Post it when the work starts and re-post it as states change — a stale checklist is
  worse than none
- A step that gets dropped or blocked becomes ⬜ and **stays on the list**, with the reason
  on the same line after an em dash. Silently vanishing steps read as completed. Don't use
  strikethrough as well — the square already says it, and struck text is harder to read for
  the one line that most needs reading
- ⬜ is the only state that carries a reason, and it always carries one. "⬜ Push main
  branches" alone tells the user nothing about whether they now have to do it
- **Every line is a step.** ⬜ is not a slot for a note, a heading or an aside — a checklist
  that carries information which is not a piece of work stops being scannable as progress,
  and the prose around it is where that belongs
- This is display, separate from any task-tracking tool. If a harness task list is also in
  use, the checklist is what the user reads

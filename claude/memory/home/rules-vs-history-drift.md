---
name: rules-vs-history-drift
description: The duplication incident that produced the rules-in-CLAUDE.md / history-in-memory split, decided 2026-07-31.
metadata:
  type: feedback
---

**Decided 2026-07-31.** Both stores were taking rules. Of roughly 103 rules stated in
both a CLAUDE.md and a memory note, **41 had drifted apart**, in both directions —
memory claiming `dgmo --json` was safe while the file said it writes a PNG; the file
trusting a build hook the note said never to trust.

**Why:** a periodic de-duplication sweep repairs the copies and not the cause. The cause
is that the split was being made by discipline rather than by *kind*, so the same fact
had two plausible homes.

**How to apply:** ask whether the fact tells a future session what to DO. Yes → a rule,
and it goes in a CLAUDE.md. No, it records what happened → history, and it stays a memory
note. A note that caused a rule keeps the incident and links to the rule's file, so the
next session can see why the rule is there before deleting it.

The rule itself lives in `claude/CLAUDE.md` → *Where Rules Live*.

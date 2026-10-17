---
name: push-queue-fanout
description: The 2026-10-09 incident behind "find the serial step before fanning out" — seven agents, one push queue, 20+ minutes each.
metadata:
  type: feedback
---

**Observed 2026-10-09.** Seven agents fixed their bugs in parallel, then each waited 20+
minutes in the one laptop-wide pre-push gate queue, and two had to push twice after another
landed first (rebase + re-run). The fan-out saved minutes of diagnosis and spent hours of
queueing.

**How to apply:** the rule is in `claude/CLAUDE.md` → *Subagents*: find the step that runs one
at a time before fanning out; if it costs about as much as the work, run the items in turn.
In Diagrammo the serial step is `scripts/gate-lock.sh`; check its queue first.

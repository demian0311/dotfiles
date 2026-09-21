---
name: say-issue-not-row
description: "Demian wants tracker items called \"issues\", never \"rows\" — in my replies and in every message the automations send him."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: d2c7f92b-4cbc-4826-9bad-a6851d935c40
  modified: 2026-09-16T10:39:44.908Z
---

Say **issue**, not **row**, for anything in `diagrammo/diagrammo`. Asked for on 2026-09-16: *"instead of saying 'row' let's refer to them as issues."*

**Why:** "row" was board jargon that arrived when workflow state moved onto the project board's Status field (2026-09-15). It named exactly the object "issue" already named, so it added a second word for one thing and made the writing harder to follow. Words that are genuinely about the board — a Status column, a board view — keep their own names; the tracker item does not.

**How to apply:** my own wording changes immediately. The messages he actually reads are generated from playbook prose, not the launcher shells — `nightly-decisions.sh` and `nightly-closeout.sh` contain no occurrences themselves, while `scripts/nightly-*.md`, `scripts/issue-status.sh` and `docs/agents/*.md` carry it throughout (~20 files). Changing those is what makes the 05:35 message, the close-out and the nightly summaries follow the preference. Related: [[no-shell-commands-for-demian]], [[merged-work-statuses]].

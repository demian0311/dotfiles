---
name: no-shell-commands-for-demian
description: "Owner 2026-09-15 — never hand Demian ls/grep/cat/commands as validation or follow-up; verify it myself, or surface it on a page."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: c67039dc-d7dc-49a7-9d05-b96af0c0070f
  modified: 2026-09-15T10:42:17.034Z
---

Demian, 2026-09-15 04:41, about "ls ~/.diagrammo/nightly-issues/latest/agent-slot-*.log" and "grep 8388608 … agent.log" as morning checks: *"i will never do this ... don't recommend. if we want to show me information it needs to be in a better format."*

**Why:** he reasons from pages and product behaviour, not terminal output; commands in a report are work handed back to him.

**How to apply:** run the check myself and report the result in words. Anything he should watch over time belongs on the nightly landing page (https://docs.diagrammo.app/infrastructure/nightly/runs/) — if the page lacks it, get it added there. "How to validate" = a link to open or a visible change in the product. Applies to children's reports I relay too: strip commands out. Related: [[nightly-morning-review-page]].

---
name: truncated-brief-recovery
description: "When a resumed OpenClaw brief is cut off (\"…(truncated)…\") in sessions_history, the full text is in the prior claude-cli transcript JSONL"
metadata: 
  node_type: memory
  type: reference
  originSessionId: eaa6a0c0-ce55-46ab-96b3-49491bf43460
  modified: 2026-09-15T00:28:35.186Z
---

`sessions_history` truncates long user messages (`contentTruncated: true`), so a
"resume from the brief above" message can leave half the brief unreadable.
The full, untruncated brief is on disk in the previous run's transcript:
`grep -rlF "<a phrase from the visible part>" ~/.claude/projects/-home-demian-code-diagrammo/*.jsonl`,
then walk line 0 (`type: queue-operation`) of the older match with python `json`
and print the string containing the phrase. The newest match is usually your own
session echoing the truncated copy — skip it.

**Why:** 2026-09-14 the close-out/pull-never-stops brief was cut mid-Job-2; the
missing half held the test, review, install and report requirements.
**How to apply:** recover the full text before acting on any resumed brief that
shows `…(truncated)…`. Related: [[anchor-installed-launchers-drift]].

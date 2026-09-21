---
name: stalled-agent-is-openclaw-watchdog
description: "A subagent dying with \"stopped making progress\" was killed by OpenClaw's own stuck-session watchdog after ~5-6 min of no progress, not by the Claude harness."
metadata: 
  node_type: memory
  type: reference
  originSessionId: 86f192b6-0a12-4d3f-a2e2-196c8a3edbd1
  modified: 2026-09-10T18:32:58.249Z
---

`⚠️ This turn was interrupted because it stopped making progress` on a spawned
session is **OpenClaw's gateway watchdog**, not a Claude-side heuristic and not a
runtime timeout. The gateway logs the real reason; the task record does not.

Find it with:

```
journalctl --user -u openclaw-gateway --since today | grep -E 'stalled_agent_run|abort_embedded_run'
```

The diagnostic line names the cause:

```
[diagnostic] stalled session: ... state=processing age=1987s queueDepth=0
  reason=active_work_without_progress classification=stalled_agent_run
  activeWorkKind=model_call lastProgress=tool:Bash:ended lastProgressAge=374s
→ action=abort_embedded_run  aborted=true
```

Read `activeWorkKind` and `lastProgressAge`:

- `activeWorkKind=model_call` with `lastProgressAge` ~365-375s — the model call
  itself produced nothing for ~6 minutes. Observed on tasks carrying very large
  contexts (a 2,100-line playbook plus a 1,790-line diff): big context raises
  time-to-first-token past the threshold. **Fix by shrinking the context handed
  to the session, not by retrying.**
- `activeWorkKind=tool_call` with a long, monotonically climbing
  `lastProgressAge` — a legitimately slow command (the `diagrammo-app` pre-push
  gate is ~7-10 min) looks identical to a hang from outside.

Not new behaviour: `abort_embedded_run` appears on most days since 2026-09-04, so
it is background behaviour that some tasks trip, not a regression to chase.

Two traps this creates:

1. **No completion event arrives for an aborted session.** Waiting on the
   notification means waiting forever — check `subagents(action=list)` on a
   timer instead. Same family as [[mcp-tool-absent-is-a-timeout]]: silence is
   not evidence of work continuing.
2. **Duration is not a fingerprint.** Three failures ran 34m, 33m and 12m from
   the same cause. Near-identical durations invite a "fixed wall" theory that
   the log immediately disproves.

Check whether the network was also flaky in the window — `ConnectionRefused` and
`UND_ERR_CONNECT_TIMEOUT` in the same log — before blaming context size.

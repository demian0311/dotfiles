---
name: cli-jsonl-8mb-turn-cap
description: A long agent turn dies at 8388608 chars of CLI JSONL with no config knob; only files written to disk mid-turn survive.
metadata: 
  node_type: memory
  type: project
  originSessionId: 2c5005b5-9893-429b-91bd-f45c8547fdaa
  modified: 2026-09-10T10:37:08.681Z
---

`CLI_STREAM_JSON_DEFAULT_MAX_TURN_RAW_CHARS = 8388608` (8 MB) and
`CLI_STREAM_JSON_DEFAULT_MAX_TURN_LINES = 20000` in
`openclaw/dist/cli-live-session-registry-*.js`. They are assigned into a
frozen `CLI_STREAM_JSON_OUTPUT_LIMITS` object that nothing reads config into,
so **there is no per-agent or per-server override** — unlike
[[mcp-tool-absent-is-a-timeout]], where `requestTimeoutMs` was tunable.
Confirmed at upstream HEAD too (`src/agents/cli-output-stream-limits.ts`),
where the file comment says so deliberately: *"the limits are process
constants, not per-backend configuration."* Do not re-search for a knob.

**What is and is not in the stream** (measured 2026-09-10 with a probe that
made a subagent emit 4000 marked lines): a subagent's own tool output does
**not** reach the parent stream — only its final report does. The stream is
the parent's own `assistant`, `thinking`, `system` and `user:tool_result`
events. So the lever is the parent's own tool output, and any command whose
result the parent `cat`s in full. Transcript file size is **not** a proxy for
stream size in either direction: a 16 KB stream had a 102 KB transcript,
because the transcript carries bootstrap the stream never sees.

Hit for real on 2026-09-09: the diagrammo nightly run did 4 builds over
4h00m41s and terminated with `CLI JSONL output exceeded 8388608 characters;
refusing to parse output`. It rendered as `model-fallback/decision:
candidate_failed … next=none` — the same log shape as an account session
limit, which is a different failure with a different fix.

**Why:** the cap is on the *whole turn's* raw stream, so it scales with turn
duration and tool-output volume, not with any single message. A long
unattended run walks into it.

**How to apply:** durability has to live in files the agent writes as it
goes, never in the value the turn returns. The 2026-09-09 night survived only
because `summary.txt` and `log.jsonl` were already on disk when the cap
tripped, and the launcher's report path keys off "did a summary file appear",
not off the exit code. When budgeting a long run, treat ~4 hours of heavy
tool use as the practical ceiling for one turn. Measured rate on that night:
**~2.1 MB of stream per issue built**, so about four builds per turn. The
structural fix is to spend one turn per unit of work instead of one turn per
night — each `agent exec` gets a fresh 8 MB — not to trim output, which buys
percentages against a budget that scales with the work.

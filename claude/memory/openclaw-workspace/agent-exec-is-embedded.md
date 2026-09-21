---
name: agent-exec-is-embedded
description: "openclaw agent exec runs the turn in-process, so exported env reaches the agent's shell — unlike gateway-routed runs."
metadata: 
  node_type: memory
  type: reference
  originSessionId: 83f7fb69-3013-4453-b7cc-5de2b7cd3a61
  modified: 2026-09-08T22:14:59.945Z
---

`openclaw agent exec` runs one embedded agent turn **without connecting to a
Gateway** (`docs/cli/agent.md:21`). So env exported by the calling script is
inherited by the agent process and by its Bash tool children.

Verified on anchor 2026-09-08:
`LOG_DIR=/tmp/logdir-probe-value openclaw agent exec 'print "${LOG_DIR:-UNSET}"'`
→ `SEEN=[/tmp/logdir-probe-value]`.

**Why it is worth writing down:** this is the opposite of the ACP-child
behaviour recorded in `MEMORY.md` (protected-secret sentinels and `HTTPS_PROXY`
never reach a `claude-cli` child, because the gateway assembles that child's
env). Ordinary inherited env and deliberately-withheld secret sentinels are
different mechanisms — do not generalise the secret-store limitation into "env
does not propagate to agents".

Used by `~/.diagrammo/nightly-issue-run.sh`, which now does `export
LOG_DIR="$LOG"` so the nightly playbook's `$LOG_DIR` is real.

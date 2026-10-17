---
name: read-tool-residency
description: Why "never read a whole file" is a 🔴 rule — the tool-output audit numbers behind it (dotfiles #2, 2026-09-21).
metadata:
  type: project
---

**Measured 2026-09-21 (the tool-output audit, dotfiles #2).** Tool results were ~90% of a
long session's context and `Read` three quarters of that: 49 KB per call against Bash's
1.5 KB, and every oversized result in the history was a `Read`. The cost is residency, not the
call — a file read at turn 10 of a 40-turn session is re-sent thirty more times.

**How to apply:** the rule is in `claude/CLAUDE.md` → *Execution Style*. The backstop
`CLAUDE_CODE_FILE_READ_MAX_OUTPUT_TOKENS` (12,500 tokens, then a path is handed back) is set
in `claude/settings.base.json`. See [[claude-code-context-budget]] for the per-session half.

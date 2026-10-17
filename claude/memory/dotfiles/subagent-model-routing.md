---
name: subagent-model-routing
description: Why the model is named per subagent and why `locate`/`Explore` are Haiku by definition — decided 2026-09-24, enforced by a hook 2026-09-23.
metadata:
  type: feedback
---

**Decided 2026-09-24.** A CLAUDE.md rule to "pass `haiku` for greps" almost never fired: to
that date 52 of 32,871 recorded messages had run on anything but Opus, greps included. So the
routing moved out of memory and into mechanism — the `locate` agent and the user-level
`Explore` override declare Haiku themselves (dotfiles f300691, 2026-09-23), and
`agent-model-gate.py` (PreToolUse:Agent, dotfiles a7d2e5a) refuses a model-less spawn of an
agent that has no model of its own.

**How to apply:** the rule is in `claude/CLAUDE.md` → *Subagents*: facts-found → `locate`;
bounded judgement → `sonnet`; deep reasoning → Opus.

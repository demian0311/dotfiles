#!/usr/bin/env python3
"""PreToolUse:Agent — refuse a model-less spawn of an agent that has no model of its own.

general-purpose (and `claude`, and an omitted type) inherit the main model, so a
grep dispatched that way runs on Opus. Naming `haiku` per call was a CLAUDE.md
rule that almost never fired: 52 of 32,871 recorded messages ran off Opus
(2026-09-21). Refusing costs one retried call; forgetting costs Opus rates.

Only those types are gated. Every other agent either pins a model in its
frontmatter (locate, Explore, repo-sweeper…) or is meant to inherit (Plan,
fork). Fails open: any parse error allows the call.
"""
import json
import sys

UNPINNED = {"", "general-purpose", "claude"}

REASON = (
    "Name a model for this agent. Answer is FACTS FOUND (where/what-calls/"
    "fetch/count/read-a-big-file) -> use subagent_type 'locate' or model "
    "'haiku'. Answer is a VERDICT (review, audit, is-it-correct, what-to-"
    "change) -> model 'sonnet' or 'opus'."
)


def main():
    try:
        tool_input = json.load(sys.stdin).get("tool_input") or {}
    except Exception:
        return
    kind = tool_input.get("subagent_type") or tool_input.get("agent_type") or ""
    if kind in UNPINNED and not tool_input.get("model"):
        print(json.dumps({"hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": REASON,
        }}))


main()

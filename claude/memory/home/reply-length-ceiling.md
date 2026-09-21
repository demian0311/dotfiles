---
name: reply-length-ceiling
description: Why replies are capped at a page and a half — the measured reason is cost, not context.
metadata:
  type: feedback
---

**2026-09-21, asked for directly:** "anything beyond a page and a half of text i'm just not
going to read but it makes it's way into the ongoing context." Chose a hard shape — replay,
one paragraph, ≤5 bullets, next steps — over a soft "be shorter".

**Why:** the stated reason was wrong and the instinct was right, so the rule needs its real
justification attached or someone will re-litigate it.

- **Not context.** Measured across the six largest sessions: the agent's replies are **0.4%**
  of content and thinking **0.3%**. Tool results are 89.9%. Halving the prose saves four tenths
  of one percent. See [[claude-code-context-budget]].
- **Cost, yes.** Opus 5 bills output at **5×** input ($25 vs $5 / MTok, from the model table in
  the `claude-api` skill), and input here is **96.5%** cache-served at **0.1×** (writes 1.25× on
  the 5-minute TTL, 2× on the 1-hour). Run those over the real history — 4,404 M input,
  27.1 M output — and output is **roughly a sixth of the effective spend** while being 0.6% of
  the raw token count. Per token, a shorter reply is worth ~40× a shorter context.
- **And the plain one:** unread text is waste whatever it cost.

**How to apply:** the rule is in `claude/CLAUDE.md` → *Communication Style*, with
*Completion Summary* pointing at it rather than restating the bullet count. The extract
`agents/WORKING-RULES.md` carries a de-personalised version — 🔴 **it is a copy, so the public
gist is stale until someone runs the push command in `agents/PUBLISHING.md`.**

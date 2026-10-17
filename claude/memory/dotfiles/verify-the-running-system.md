---
name: verify-the-running-system
description: The incidents behind "verify against the running system, not the deploy log" — a red CI run that was never re-tested, and one repo's blocked jobs read as the whole org's.
metadata:
  type: feedback
---

**Two incidents, both 2026.** A red CI run kept confirming a broken-token diagnosis that was
never re-tested against the live token. One repo's blocked jobs were read as the whole
organisation's without checking a second repo. In both, a claim already present in several
files was taken as checked when it had only been copied.

**How to apply:** the rule is in `claude/CLAUDE.md` → *Working Rules*: read the deployed
bundle, curl the endpoint, query the production table, check the live schema. A claim that
appears in several files is evidence of copying, not of checking.

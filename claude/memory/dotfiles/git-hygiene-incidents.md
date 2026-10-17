---
name: git-hygiene-incidents
description: What each hard git prohibition in CLAUDE.md cost before it became a rule — amend, checkout --, bare cat, -m with backticks.
metadata:
  type: feedback
---

- **`git commit --amend`** once rewrote another session's commit that had landed on top of
  ours, folding an unrelated edit into their work under their message. Hence: a follow-up fix
  is always a new commit.
- **`git checkout -- <file>`** silently discarded a collaborator's uncommitted change in that
  file. Hence: revert through `git stash push <file>` or a scratchpad copy.
- **Bare `cat` in a heredoc** is aliased to `bat` and injected ANSI escapes into hundreds of
  commit messages before anyone noticed. Hence: `command cat <<'EOF'` plus `git commit -F`.
- **`-m` with prose**: backticks in the message executed as command substitution.

**How to apply:** the rules are in `claude/CLAUDE.md` → *Git* and *Working Rules*; the
procedure is the `git-workflow` skill.

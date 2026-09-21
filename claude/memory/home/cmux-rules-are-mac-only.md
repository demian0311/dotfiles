---
name: cmux-rules-are-mac-only
description: Why the cmux sidebar rules moved out of the always-loaded CLAUDE.md into a macOS-only import on 2026-09-21.
metadata:
  type: project
---

**2026-09-21**: the cmux hook-and-pill rules moved from `claude/CLAUDE.md` into
`claude/CLAUDE.macos.md`, which `~/.claude/CLAUDE.md` imports only when
`uname -s` is `Darwin`. `install.sh` writes the second pointer line.

**Why**: cmux exists on the Mac and nowhere else. On anchor there is no `cmux` on
PATH, no `~/.cmuxterm`, no binary anywhere — yet 2,039 tokens of cmux rules loaded
on every session, plus 1,088 more in `agents/GLOBAL.md`. That was 6.7% of a 46.7k
session baseline spent on instructions the machine could not act on. Found in the
context audit (dotfiles #1).

The `GLOBAL.md` half could NOT be split the same way: Codex reads exactly one global
file (`~/.codex/AGENTS.md`), so it was compressed in place instead — rules kept, the
verification narratives dropped.

🔴 **The foreign-pointer greps in `install.sh` had to widen to
`@.*/CLAUDE(\.[a-z]+)?\.md$`.** They exist to drop another checkout's pointer line
rather than adopt it as memory (the #861 ping-pong that committed a self-import). A
pattern anchored on `CLAUDE.md` would not have recognised `CLAUDE.macos.md` as a
pointer, so a run from a worktree would have appended it to the tracked file.

Related: [[claude-code-context-budget]], [[dotfiles-self-update-mechanism]].

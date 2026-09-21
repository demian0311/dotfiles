---
name: claude-code-context-budget
description: The 2026-09-21 session-baseline audit — where the 46.7k went, what was cut, and the settings keys verified against the installed binary.
metadata:
  type: project
---

**Audited 2026-09-21 on anchor**, Opus 5 1M, from the harness's own `/context`.
Baseline before any user message: **46.7k tokens** — system tools 14.9k and system
prompt 3.3k (fixed), instruction files 20.8k and skill listings 7.6k (ours).
Filed as dotfiles #1.

**Cut that day**, option 1 of four: cmux rules to a macOS-only import, the installer
story out of *Where Rules Live*, the publishing procedure out of `GLOBAL.md`, the
claude.ai skill and plugin sync off, `mattpocock-skills` uninstalled. Instruction
files went 56,827 → 44,944 bytes (~4,100 tokens) on anchor, ~2,800 on the Mac.

**Settings keys, grepped from `~/.local/share/mise/installs/claude/latest/claude`**
rather than recalled — all present in that build:

- `skillListingBudgetFraction` — default **0.01**. Allowance is
  `contextWindow * 4 chars * fraction`. Ours was 0.08, which permits 320,000 chars
  against a ~30,000-char listing, so it was inert and still is.
- `skillListingMaxDescChars` — default **1536**. This is the knob that actually
  truncates; it is why `dataviz` stops where it does. Not yet turned down.
- `skillOverrides` — per-skill, four values: `on` (the default), `name-only` (lists
  the name without the description), `user-invocable-only` (hidden from the model,
  `/name` still works), `off` (hidden from both). `/skills` toggles it.
- `syncClaudeAiSkills` / `syncClaudeAiPlugins` — set to false. Previously synced
  skills move to `~/.claude/skills/.trash/`.
- `disableBundledSkills` (+ `CLAUDE_CODE_DISABLE_BUNDLED_SKILLS`) — all-or-nothing
  on the 2.6k of built-ins, so unusable: `artifact-design`, `update-config`,
  `code-review` and `dataviz` are load-bearing for our own rules.

🔴 **Lowering `skillListingBudgetFraction` until it bites is the wrong lever** — when
it does, skills at the bottom of the listing are dropped from Claude's view with no
announcement. They stay invocable by name, so the failure looks like a skill that
simply never triggers.

**Skill launches are almost nil.** Across 882 transcripts from 2026-08-28 to
2026-09-21 there were **11** in total: `omarchy` 4, `solve` 2, `diagnose-crash` 1,
`claude-api` 1, `artifact-design` 1, plus 2 whose name the pattern
`Launching skill: ` did not capture. 59 of the 64 skills had never fired — which is
evidence of cost, not of uselessness: `release` and `code-review` exist for occasions
that had not come up, and a skill hidden from the model can never prove its worth.

Also done 2026-09-21: `skillListingMaxDescChars` 1536 → **400** (~1.6k), and
`skillOverrides: {"dataviz": "user-invocable-only"}` (480) — `dataviz` was the largest
single entry and had never been launched. 🔴 The 400-char cap cuts `claude-api`'s
description before its SKIP paragraph, so it now over-triggers rather than under-triggers;
700 would keep the SKIP rule and still save most of it.

Still on the table: the fourteen Cloudflare skills (860), none of which has ever fired.

## The bigger half: per-session spend, audited 2026-09-21 (dotfiles #2)

Read from the `usage` records in all 882 transcripts, 2026-08-28 → 2026-09-21.
**4,404 M input tokens over 32,796 requests**; output 27.1 M. Cache reads 4,250 M
(96.5%) against 153 M writes and ~0 uncached — caching is optimal, not a candidate.

Context per request: p50 **105k**, p75 181k, p90 257k, p95 312k, p99 447k, max 644k.
**21% of requests run above 200k and carry 43.5% of all input.**

🔴 **Conversation is not the cost; tool output is.** In the six largest sessions, tool
results are **89.9%** of content, tool inputs 9.3%, and everything either party actually
said plus thinking is under 1%. Terser prose saves nothing measurable.

🔴 **`Read` is 74% of tool-result bytes** — 262 calls averaging **49.3 KB** in the 25
largest sessions, against `Bash`'s 2,568 calls averaging **1.5 KB**. All 66 results over
50 KB were `Read`; none was `Bash`. Largest single result 596 KB (~150k tokens). The cost
is residency: a file read at turn 10 of a 40-turn session is re-sent 30 more times.

Across the whole history: 1,317 `Read` results, 30.11 MB, avg 22.3 KB; 622 used
`offset`/`limit`, 695 did not. Simulated caps — 25 KB saves 48.2% of `Read` output
(366 reads affected), 50 KB saves 26.6% (143), 100 KB saves 18.5% (32).

**Done 2026-09-21:** `env.CLAUDE_CODE_FILE_READ_MAX_OUTPUT_TOKENS = "12500"` (~50 KB;
over it the content is written to a file and the path returned), plus two rules in
`claude/CLAUDE.md` — read ranges not files (*Execution Style*), and name `haiku` for
locate-or-search agents (*Subagents*). 32,742 of 32,871 messages had run on Opus; 52 on
Haiku. Subagent work is 494 M input tokens, but delegation is working — `Agent` results
average 5.2 KB, a fortieth of a `Read`.

Other verified knobs, not used: `BASH_MAX_OUTPUT_LENGTH` and a settings key capping Bash
output inline at 30,000 chars (clamped 4,000–128,000, overflow to a file plus preview) —
the key's name was not pinned down, and `Bash` averages 1.5 KB here so it does not matter.
`MAX_MCP_OUTPUT_TOKENS` is moot: zero MCP servers configured.

## Project instruction load, audited and cut 2026-09-21 (diagrammo #877)

The global files were the smaller half. A diagrammo session was loading **54.6k tokens**
before anyone typed — 16.0k global plus **38.6k** from `diagrammo/CLAUDE.md` — across 140
recorded sessions, in the largest consumer in the whole history (2,349 M input tokens).
Twelve more `CLAUDE.md` files sit under that root, 7–54 KB each, loading when work enters
their subtrees.

🔴 **Discovery was never the bottleneck.** 934 of 1,317 file reads (**70.9%**) already came
within a few tool calls of a `Grep`/`Glob`/shell search; only 383 were cold. A symbol index
addresses the 29%. `## Repo Layout` — the map — was already written, 6.9% of the file, and
simply arrived welded to 36k tokens of procedure.

**Cut to 8.0k** (111,955 → 23,236 B) by moving procedure out: skills `workspace-scripts`,
`anchor-machine`, `cross-repo-workflows`, `ui-conventions`, `diagrammo-mockups`; subtree
files `docs/CLAUDE.md` and `.agents/skills/CLAUDE.md`. Orientation and landmines stayed.
A diagrammo session now loads 24.0k.

🔴 **`diagrammo-app/`, `dgmo/` and `diagrammo-ecosystem-docs/` are SEPARATE repos that
`diagrammo` does not track**, though they sit inside `~/code/diagrammo/`. A section cannot
be pushed down into them from the diagrammo worktree — it has to become a skill instead.

🔴 **A skill here needs BOTH `.agents/skills/<name>/` and the `.claude/skills/<name>`
relative symlink, both staged.** Codex never looks inside `.claude/`. `skills-lock.json`
tracks only vendored (github-sourced) skills — all 34 entries — so locally authored ones
correctly get no entry.

Still untouched: `scripts/nightly-issue-run.md`, 199,911 B in 30 copies, read 221 times,
~7.6 MB of the 30.11 MB of all file-read output ever recorded.

Related: [[cmux-rules-are-mac-only]], [[dotfiles-self-update-mechanism]].

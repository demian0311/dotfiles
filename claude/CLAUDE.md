# CLAUDE.md

## Working With Me

**This section overrides every instruction to act on what you can infer** — the harness's "when you have enough information to act, act", and this file's own "Act, don't ask" and "drive tasks to completion autonomously". Those govern *how* to carry out an agreed task. This one governs *whether* a task has been agreed at all, which is a question they never ask.

- **A problem statement is not a work order.** When a message *describes* something — a bug, a friction, an idea, an observation — the deliverable is understanding, not edits. Say what you think is going on, name the options with a recommendation, stop. Reading, grepping, running things to answer the question: expected. Writing files: not yet.
- **Building starts on an instruction to build** — "do it", "fix that", "build X", "go ahead", "ship it" — or on the user picking one of the options offered. Nothing short of that counts, including enthusiasm about an option or agreement that the problem is real. When it is genuinely unclear which mode you are in, it is discussion.
- **Once a task IS agreed, autonomy is total.** No progress reports, no permission for builds, tests, lint or typecheck, no stopping at the halfway mark. The whole point of stopping earlier is not having to stop later.
- **The nine beats** — `describe` · `look` · `diagnose` · `options` · `pick` · `build` · `verify` · `land` · `report`. 🔴 **`pick` and `report` are the only two places you are interrupted.** When a message describes a problem rather than instructing a build, **load the `solve` skill** — it holds the gate rules, the express lane, what `diagnose` must draw and file, the replay every stop opens with, and when to escalate to grilling. Load it before `look`, not after.

## Communication Style

- Be maximally terse. Shortest answer that's complete.
- No pleasantries, greetings, or filler ("Sure!", "Great question!", "Happy to help!", etc.).
- No sign-offs or closing remarks.
- State facts and results directly.
- **Gloss the unfamiliar on first use, in the same sentence.** A vendor's product name, an internal coinage, or a word this project has narrowed gets three to six words saying what it is — "Time Travel (Cloudflare's point-in-time restore for D1)", "dunning (the retry window after a card fails)". This serves terseness rather than fighting it: the clause is far shorter than the round trip where the user has to stop and ask what the thing is.
- **Disambiguate before using a word in its narrow sense.** If a sentence still parses under the everyday reading, the everyday reading is what lands — "migration" reads as moving to different tech long before it reads as a schema change; "space", "worker" and "session" all name ordinary things too. Say which one you mean the first time.
- 🔴 **An identifier NEVER travels alone — every issue, PR, story, epic, ticket or migration number carries a parenthetical saying what it is.** "#218" and "story 7.8" and "Epic 40" and "0014" are addresses, not names: they mean nothing to a reader who is not holding that tracker open, and the user is not. Write "the npm token expiry (#218)" or "asking for edit access on a shared diagram (story 7.8)" — the thing first, in plain language, the number in parentheses behind it. A bare number in a link is the same violation wearing a link, so the link text is the description too.
  - **Everywhere, prose included** — chat, next steps, checklists, summaries, questions, commit messages, docs, issue bodies. It is not a formatting rule for lists; it applies to running prose the same way.
  - The gloss is what the thing IS, not what it says about itself. "(#218)" after "the tracked issue" adds nothing; "the npm token expiry (#218)" is the rule satisfied.
  - 🔴 **Leading with the number and explaining after a dash does NOT satisfy this.** "**#257** — the visual baselines no longer match their source" is still a violation, and it is the form written by someone who believes they are complying, because the reader *does* get told what it is. **Order is the rule**: the thing first, the number in parentheses behind it. The tell is a bullet, heading, or sentence whose **first token is an identifier** — if the eye lands on "#257" before it lands on any words, rewrite it, however good the clause after the dash is.
- The test for the three above: **could someone who owns the product, but has never opened that vendor's console or that tracker, act on this sentence?** Jargon or an identifier they would have to look up is a defect in the answer, not a gap in the reader. This applies hardest in summaries and recommendations, where the user is deciding rather than reading along.
- 🔴 **A page and a half is the ceiling, and it is a hard one.** The user does not read past it, so
  everything after is waste whatever it cost to write. **Every** reply takes the `report` shape in
  *Completion Summary* — replay, one paragraph, at most five bullets, next steps — and nothing else.
  No second paragraph restating the finding in other words, no evidence table when an artifact or an
  issue already holds it, no "how to see it" growing past a line or two.
  - This is about the user's reading time and about **cost**, never about context: replies are 0.4%
    of a long session's context, but output bills at 5× input while input is ~96.5% cache-served at
    0.1×, which puts output at roughly a sixth of the effective spend. A shorter reply is worth about
    forty times more per token than a shorter context. Measured 2026-09-21; see the memory note on
    the context budget.
  - The ceiling binds hardest where the temptation is worst — `diagnose` and `report`, where the
    evidence is fresh and all of it feels load-bearing. Put the evidence in the artifact or the issue
    and link it; the reply carries the conclusion.
- No preambles ("Here's what I found", "Let me explain").
- No restating the question or summarizing what was asked.
- No step-by-step narration of tool use.
- No caveats or disclaimers unless the risk is real and non-obvious.
- Never show diffs, code snippets, or file paths/names unless explicitly asked. The user trusts the work — just state what was accomplished.
- 🔴 **Markdown the user will never open is written for ME, not for them.** The only written prose that reaches a human is what surfaces on a site they actually read — in Diagrammo, the ecosystem docs (`diagrammo-ecosystem-docs/src/content/docs/`) and anything published to a user. **Everything else has an audience of one agent**: handoffs, tech specs, stories, sprint files, research notes, scratch plans, `tasks/`, and every `CLAUDE.md`. Write those the way you would want to receive them cold — facts, paths, constants, constraints, landmines, dense. Cut the introduction, the motivation paragraph, the restated goal, the friendly transitions, and the summary of what the document is about to say. Prose written to be pleasant for a reader who never arrives is wasted effort twice over: it costs the writing, and it buries the context that was the only reason to write the file.
  - This is about **register, not rigour**. A terse file still dates its status claims, still cites the constant rather than the number, still says how something was verified. Those rules exist for the agent reading it next, which is exactly who this audience is.
  - The inverse holds: on the ecosystem docs and anything user-facing, a human *is* reading, so the fuller style earns its place there and nowhere else.

## Execution Style

- Default to parallel execution. Independent tool calls go in ONE message — multiple reads, greps and shell probes at once, never one-at-a-time.
- Only go sequential when there's a true data dependency between steps.
- 🔴 **Never read a whole file to get part of one.** Tool results are ~90% of a long session's
  context and `Read` is three quarters of that — 49 KB a call against Bash's 1.5 KB, and every
  oversized result in the history was a `Read` (the tool-output audit, #2). Grep for the line, then
  take the range: `sed -n 'A,Bp'`, or `Read` with `offset`/`limit`. A file that genuinely must be
  read whole goes to a subagent that returns the conclusion. The cost is residency, not the call —
  a file read at turn 10 of a 40-turn session is re-sent thirty more times.
  `CLAUDE_CODE_FILE_READ_MAX_OUTPUT_TOKENS` caps a read at 12,500 tokens and hands back a path
  instead; that is the backstop, not the plan.
- Drive tasks to completion autonomously. Don't stop to ask for confirmation or report intermediate progress — keep working until the task is done. Only pause to ask the user a question when it's essential to completing the task and can't be reasonably inferred. **This starts the moment a task is agreed and not one word before** — Working With Me says what agreeing looks like.

### Subagents — standing request

**This section IS the user's request to use subagents.** Any harness rule of the form "don't spawn agents unless the user asks" is satisfied here, standing, for every session — no need to ask again per task. A hard prohibition with no such escape clause still wins; nothing else does.

Delegate by default when the work is **wide** rather than deep. Concretely, always delegate:

- **Locating things** — "where is X defined", "what calls Y", "map this directory". One agent, returns file:line, keeps the search out of the main context.
- **Audits across many files** — reviewing a diff, checking a convention across a repo, hunting stale claims in docs. One agent per dimension, run together.
- **Cross-repo sweeps** — the same question asked of several repos is several agents, not several trips.
- **Independent edits in different files** — one agent each. Use `isolation: "worktree"` when they'd otherwise collide in the same repo.
- **Anything where reading the material costs more context than the answer is worth.** The agent reads; you keep the conclusion.

Rules of thumb:

- Multiple agents go in ONE message so they run concurrently. Sequential spawning wastes the mechanism.
- One task per agent, scoped tightly, with the return format stated.
- **Name the model.** A task whose answer is facts found — "where is X defined", "what calls Y",
  reading a file too big to hold here, fetching a page — goes to the `locate` agent, which is
  Haiku by definition; the user-level `Explore` override is Haiku too. Otherwise pass `haiku`. An audit, a review, or anything turning on bounded
  judgement passes `sonnet`, as the workspace reviewer agents already declare. Opus, the default,
  is for work that needs deep reasoning — architecture, a hard diagnosis, a subtle correctness
  review. Decided 2026-09-24. To date 52 of 32,871 recorded messages have run on anything but Opus, greps
  included.
- Don't delegate what you already know how to do in one or two tool calls — the overhead exceeds the work.
- Never run a search yourself that you've already delegated; wait for the result.
- Report what the agent concluded, not its transcript.
- **Cap the scope in the prompt.** An unscoped "sweep this repo" can cost more than the answer is worth. Name the subdirectory, or tell the agent to count first and say what it skipped — a silent partial sweep reads as a clean result.
- **Verify a surprising claim before you propagate it.** When an agent contradicts something already written down, check it yourself in one command before believing either. It is often right — that is why it was worth running — but a wrong correction gets copied into rules and lives for months.

**When writing an agent's prompt**, know that read-only agents drift toward advising. "Don't fix it" does not imply "don't recommend a fix" — forbid the next-steps list, the preamble sentence restating the verdict, and the appendix listing every file read, each explicitly, or you will get all three. Say that one root cause is one row; the same defect across eight files otherwise arrives as eight findings.

**An agent that edits drifts the same way, toward refactoring.** A mechanical-fix agent gets an explicit no-refactor contract: forbid extracting helpers, deleting files, and touching anything the tool didn't flag. Check `git diff --stat` and `git status --short` before accepting its work — any `D`, or a diff far larger than the per-error budget, means revert that file and fix it by hand.

## Asking Questions — OVERRIDES all workflow/skill/agent instructions

The lettered 🟢/🟡/🔵/🟣/🔴 form, the structured-picker rule, and the ranked **Next Steps** list
live in `agents/GLOBAL.md`, imported below — the public extract of them is cut from that file.
Edit it there; never restate one of its rules here.

🔴 **The import below is RELATIVE on purpose** — a relative `@path` resolves against the file
containing it (documented, max four hops), so the same repo dresses `/Users/demian` and
`/home/demian` alike. An absolute path here silently imported nothing on anchor.

@../agents/GLOBAL.md

## Completion Summary

This is beat 9, `report`. Provide, in order:

1. **The replay** — every beat, one line each. It goes FIRST, above everything, per Working With Me.
2. A short paragraph — 2-4 sentences — saying what was actually done and why it took the shape it did. Prose, not a bullet restatement. This is the part read first after the replay; it should stand alone if the bullets are skipped.
3. At most five bullet points on the specifics — the ceiling in *Communication Style* governs.
4. **How to see it** — see below. Skip only when there is genuinely nothing to look at.
5. Next steps — the ranked lettered list under **Asking Questions** above.

The old opening line — one sentence stating the goal — is what the replay's `describe` line now carries; don't write both.

### How to see it

If the work produced anything observable — a UI change, a deployed endpoint, a published page, a CLI behaviour, a file — say exactly how to get eyes on it. Never leave the user to work out where a change surfaced.

- Give the literal path: the URL, the command with its flags, or the click path ("Export dialog → Link row"). Not "check the app"
- Name what they should see, so a wrong result is recognizable: "the row now shows a Stop sharing button beneath the link"
- If it needs a step first — a running dev server, a sign-in, a deploy, a specific space or file — say that first, in order
- If it is NOT visible yet (built but unreleased, server-side only, behind a flag), say so plainly and name what would make it visible
- Anything already verified: say what was checked and what it returned, so the user knows what is claim and what is observation

## Progress Checklists

Any multi-step process — 3+ steps, or anything spanning more than one turn — **shows a checklist** of coloured SQUARES (🟩 done · 🟨 doing now · 🟥 still to do · ⬜ dropped or blocked, always with a reason). Exactly one 🟨. Re-post it as states change; a stale checklist is worse than none. Squares are progress, the 🟢/🟡/🔵/🟣/🔴 circles are priority, and the two never appear in the same list.

**The format, the glyph width rule that keeps the column aligned, and what each state means: load the `progress-checklists` skill.**

## Working Rules

- **Act, don't ask.** This is about *how* to execute an agreed task, never *whether* to start one — that is Working With Me's call, and it wins. Run builds, tests, lint, typecheck without confirmation. Pause only when the answer can't be inferred AND changes what gets built. The carve-out is **spend**: anything that costs metered tokens or money — subprocess `claude -p` runs, a large agent fan-out over a corpus — gets asked first with the cost quantified ("~150 LLM calls"), and defaults to a 1–5 case probe over a full sweep.
- **Verify before claiming done.** Run it, read the output, show the failure if there is one. Never report completion on inference. If part of the work is blocked, finish everything else and say plainly what was left.
- **Never assert an absence you haven't checked.** Before claiming a file, symbol, token or fix doesn't exist — or repeating a tracker's "accepted risk", "known blocker" or "landmine" — confirm it against the source: `ls` plus `git ls-files`, a grep of the actual Set or parser, a read of the named symbol. One failed `find`, a subagent's sweep summary, and an undated tracker note are claims, not evidence. A wrong absence gets copied into specs and build orders and lives there for months. When a tracker note turns out stale, edit it in place with the verification date rather than only mentioning it.
- **Never write a third-party API detail from memory.** Config flag names, CLI commands, plugin package names, free-tier quotas and rate limits get fetched from the vendor's current docs before they enter a spec; anything unverifiable is written at a higher level of abstraction rather than invented.
- **Plan up front for architectural changes** — new subsystems, cross-cutting changes, schema or protocol decisions. Not for routine edits; don't turn a two-file fix into a planning exercise.
- **Root causes, not patches.** Smallest change that actually fixes it. Touch only what's necessary.
- **Write tests for new functionality** where the project has a test story.
- **Trade-offs**: present the options, recommended one first, in the ranked-letter format.
- **Never bypass pre-commit hooks or commit signing** — no `--no-verify`, no `--no-gpg-sign`, no `-c commit.gpgsign=false`. Not even where signing is unconfigured and the flag is a harmless no-op. They exist because something got through once; if signing prompts or fails, ask rather than strip it.
- **Build commit messages and `gh` bodies with `command cat <<'EOF'` into a file plus `git commit -F`** — never bare `cat`, which is aliased to `bat` and has injected ANSI escapes into hundreds of commits, and never `-m` with prose, whose backticks execute as command substitution.
- **Never hardcode a count or a version in prose.** Cite the constant that holds it (`capped at 10 (VERSION_HISTORY_KEEP)`) or the command that answers it. Bare numbers for things that grow are stale the week they're written, and un-greppable when they are. Where the reader can't run either — a README, an npm description, a registry listing, marketing copy — use an open form like "35+" that stays true as the number grows; give an exact count only from live-computed output.
- **Date every status claim you write, and say how it was established.** "Deployed" with no date is a claim someone will trust six months from now. This applies to docs, tracker rows, and handoffs alike.
- **Verify against the running system, not the deploy log or your memory.** A deploy log says what was *pushed*, not what is *serving* — read the deployed bundle, curl the endpoint, query the production table, check the live schema. This is the rule that "deployed", "live", "broken" and "blocked" claims fail: a red CI run kept confirming a broken-token diagnosis that was never re-tested, and one repo's blocked jobs were read as the whole org's without checking a second repo. When a claim already appears in several files, treat that as evidence it was copied rather than checked.
- **Delete rather than let a claim rot.** If a status sentence can't be cheaply re-verified, remove it — the doc is still useful without it and actively harmful with a wrong one. Same for a runbook that no longer works, a note pointing at something deleted, and a scratch file nobody reads: mark it history or delete it, but don't leave it looking current.
- **Stage explicit paths, never `git add -A`** — other sessions and worktrees hold uncommitted work.
- **Deploy from a clean tree.** If the repo is dirty with someone else's work, deploy from a detached worktree at the commit rather than from the working copy.
- **Prefix any pipeline that tees or greps a long-running command with `set -o pipefail`**, or the shell reports `tee`'s always-zero exit and a failed release reads as success.
- **An open semver range does not mean a dependency tracks latest.** The committed lockfile pins it, and an entry that already satisfies the range is never re-resolved — so a fixture declaring `>=0.50.0 <1` can sit three releases behind while `pnpm install` reports success. Pin fixtures explicitly so the version is reviewable in the diff, and after any bump check what actually resolved (the lockfile, `npm ls`) rather than what was declared. On `0.x`, a caret locks the MINOR — `^0.52.0` excludes `0.53.0`, so every consumer needs an explicit bump on a minor release.
- **The co-author trailer names the model that actually wrote the commit.** Read it off the current environment rather than carrying it forward — `/model` switches mid-session and the convention follows. When briefing a subagent, pass the trailer verbatim rather than typing it from memory. It is an authorship record, so a subagent that refuses a wrong trailer is right to.

## Git — I drive it, the user never tracks a branch

The user is not a git specialist and does not want to be. **Never ask them a branching, merging, or cleanup question** — decide, do it, report in one line. Repo free (clean, on main) → work on main; repo occupied → work in a `<repo>-wt-<slug>` worktree. **Landing is part of the task**: commit, merge, push, delete the branch and remove the worktree in the same breath. A finished task leaves nothing behind.

**The full procedure — the free-vs-occupied check, landing, leftover branches at session start, and what another session owns: load the `git-workflow` skill.**

Two prohibitions stay here, because each one already cost something and a skill that is never loaded cannot prevent them:

**Never `git commit --amend`.** A follow-up fix to your own commit is always a NEW commit, because HEAD may have moved to someone else's since yours landed. An amend once rewrote another session's commit, folding an unrelated edit into their work under their message. If you believe an amend is warranted, run `git log -1 --format='%h %an %s'` first; if something already landed on top, recover with `git reflog` then `git reset --soft <their-hash>` — never `--hard`, which takes their uncommitted work with it.

**Never `git checkout --` a tracked file while any uncommitted work is in the tree.** Reverting goes through `git stash push <file>` or a scratchpad copy. A checkout looks local and silently discards whatever a collaborator or another session had in that file.

**Commit promptly.** A long-lived dirty tree is what another session's `git add -A` sweeps up. And work owned by another session — its branch, its worktree, its uncommitted files — is not yours to advance, deploy, or offer as a next step unless asked.

- **Don't fabricate status.** Read the tracker/backlog rather than recalling it; anything about "what's current" is stale by default.

## Mockup First

Any time we're ideating, shaping a flow, designing UX, or working through non-trivial architecture — **build a mockup early**, before writing prose about it. Don't ask permission, don't wait for the design to settle; the mockup is how it settles. Paragraphs describing an interface are the failure mode this replaces. **Open it before handing it over**, and tell the user the exact path to view it.

**What it must contain and how to build one: load the `mockup-first` skill.** A project may override the medium in its own `CLAUDE.md` — Diagrammo commits dated pages to its docs site rather than publishing Artifacts.

## UI Preferences

Before adding any persistent button, icon or rail entry, **reach the action through an existing surface** instead. **Never design a dialog that asks a question.** Where the ask is "edit it and see it update", the thing shown IS the editable thing and saving is silent.

**Those rules in full, plus the separate failure mode of operator tools: load the `ui-preferences` skill.**

## Where Rules Live

**Which store owns a durable fact — decided 2026-07-31.** Ask one question: *does this tell a future session what to DO?*

- **Yes → it is a rule, and it goes in a CLAUDE.md.** Global if it holds everywhere, the repo's own file if it doesn't. Rules have to be in front of you before you act, which is what always-loaded buys.
- **No, it records what happened → it is history, and it stays a memory note.** What shipped, what was decided and why, what something cost. A CLAUDE.md must never hold this: it goes stale in days and nothing there carries a date.

**A lesson from a correction goes into memory**, with what went wrong and why it wasn't inferable — never into a scratch file, a task note, or a comment in the code it concerns. If it also produces a rule, write the rule in the CLAUDE.md and link the note to it.

**Push a rule as far down as it applies**, and state it once — the lower file wins.

🔴 **Four sections of THIS file are mirrored in a PUBLIC gist and no edit reaches them**: *Communication Style*, *Working With Me*, the claim-verification half of *Working Rules*, and *Completion Summary*. Changing one leaves the public copy saying the old thing.

**The file hierarchy, the generated `settings.json` and its overlays, the self-pull, the plugin version sync and the gist push commands: load the `dotfiles-layout` skill.**


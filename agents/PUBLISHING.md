# Publishing the de-personalised extracts

Not imported by any harness — read it when editing one of the extract files or one
of their sources. Kept out of `GLOBAL.md` because it is a procedure, not a rule, and
out of the extracts themselves because they are public.

## The two files, and where each is sourced from

| File | What it extracts | Sourced from |
|---|---|---|
| `agents/OPTION-GLYPHS.md` | the 🟢/🟡/🔵/🟣/🔴 circles and the 🟩/🟨/🟥/⬜ squares, with worked examples of a departure vs a continuation | `agents/GLOBAL.md` → *Presenting options* |
| `agents/WORKING-RULES.md` | build-only-when-told · say less · make claims that stand up · how to report finished work | 🔴 `claude/CLAUDE.md`, which Codex never reads — so an edit there is the one that silently strands this copy |

Four sections of `claude/CLAUDE.md` feed the second file: *Communication Style*,
*Working With Me*, the claim-verification half of *Working Rules*, and
*Completion Summary*. Changing one of those leaves the public copy saying the old
thing, with nothing to say so.

## The gist

<https://gist.github.com/demian0311/3c139b3fb8fc79640f40f0458ba6e552> — created
2026-09-20, second file added the same day. A gist is multi-file, so both render on
that one URL, alphabetically, which is why the names put the glyphs first.

🔴 **They are COPIES, so no edit anywhere reaches them.** Update the extract by hand,
then push it — one command per file, and the gist rewrites only the file named:

```bash
gh gist edit 3c139b3fb8fc79640f40f0458ba6e552 -f OPTION-GLYPHS.md  agents/OPTION-GLYPHS.md
gh gist edit 3c139b3fb8fc79640f40f0458ba6e552 -f WORKING-RULES.md  agents/WORKING-RULES.md
```

⚠️ **De-personalise on the way out.** No names, repos, hosts, issue numbers, product
names or tool names that exist in one harness only. The gist is public and anything
specific in it is both a leak and a rule a stranger cannot act on. That is also why
this file exists separately rather than as a comment at the top of each extract.

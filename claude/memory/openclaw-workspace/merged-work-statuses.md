---
name: merged-work-statuses
description: "Since 2026-09-15 merged work is Needs your check / Awaiting release / Done on the diagrammo board, with an \"Awaiting release — repo@sha\" marker; Your turn is 4 statuses, view 6"
metadata: 
  node_type: memory
  type: project
  originSessionId: fb9c0172-def0-4e33-8648-c981c34758d8
  modified: 2026-09-15T14:43:53.266Z
---

Owner design, 2026-09-15: the "Diagrammo issues" board gained **Needs your check** and **Awaiting release** between In progress and Done. First that fits for a wholly merged row: owner-only check → Needs your check; any commit in a release-shipped repo (`issue-status.sh ships-by-release`) → Awaiting release; else close. Slices left → stay Ready for agent + `partly-landed` label (never removed).

- Every landing comment on a released repo ends with `Awaiting release — <dir-name>@<sha>`; `issue-status.sh shipped` closes a row only when a *published* release contains every marker (GitHub compare `behind`/`identical`). Run by release scripts and each night's triage pass.
- **Your turn** = Needs decision, Needs your check, Human only, Needs design: board view https://github.com/orgs/diagrammo/projects/1/views/6, `issue-status.sh yours`, the 05:35 message.
- Adding ProjectV2 single-select options via `updateProjectV2Field` keeps item values **only if every existing option is passed with its `id`**; verified on a scratch project, then on the real board (35/35 intact).
- Awaiting release rows must be **open**: `issue-status.sh list` filters OPEN, so a closed row is invisible to `shipped`. The board has no reopen workflow, so reopen then `set`. On 2026-09-15 18 closed rows were reopened into it. `repo:*` labels were deliberately not added, because the marker already names each repo.
- `dgmo-content` is deliberately outside the released set (never tagged), so content-only rows close on merge.

**Why:** a closed row hid owed checks (#685). **How to apply:** never close a Needs your check / Awaiting release row by hand; add a missing marker instead. Related: [[nightly-morning-review-page]], [[no-shell-commands-for-demian]].

**Retired workflow labels stripped from every issue, 2026-09-15 09:01–09:05** (owner: "let's get rid of those labels since we're handling that with status now"): 269 ready-for-agent, 183 ready-for-human, 178 needs-triage, 13 needs-decision, 3 human-only, 1 needs-info, 1 in-progress, all closed issues. Logs in `~/.diagrammo/status-migration/retired-label-removal-*.tsv`. Label definitions kept, described "RETIRED … on no issue … Never apply", so a stale writer is visible. `issue-status.sh since` still reads the old label *events* from the timeline (verified identical for #688, #656, #765). `docs/agents/issue-statuses.md` still says ready-for-human was kept on ~183 closed issues for history, which is now stale.

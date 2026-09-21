---
name: night-by-night-report
description: "The nightly issue run's per-night docs pages + trend chart are generated at 06:00 by a silent command job; fix the script or the artifacts, never the pages."
metadata: 
  node_type: memory
  type: project
  originSessionId: 747fe6ca-4acd-4062-afcb-23272938360f
  modified: 2026-09-19T13:03:00.419Z
---

Since 2026-09-14, `diagrammo-ecosystem-docs/scripts/nightly-report.mjs` turns `~/.diagrammo/nightly-issues/` into `src/content/docs/infrastructure/nightly/runs/` (one page per night + trend page with dgmo stacked bars). Automation `ea2e272b` "Night-by-night docs" (06:00 Denver, `--no-deliver`) runs `~/.diagrammo/nightly-report.sh` → worktree `~/.diagrammo/wt/nightly-report-job` at origin/main → `scripts/nightly-report-publish.sh` (commit only runs/, push, `pnpm run deploy`). Log: `~/.diagrammo/nightly-report/latest.log`; `deployed-sha` there.

**Why:** Demian asked for a nightly report and a graph to compare runs. Kept as its own command job rather than inside the 05:40 close-out agent turn — deterministic shell, independent failure.

Since 19:30 the same day `runs/index.md` is his MORNING PAGE ("The nightly run, this morning", sidebar under Overview): last night, trend, waiting-on-you and pipeline issues live from gh (never cached, "unavailable" on failure), recurring causes from `CAUSES` (cause · stage · evidence). Issues link to a cause via `nightly-report: <key>` in the body. Follow-ups filed 2026-09-14: #798–#802.

Since 2026-09-15 (`ef36348`, pages `3e8e926`) the generator reads per-slot nights (#797 launcher): turns from `agent-slot-<n>.log` / `-session-limit.log` (start = mtime − durationMs), stop reason from the closing log.jsonl row's `stopped_by` (that row is the record even at `ended: failed`), `not_built` and unrecorded `build-<n>.started` as `turn-died-mid-build`, and `closed:false` without `slice` as "Merged, left open for the owner". dgmo has exactly 11 colour names, so the chart has no spare colour left (triaged-other is white). A baseline diff of all pages before/after is how to prove older nights unchanged. Follow-ups #811–#813.

Since `7cb9b67` (2026-09-15) *Waiting on you* reads the project board, not labels: `issue-status.sh list "Needs decision"` runs from diagrammo's origin/main via `git show` into a temp file. `agent-failed` is still a label. Triaged records carry `status` from 09-15 on, and `label` before that. The board also has "Needs your check" and "Awaiting release" columns the script doesn't know about (#817). Since `b6d760f` the section shows the owner's whole set, grouped by status. It uses `issue-status.sh yours` once origin/main has it (it's on branch `issue-statuses-release`); until then it runs `list` per status and names on the page any status the script can't read yet.

**Verified 2026-09-19 against `openclaw automations list --all`: job `ea2e272b` no longer exists and the night-page publisher is DISARMED.** Nothing generates the pages now. This is known and deliberate, not a fault — option 4 on the morning-message-length issue (#862) reads "re-arm the night-page publisher and link to it", and the issue recommends against doing it that night. Do not treat a missing/stale night page as a generator bug until that option is taken. Same morning, the five separate 05:00–05:40 announcers (digest, Last night built, gate report, Your turn, Close-out) became ONE announcing job, `diagrammo:bob-morning` "Morning (diagrammo)" `afce3f77` at **03:55**; the remaining stage jobs moved earlier (gate 02:00, retro 02:10, triage 03:00, Your turn 03:20, Close-out 03:35) and are all delivery `not requested`, feeding that one message. The old daily digest `ada21eea` is gone; a `diagrammo:morning-digest` "Weekly product digest" `cbdff4ee` now runs Mondays 05:00.

**How to apply:** a wrong night page is fixed in the generator or the artifact; a human explanation goes in `<night dir>/report-annotation.md` (written for 09-11 gateway crash, 09-12 pull.rebase refusal). The generator fails closed on unparseable JSON records. Note `log.jsonl`'s 09-11 "failed" row is the 21:00 attempt; the 21:33 relaunch landed #783. `openclaw cron add` without `--no-deliver` defaults to announce→last, which has no route on anchor. Related: [[cli-jsonl-8mb-turn-cap]], [[unstaged-root-change-kills-nightly]].

---
name: nightly-retro-job
description: "The 04:30 nightly retro automation — where it writes, how to dry-run it, and what inside agent exec cannot do"
metadata: 
  node_type: memory
  type: project
  originSessionId: 88cdf8b2-49c0-4b3e-a51a-cf9e66b70bef
  modified: 2026-09-14T23:41:03.846Z
---

The `diagrammo:nightly-retro` automation (id 8231ac56…, cron `30 4 * * *` America/Denver) was installed 2026-09-14 from main@8dbcefc. Its playbook is `scripts/nightly-retro.md` and its wrapper is `~/.diagrammo/nightly-retro.sh`. It judges the night of yesterday's 21:00 run and files 0–3 `nightly-retro` issues. Output goes to `~/.diagrammo/nightly-issues/<night>/retro.md`, plus `retro-facts.txt` and `retro-agent.log`.

Dry run: `RETRO_DRY_RUN=1 RETRO_NIGHT=<date> ~/.diagrammo/nightly-retro.sh` writes `retro-dry-run.md`. Run it longer than 10 minutes as a one-shot `openclaw cron add --at … --command … --delete-after-run`, because background Bash is denied in these sessions.

**Why:** inside `openclaw agent exec` the gateway refuses `openclaw cron` ("invalid agent runtime identity token"), so anything that needs automation run history has to be read by the wrapper shell first. A cron command shell can read it.

**How to apply:** if a morning retro looks blind, check `retro-facts.txt` before blaming the playbook. See [[anchor-installed-launchers-drift]].

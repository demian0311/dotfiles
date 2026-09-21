---
name: auto-disabled-automation-is-silent
description: An automation that auto-disables after consecutive failures stops speaking forever with no further alert; the weekly account limit is the usual cause.
metadata: 
  node_type: memory
  type: project
  originSessionId: d2c7f92b-4cbc-4826-9bad-a6851d935c40
  modified: 2026-09-16T02:14:47.351Z
---

OpenClaw auto-disables a job after 10 consecutive errors (`autoDisabled.reason = consecutive-failures`) and then says nothing again — the failure alert fires once, on the way down, and never repeats. A dead job looks identical to a quiet one.

On 2026-09-12 the hourly "Outside voices" tripwire (`dd996fa8-de92-4de7-ab1c-6e13f035a65c`) auto-disabled after 10 runs erroring `You've hit your weekly limit · resets 2am`. It is the only automation that ever messages Demian outside the 05:00–05:40 morning block, so its death read as three days of ordinary daytime silence. He noticed on 2026-09-15 and asked what was wrong. Re-enabled 2026-09-15 20:14 MDT.

**Why:** the account weekly limit is shared by the nightly issue run, the morning jobs and every hourly tripwire. When it is exhausted, hourly jobs burn their error budget fastest and die first — and they die during the window when nobody is watching.

**How to apply:** when he reports missing messages, check the job inventory for `disabled (Nx)` before touching the transport — delivery logs will look perfectly healthy because the jobs never ran. Note that only the default caller-scoped inventory is visible through the automations tool; the full list needs `--all`. Related: [[no-shell-commands-for-demian]], [[nightly-morning-review-page]].

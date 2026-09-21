---
name: dgmo-cache-dirties-app-site
description: "diagrammo_app_site dirties itself — .dgmo/references/*.json is a tracked cache whose fetchedAt is rewritten on every dgmo fetch, so its nightly pull gets REFUSED with nobody having edited anything."
metadata: 
  node_type: memory
  type: project
  originSessionId: bb1d5c79-5890-40db-b43e-7c81d226edd9
  modified: 2026-09-17T22:32:14.737Z
---

`diagrammo_app_site` tracks `.dgmo/references/dgm_*.json`, and those files carry a
`fetchedAt` epoch that a dgmo fetch rewrites even when the cached `source` payload
is byte-identical. The repo therefore goes dirty on its own, on any day something
ran a dgmo fetch there.

Observed 2026-09-17 16:30 MDT: the sole diff across all 15 repos was one line,
`fetchedAt` 1789065795531 → 1789669275034, written ~10 minutes earlier. Restoring
it (`git checkout --`, safe — it regenerates) let `git pull --rebase --ff-only`
answer *Already up to date.*

**Why:** unlike [[unstaged-root-change-kills-nightly]], this one is not a human
leaving work behind, so "don't leave the checkout dirty" does not prevent it. A
dirty sibling repo is REFUSED by the launcher's pull, and the playbook then drops
every candidate issue living in that repo — reported as one line, never as an
error, so a silently narrowed queue looks like an ordinary night.

**How to apply:** sweep `git status --porcelain --untracked-files=no` across all
siblings before 21:00, not just the root; a timestamp-only diff is safe to discard.
The real fix belongs in the repo — `fetchedAt` is a cache fact and should not be
tracked — and that is an issue to file, not a drive-by edit.

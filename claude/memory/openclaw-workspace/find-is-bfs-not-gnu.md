---
name: find-is-bfs-not-gnu
description: "/usr/bin/find on this host is bfs, which rejects relative -newermt timestamps and silently yields zero matches"
metadata: 
  node_type: memory
  type: reference
  originSessionId: c006b869-17ba-42c7-a79e-42ecdccd8067
  modified: 2026-09-08T20:13:29.331Z
---

`/usr/bin/find` on this machine is **bfs 4.1.1**, not GNU findutils. bfs rejects
relative `-newermt` arguments like `'10 minutes ago'` with `Invalid timestamp` on
**stderr** and exits with **zero matches**. A probe such as

```
find "$DIR" -newermt '10 minutes ago' -type f 2>/dev/null
```

therefore prints nothing and reads as "no files were touched" — indistinguishable
from a genuinely idle directory. This produced a false stall alarm against the
issue-745 trial run on 2026-09-08: the run had in fact written seven files and
made two commits in the window the probe called silent.

Use an absolute ISO timestamp instead:

```
CUTOFF=$(date -d '15 minutes ago' '+%Y-%m-%dT%H:%M:%S')
find "$DIR" -newermt "$CUTOFF" -type f
```

bfs accepts `2026-09-08`, `2026-09-08T14:12:54`, and offset/`Z` forms.

**How to apply:** never `2>/dev/null` a liveness probe — suppressing stderr is
what converted a tool error into false evidence. When a probe reports absence,
confirm the probe can report presence before believing it. For git worktree
liveness specifically, `git log` and the mtime of
`.git/worktrees/<name>/index` are better primary signals than file scans.

Related: [[diagrammo-nightly-issue-pipeline]]

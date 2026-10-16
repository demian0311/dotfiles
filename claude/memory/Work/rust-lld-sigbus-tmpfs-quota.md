---
name: rust-lld-sigbus-tmpfs-quota
description: "rust-lld SIGBUS core dumps on anchor = /tmp tmpfs per-user quota exhausted by a cargo target dir, not a linker bug"
metadata:
  node_type: memory
  type: project
  originSessionId: 19f86988-5801-4509-aaee-1d920670e330
  modified: 2026-10-02T12:46:41.283Z
---

2026-10-01 12:34 MDT, host `anchor`: rust-lld (toolchain 1.98.1) crashed with SIGBUS (`BUS_ADRERR`) while linking the `tauri-plugin-window-state` build script. A diagrammo review subagent was running `CARGO_TARGET_DIR=/tmp/review-785-target cargo test` from the `diagrammo-app-wt-issue-785` worktree.

/tmp is a 7.8 G tmpfs mounted with `usrquota`. In the same build, cargo logged `Disk quota exceeded (os error 122)`. lld writes its output through mmap, so running out of quota shows up as SIGBUS instead of an error. Not an Omarchy bug and not an LLVM bug.

**Why:** the coredump looks like a linker crash, and without the agent transcript it can't be told apart from one.
**How to apply:** a SIGBUS from rust-lld, gold or mold on this machine → check where the output path points and the /tmp quota before anything else. The rule now lives in diagrammo-app's CLAUDE.md (Build landmines).

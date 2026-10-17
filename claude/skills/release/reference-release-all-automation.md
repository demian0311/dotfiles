# Release skill — release-all automatic checks

### Now automatic (landed 2026-10-09; no real release has run them yet)

The three issues below stay open as `check` rows until one release does.

- **Mac pre-push** — the macOS-only failure issue (#1162). `release-cascade.sh`
  runs each package repo's REAL pre-push hook on this Mac against HEAD, in the
  background while anchor gates, and refuses before Level 0 if any hook would.
  On by default on macOS; `--no-mac-prepush` skips it (e.g. a resume whose
  shas already passed). Logs: `$LOGDIR/mac-prepush-<repo>.log`.
- **Site submodule** — the site-floors issue (#1160). `release-all.sh` refuses a
  submodule not at its recorded commit (`+`, `-`, `U` in `submodule status`),
  by name, with the update command. It never updates one itself.
- **One gate budget on anchor** — the gate-load issue (#1163). `--gate-jobs`
  (default 1) now counts the app's gate too: release-all exports
  `RELEASE_GATE_SLOTS`, and `release-remote.sh` takes a slot on the Mac before
  gating. A standalone `release-cascade.sh` sets no budget.
- **Retry alone** (#1163). A failed package gate is re-run once after the others
  finish. Pass alone → `::warning::LOAD, not code`, and the run continues; the
  first log is kept as `gate-<repo>.first.log`. The app's gate does not retry.

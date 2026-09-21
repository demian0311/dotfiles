---
name: gateway-unit-pins-pnpm-version-path
description: "The openclaw-gateway systemd unit hard-codes a version-pinned .pnpm path that `openclaw update` never rewrites, so an update would leave the gateway unable to start."
metadata: 
  node_type: memory
  type: project
  originSessionId: 7fd9b9a2-1cb2-4e95-a668-ca9831185460
  modified: 2026-09-10T01:54:41.369Z
---

On anchor, `~/.config/systemd/user/openclaw-gateway.service` had
`ExecStart=… /home/demian/.local/share/pnpm/global/5/.pnpm/openclaw@2026.9.1/node_modules/openclaw/dist/index.js`
— the realpath of the *installed version*, written by the service installer via `realpathSync`.

`openclaw update` does not reconcile that unit. Its dry-run plan is only: pnpm global
update, plugin sync, completion cache, restart + doctor. Grepping
`update-command-service-plan-*.js` and `update-command-service-*.js` for `ExecStart`,
`writeUnit`, `rewriteUnit`, `reinstall` returns nothing. So a successful
`pnpm add -g openclaw@<new>` prunes `.pnpm/openclaw@<old>/` and the very next
`systemctl restart` fails 203/EXEC — a dead gateway, which on this box means every
automation silently stops firing.

**Fixed 2026-09-09** by repointing ExecStart at the version-stable symlink
`/home/demian/.local/share/pnpm/global/5/node_modules/openclaw/dist/index.js`
(pnpm rewrites that symlink on every global install). Verified it boots:
`node …/global/5/node_modules/openclaw/dist/index.js --version`. Backup at
`openclaw-gateway.service.bak-20260909-195402`. `daemon-reload` only — no restart.

**Why:** an update that succeeds and then can't restart is indistinguishable from the
pnpm `ERR_PNPM_NO_GLOBAL_BIN_DIR` failure that preceded it — both end with a stopped
gateway — so the second bug would have been blamed on the first. Same family as
[[mcp-tool-absent-is-a-timeout]]: two causes, one symptom.

**How to apply:** before any `openclaw update`, check that ExecStart's script path
survives the version bump. Never assume the updater owns the service file.

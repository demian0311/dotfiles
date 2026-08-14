---
name: release
description: Cut an npm / GitHub release across the diagrammo workspace (dgmo, dgmo-mcp, obsidian-dgmo, remark-dgmo, astro-dgmo, docusaurus-plugin-dgmo, fumadocs-dgmo, diagrammo-app). Use when the user says "release", "cut a release", "ship it", "publish", "release X.Y.Z", or names one of the workspace repos + a version. Encodes the local-publish path (canonical) + CI fallback, the npm-token landmines, and the cross-repo dependency order.
---

# Diagrammo release skill

## Decision: which path?

**Local publish is the only path that ships anything.** CI is not a fallback — for
every npm repo but one, it cannot run at all.

| Path | When to use |
|------|-------------|
| **Local** (`./release.sh` at workspace root, or per-repo `dgmo/release.sh`; `dgmo-mcp` has `preflight.sh` + a manual `npm publish`) | Always. |
| **Tag-driven CI** (`scripts/release.sh <repo> <ver>`) | 🔴 **Dead since 2026-07-22** — the `release.yml` tag triggers were removed from all npm repos to cut Actions minutes, leaving `workflow_dispatch` only. Pushing a tag ships nothing. `obsidian-dgmo` is the sole repo where a tag still drives a release. |

🔴 **`NPM_TOKEN` is NOT broken** — that diagnosis stood for weeks, reached three
artifacts and eight workflow headers, and was **retracted 2026-07-31** after reading
a failing run's own log: it says `You cannot publish over the previously published
versions`, because a local publish had already gone out. The token authenticates for
scoped and unscoped packages alike. Its real risk is the 90-day expiry, **~2026-08-15**.

⚠️ **`npm access list packages` returning 403 does not mean the token can't publish.**
That endpoint is `GET /-/org/<user>/package`, and the local token is deliberately
issued with **Organizations → No access**, so a 403 there is expected. The check that
actually settles it is `npm publish --dry-run`: if it reaches the tarball summary and
the version check, credentials are fine. Verified 2026-07-31 during the 0.15.1 release.

**Why local is canonical**: this workspace's `NPM_TOKEN` story has been fragile (per `reference_npm_token_rotation.md` + `feedback_local_npm_token_bypass_2fa.md`). The `dgmo` CI path migrated off Trusted Publishing onto a shared org-secret on 2026-05-17 and has had at least one full-tag-pushed-but-publish-failed incident. Local publish lets the human see auth failures immediately instead of after a CI round-trip.

## Pre-flight (always, before any path)

1. `git status` in the target repo — **must be clean** (no modified tracked files).
2. `pnpm test` green.
3. `pnpm typecheck` green.
4. `pnpm build` green.
5. `CHANGELOG.md` has an entry under `## [Unreleased]` describing this release. Major user-facing features deserve marquee callouts per `feedback_release_notes_feature_callouts`.
6. Version-bump check: `grep '"version"' package.json` matches what you intend to ship; for `dgmo-mcp` also check `manifest.json` and `server.json`; for `obsidian-dgmo` also check `manifest.json`.
7. `npm whoami` returns the expected user (`demian0311`). **If 401, see "Recovery — local token invalid" below.**

## Local-publish flow (canonical)

```bash
# From workspace root, full pipeline (dgmo + app + site + mcp + homebrew)
./release.sh                       # draft GH releases by default
./release.sh --publish             # auto-publish GH releases
./release.sh --dry-run             # preflight only, no side effects
./release.sh --skip-app            # dgmo-only release
./release.sh --skip-dgmo           # everything except npm publish

# From a single repo, just that repo
cd dgmo && ./release.sh            # builds, checks, npm publish
cd dgmo && ./release.sh --dry-run  # skip the publish step
```

After publish:
- `gh release create v<version> -R diagrammo/<repo> --notes "$(cat changelog-entry.md)"` (or `--draft` if reviewing first).
- For dgmo specifically: also bump the homebrew formula via `homebrew-dgmo` repo (the workspace `release.sh` does this automatically).

## Tag-driven CI flow (fallback)

```bash
scripts/release.sh <repo> <version>          # interactive (prompts to confirm)
scripts/release.sh <repo> <version> --yes    # skip confirmation
scripts/release.sh <repo> <version> --no-wait # don't block on npm propagation
```

What it does:
1. Bumps every version field the repo's CI workflow validates.
2. Shows the diff, prompts for confirmation.
3. Commits with `Release <tag>`, tags, pushes commit + tag.
4. CI takes over from the tag — publishes to npm, creates GH release, bumps homebrew.
5. Script blocks until the new version is live on npm (or GH release for obsidian).

**Pre-rotation hazard**: if the CI's `NPM_TOKEN` is expired/revoked, the workflow gets through every step (build, lint, test, tarball pack) and only fails at `npm publish`. The tag has already been pushed by then. Recovery is in "Recovery — CI publish failed" below.

## The `npm login` trap (NEVER run it)

User authenticates to npm with a WebAuthn security key (Apple Passwords) — no TOTP. The npm CLI's "enter OTP" prompt has no answer in this setup.

**Working state**: `~/.npmrc` contains a granular access token with **Bypass 2FA for publishing** enabled, stored as `//registry.npmjs.org/:_authToken=npm_xxx...`. The token has bypass-2FA, so `npm publish` succeeds without OTP.

**Broken state**: `npm login` overwrites `~/.npmrc` with a session token that does **NOT** have bypass-2FA. Next `npm publish` returns `EOTP`; there's no way to satisfy it; ~1 hour of debugging.

**Rules:**
- **Never run `npm login` or `npm logout`.** Both rewrite `~/.npmrc`.
- **Never suggest `npm login` to the user.**
- To swap or refresh local tokens: `npm config set //registry.npmjs.org/:_authToken=npm_<new-token>` — direct file write, preserves bypass-2FA.
- If the user runs `npm login` by accident, fix immediately: generate a new bypass-2FA token and `npm config set` it.

## Token rotation playbook

**Two tokens exist:**

| Token name | Where stored | Used by |
|------------|--------------|---------|
| `local-publish` | `~/.npmrc` on the user's laptop | All local `./release.sh` invocations |
| `diagrammo-ci` | GitHub diagrammo-org Actions secret `NPM_TOKEN` | All 6 npm-publishing repos' CI workflows (`release.yml`) |

**Token type**: Both `local-publish` and `diagrammo-ci` are **Granular Access Tokens** (the npm default). The critical setting is **"Bypass two-factor authentication (2FA)"** — a checkbox under the **Security settings** section of the token-edit page, **far below** Packages and Organizations. It's the single most-missed field.

**It's easy to edit an existing token instead of generating a new one**. From https://www.npmjs.com/settings/demian0311/tokens, click the token name → edit. The Bypass 2FA checkbox is editable and the change applies to the existing token value (no need to update `~/.npmrc`). This is the fastest fix when EOTP fires after a rotation.

**Rotation procedure for `local-publish`** (Granular Access Token):

1. https://www.npmjs.com/settings/demian0311/tokens → revoke the expiring token (or skip if not expired yet and just editing).
2. **Generate New Token → Granular Access Token**. The form has many sections; pay attention to all of them, especially:
   - **Token name**: `local-publish`
   - **Expiration**: 90 days (the max — don't accept the default if it's lower)
   - **Permissions → Packages and scopes → Read and write → All packages**
   - **Organizations → No access**
   - **Security settings → Bypass two-factor authentication (2FA)**: ✅ **THE CRITICAL CHECKBOX** — it's below the Permissions section and easy to scroll past. Without it, `npm whoami` will succeed but `npm publish` will return EOTP.
3. `npm config set //registry.npmjs.org/:_authToken=npm_<new-token>`
4. Verify with both:
   - `npm whoami` → should return `demian0311`
   - `npm access list packages 2>&1 | head` → should NOT return 403; should list packages including `@diagrammo/dgmo`. A 403 here means the org-access flag is wrong, even though whoami works.
   - Optional: `cd dgmo && npm publish --dry-run` should not error with EOTP.

**Don't trust `npm whoami` alone** — it passes for tokens that authenticate but lack publish permission AND for tokens that lack bypass-2FA.

**Rotation procedure for `diagrammo-ci`** (Granular, if you keep CI publishing):

1. https://www.npmjs.com/settings/demian0311/tokens → revoke the expiring token.
2. **Generate New Token → Granular Access Token**:
   - **Bypass two-factor authentication when publishing**: ✅ **required** — verify the checkbox is on
   - Packages and scopes → Read and write → All packages
   - Organizations → No access
   - Expiry: 90 days (the max for granular)
3. GitHub → diagrammo org → Settings → Secrets and variables → Actions → `NPM_TOKEN` → Update secret → paste new value.
4. No code/workflow changes needed.

**Lifetime**:
- Classic Publish tokens: no enforced expiry, but rotate yearly for hygiene.
- Granular tokens: 90 days max. Plan to rotate every 75–80 days to avoid mid-release expiry. npm caps granular tokens at 90 days regardless of what the dropdown suggests.

**Hard-won lesson (2026-05-20 0.16.0 recovery)**: the bypass-2FA checkbox on granular tokens was missed twice in a row when generating fresh tokens. `npm whoami` returned demian0311 both times. `npm publish` returned EOTP both times. Switching to a Classic Publish token resolved it. The user's npm account uses WebAuthn (no TOTP), so EOTP is unsolvable in CLI — bypass-2FA isn't optional.

**Affected repos** (all six + future additions):
- `dgmo`, `dgmo-mcp`, `remark-dgmo`, `astro-dgmo`, `docusaurus-plugin-dgmo`, `fumadocs-dgmo`

## Cross-repo ordering

When releasing multiple repos in one session:

1. **`dgmo` first** — every other repo depends on it transitively.
2. **`dgmo-mcp` and `remark-dgmo`** next, in parallel. Both consume `@diagrammo/dgmo`.
3. **Host wrappers** (`astro-dgmo`, `docusaurus-plugin-dgmo`, `fumadocs-dgmo`) — depend on `remark-dgmo`. Release after remark is on npm.
4. **`obsidian-dgmo`** — separate convention: plain semver tag (no `v` prefix). Per `reference_obsidian_community_store`, the community store auto-picks up new versions from GH releases.
5. **`diagrammo-app`** — uses its own `diagrammo-app/release.sh` with code-signing + notarization. Releases go on `diagrammo/releases` repo (NOT `diagrammo/app`). Single `v*` tag triggers both desktop build + `online.diagrammo.app` Cloudflare Pages deploy.
6. **`diagrammo_app_site`** — 🔴 **a push to `main` deploys nothing.** That repo's Actions have been billing-blocked since 2026-07-27 (jobs never start: zero steps, `log not found`). Ship it by hand with `pnpm build && npx wrangler deploy`. Checked 2026-07-31.

The `scripts/release.sh` tag-driven path blocks until the previous repo's version is live on npm — necessary because the wrapper repos' CI runs `pnpm install` and needs the upstream version available. Local `./release.sh` does the same wait via npm view polling.

## Recovery — common failures

### Local token returns `401 Unauthorized`

Symptom: `npm whoami` returns `401`. Could happen on a "fresh" token if it was revoked by npm (security alert) or if the actual expiry was earlier than memory claimed.

Recovery: rotate `local-publish` per the playbook above. `npm publish` until then will fail.

### Local publish returns `EOTP`

Symptom: `npm publish` returns `EOTP` (One-time password required). `npm whoami` works (token authenticates), but publish fails.

Diagnosis: the token in `~/.npmrc` lacks bypass-2FA. Either someone ran `npm login`, or the token was generated without the **Bypass two-factor authentication when publishing** checkbox ticked. This checkbox is easy to miss — it's typically near the top of the form, separate from the Permissions section, and the form will save without it.

Recovery: delete the no-bypass token, generate a new granular token with **Bypass 2FA: ON** checked explicitly, then `npm config set //registry.npmjs.org/:_authToken=npm_<new-token>`. The bypass flag is the FIRST thing to verify when generating any local-publish token — `whoami` passing only tells you the token authenticates, not that it can publish.

This trap fired again on the 0.16.0 recovery (2026-05-20): user rotated to a 90-day token, `npm whoami` returned `demian0311`, but `npm publish` returned `EOTP`. Solved by regenerating with the bypass-2FA checkbox.

### CI publish returns `404 Not Found - PUT`

Symptom: GitHub Actions `release.yml` job fails at the `Publish to npm` step:
```
npm error 404 Not Found - PUT https://registry.npmjs.org/@diagrammo%2fdgmo
npm error 404 The requested resource '@diagrammo/dgmo@X.Y.Z' could not be found
or you do not have permission to access it.
```

The 404 on a PUT specifically indicates the token doesn't have publish scope for this package — usually the org `NPM_TOKEN` is expired, revoked, or doesn't carry the right "all packages / read and write" scope.

Diagnosis steps:
1. Check the token at https://www.npmjs.com/settings/demian0311/tokens — confirm it's still listed and not expired.
2. `npm access list packages npm_<copied-token>` — verify scope includes `@diagrammo/dgmo` with read-write.
3. Compare against another recently-published wrapper (`remark-dgmo` last release date) — if they all failed around the same time, it's a token issue.

Recovery: rotate `diagrammo-ci` per the playbook, then:

```bash
# Option A — re-run the failed CI job (tag already pushed)
gh run rerun <run-id> -R diagrammo/<repo> --failed

# Option B — publish locally from a clean checkout at the tag
cd <repo> && git fetch && git checkout v<version> && npm publish
gh release create v<version> -R diagrammo/<repo> --notes "$(awk '/## \['<version>'\]/{flag=1; next} /## \[/{flag=0} flag' CHANGELOG.md)"
```

Option B leaves the CI run as a failure marker but unblocks the release immediately. Prefer Option A if the token rotation can happen in minutes.

### Tag pushed, publish failed — how to redo cleanly?

If you'd rather erase the tag and republish from scratch:

```bash
git push --delete origin v<version>
git tag -d v<version>
git reset --hard HEAD^  # if the "Release v<version>" commit also needs reverting
git push --force-with-lease  # force-push only after `--delete` of the tag
```

Then rotate the token and re-run `./release.sh` or `scripts/release.sh`. **Avoid** force-push if any external consumer may have already fetched the tag.

## Common pitfalls (history-informed)

- **`npm login`** — see the trap section. Never.
- **Forgetting to update `CHANGELOG.md`** before bumping version. The release commits will include the version bump only; the changelog entry must already be present.
- **Releasing `dgmo` then immediately releasing a wrapper** before npm has propagated. The wrapper's CI will fail at `pnpm install`. `scripts/release.sh` blocks-on-npm by default; don't pass `--no-wait` across multiple repos.
- **diagrammo-app version-triple drift**: `package.json`, `src-tauri/tauri.conf.json`, and `src-tauri/Cargo.toml` must all match. `release.sh` validates and fails if any is out of sync.
- **`scheduled_tasks.lock` and similar untracked files** — fine; `release.sh` only checks tracked files. Don't `git stash` to "make it clean" — you'll lose work-in-progress on adjacent features.
- **Token expiry "feels recent" but isn't** — when in doubt, check the expiry date at https://www.npmjs.com/settings/demian0311/tokens. Memory of "rotated last week" has been wrong before.

## Memory cross-references

- `reference_npm_token_rotation` — CI-side token mechanics + 90-day cap
- `feedback_local_npm_token_bypass_2fa` — local-token + WebAuthn + the `npm login` trap
- `reference_obsidian_community_store` — Obsidian's plain-semver tag + community store auto-pickup
- `feedback_release_notes_feature_callouts` — surface major features in release notes
- `feedback_no_gpgsign_false_flag` — don't add `-c commit.gpgsign=false` to release commits
- `feedback_command_cat_for_heredocs` — use `command cat` when piping commit messages through heredoc (avoids `cat → bat` aliasing)
- `feedback_pipefail_with_tee` — `tee` returns 0 regardless; use `pipefail` to propagate upstream errors when teeing release output

## What this skill does NOT cover

- Building the desktop app (`diagrammo-app/release.sh` — signing, notarization, draft GH release on `diagrammo/releases`). Surface area too specialized; lives in its own per-repo script + workspace memory.
- Manual `npm unpublish` / `npm deprecate` for retracting bad releases.
- npm registry incidents (rare; check https://status.npmjs.org).

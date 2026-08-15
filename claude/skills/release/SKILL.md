---
name: release
description: Cut an npm / GitHub release across the diagrammo workspace (dgmo, dgmo-mcp, obsidian-dgmo, remark-dgmo, astro-dgmo, docusaurus-plugin-dgmo, fumadocs-dgmo, diagrammo-app). Use when the user says "release", "cut a release", "ship it", "publish", "release X.Y.Z", or names one of the workspace repos + a version. Encodes the dispatched-CI trusted-publishing path (canonical, and the only one that ships), what a new package needs registered before it can publish, the npm-token landmines, and the cross-repo dependency order.
---

# Diagrammo release skill

## Decision: which path?

**CI publishing over npm Trusted Publishing (OIDC) is the canonical and only path, as
of 2026-08-14.** `scripts/release.sh <repo> <version>` dispatches the release workflow
at the tag and watches it. There is no `npm publish` for a human to run, and no stored
credential sits on the publish path at all.

| Path | When to use |
|------|-------------|
| **Dispatched CI over OIDC** (`scripts/release.sh <repo> <ver>`, or the per-repo `dgmo/release.sh` inside the coordinated app release) | Always. |
| **Local `npm publish`** | 🗑 **Gone.** The `~/.npmrc` token was deleted 2026-08-15 after the first OIDC publish landed; `npm whoami` answers `need auth`. The only case that could need a token again is the **first** publish of a brand-new package name, which cannot have a trusted publisher until it exists on npm. |
| **Tag-push CI** | 🔴 **Still dead, and now deliberately.** Tag triggers came off 2026-07-22 and stay off — the reason is now "don't run the same release twice", not Actions minutes. Every workflow is `workflow_dispatch` only, with an optional `tag` input for dispatching from a branch. `obsidian-dgmo` is the sole repo where a tag push still drives its GitHub release. |

**Why the old path is gone, in one line**: npm removes direct publish from bypass-2FA
tokens in **January 2027**, and this workspace's local token expires 2026-08-19 — so
the credential the local path stood on has a hard end date, and OIDC has none.
(<https://github.blog/changelog/2026-07-31-restricting-npm-bypass-2fa-granular-access-tokens/>)

⚠️ **Actions minutes are not a reason to avoid CI here.** All ten publishing repos are
**public**, and GitHub charges nothing for Actions on public repos with standard
runners. Included minutes (2,000 Free / 3,000 Pro) are consumed by the **private**
repos only — `diagrammo_app_site`, `app`, `diagrammo-cloud`, `diagrammo-ecosystem-docs`,
`my-diagrams`, `diagrammo`. Evidence 2026-08-14: the newest `diagrammo_app_site` run
(private) failed with **0 steps** — the billing-block signature — while the newest run
in every public package repo executed real steps (`dgmo` 22, `dgmo-mcp` 20,
`nextra-dgmo` 18, `fumadocs-dgmo` 18, `vitepress-dgmo` 17, `docusaurus-plugin-dgmo` 15,
`astro-dgmo` 14, `obsidian-dgmo` 14, `remark-dgmo` 13).

### What ships what

| Package | Repo | Workflow | Tag |
|---|---|---|---|
| `@diagrammo/dgmo` | `dgmo` | `release.yml` | `vX.Y.Z` |
| `@diagrammo/dgmo-standalone` | `dgmo` | `release.yml` (same run) | `vX.Y.Z` |
| `@diagrammo/dgmo-cli` | `dgmo` | `release-cli.yml` (**new** 2026-08-14) | `cli-vX.Y.Z` |
| `@diagrammo/dgmo-mcp` | `dgmo-mcp` | `release.yml` | `vX.Y.Z` |
| `remark-dgmo` | `remark-dgmo` | `release.yml` | `vX.Y.Z` |
| `astro-dgmo` | `astro-dgmo` | `release.yml` | `vX.Y.Z` |
| `docusaurus-plugin-dgmo` | `docusaurus-plugin-dgmo` | `release.yml` | `vX.Y.Z` |
| `fumadocs-dgmo` | `fumadocs-dgmo` | `release.yml` | `vX.Y.Z` |
| `nextra-dgmo` | `nextra-dgmo` | `release.yml` | `vX.Y.Z` |
| `vitepress-dgmo` | `vitepress-dgmo` | `release.yml` | `vX.Y.Z` |

Before 2026-08-14 the CLI and the standalone drop-ins had **no CI publish path at all**
— they could only be published by hand. `obsidian-dgmo` is unchanged: it publishes no
npm package, and its tag push still drives its own GitHub release.

### The prerequisite — done for all ten on 2026-08-14, and needed again for any new package

Each package needs a **trusted publisher registered by a human** at npmjs.com:
package → Settings → Trusted Publisher → GitHub Actions, then

- **Organization or user**: `diagrammo`
- **Repository**: from the table above
- **Workflow filename**: from the table above (filename only, with `.yml`)
- **Environment name**: blank
- **Allowed actions**: `npm publish`

The runbook — every package's exact field values, both states the settings page can be
in, and what does and does not prove it worked — is
`diagrammo-ecosystem-docs/src/content/docs/infrastructure/npm-trusted-publishers.md`,
live at <https://docs.diagrammo.app/infrastructure/npm-trusted-publishers/>. There is no API for this, and since
2026-07-31 a bypass-2FA token is forbidden from changing trusted-publishing
configuration — so it cannot be automated at all.

**Until a package is registered, its publish step fails to authenticate.** That is the
error a release will hit first.

🔴 **Registration state can only be read off each package's settings page — never from
a terminal, and never from `dist.attestations`.** This skill said "no package is
registered" on 2026-08-14, inferred from `npm view <pkg> dist.attestations` being empty
everywhere. That inference is invalid: an empty attestation proves only that nothing has
ever *published* from CI, which was true because releases were run locally and the local
publish always beat the workflow to the version. **`@diagrammo/dgmo` was in fact already
registered** (`diagrammo/dgmo` · `release.yml` · `npm publish`, seen in the npm UI that
day). **All ten were registered on 2026-08-14** and confirmed by the person who did it;
and the path was proven on 2026-08-15: `vitepress-dgmo` 0.6.5 is the first version
Actions published, and `npm view vitepress-dgmo@0.6.5 dist.attestations` returns a SLSA
provenance record where 0.6.4 returns nothing. A non-empty attestation is the right
evidence that a package has *published* over OIDC — the other nine have not yet.

🔴 **The claim that the `dgmo` CI path "migrated off Trusted Publishing onto a shared
org-secret on 2026-05-17" is wrong, and was retracted 2026-08-06.** Every `release.yml`
publishes over OIDC and has for some time. Don't reintroduce it.

🔴 **`NPM_TOKEN` is NOT broken, and nothing reads it** — the broken-token diagnosis
stood for weeks, reached three artifacts and eight workflow headers, and was
**retracted 2026-07-31** after reading a failing run's own log: it says `You cannot
publish over the previously published versions`, because a local publish had already
gone out. Verified again 2026-08-14: **zero** `NODE_AUTH_TOKEN` references in any
publishing repo's workflows. Its ~2026-08-15 expiry breaks nothing and rotating it
restores nothing. Conflating that org secret with the `~/.npmrc` token is the recurring
failure here.

⚠️ **`npm access list packages` returning 403 does not mean the token can't publish.**
(Fallback token only — nothing on the OIDC path uses it.) That endpoint is
`GET /-/org/<user>/package`, and the local token is deliberately issued with
**Organizations → No access**, so a 403 there is expected. The check that actually
settles it is `npm publish --dry-run`: if it reaches the tarball summary and the
version check, credentials are fine. Verified 2026-07-31 during the 0.15.1 release.

## Pre-flight (always, before any path)

1. `git status` in the target repo — **must be clean** (no modified tracked files).
2. `pnpm test` green.
3. `pnpm typecheck` green.
4. `pnpm build` green.
5. `CHANGELOG.md` has an entry under `## [Unreleased]` describing this release. Major user-facing features deserve marquee callouts per `feedback_release_notes_feature_callouts`.
6. Version-bump check: `grep '"version"' package.json` matches what you intend to ship; for `dgmo-mcp` also check `manifest.json` and `server.json`; for `obsidian-dgmo` also check `manifest.json`.
7. **The package's trusted publisher is registered at npmjs.com** (see the prerequisite above). This is the check that used to be `npm whoami`. All ten were registered 2026-08-14, so it bites only for a **new** package or after a workflow file is renamed. `npm whoami` returning `demian0311` matters only if you are falling back to a local publish before the token expires 2026-08-19.

## The per-repo `release.sh` scripts — they no longer publish

`dgmo/release.sh` (used by the coordinated app release) stopped running `npm publish` on
2026-08-14. It now builds, runs the checks, tags if needed, dispatches `release.yml`,
watches the run, and verifies both `@diagrammo/dgmo` and `@diagrammo/dgmo-standalone`
on npm afterwards.

```bash
cd dgmo && ./release.sh            # build, check, tag, dispatch CI, watch, verify on npm
cd dgmo && ./release.sh --dry-run  # no side effects
```

For `dgmo` specifically, the homebrew formula tracks `@diagrammo/dgmo-cli` and is bumped
separately — see Cross-repo ordering below.

## Dispatched CI flow (canonical)

```bash
scripts/release.sh <repo> <version>          # interactive (prompts to confirm)
scripts/release.sh <repo> <version> --yes    # skip confirmation
scripts/release.sh <repo> <version> --no-wait # dispatch and return
```

What it does:
1. Bumps every version field that repo's workflow checks.
2. Shows the diff, prompts for confirmation.
3. Commits with `Release <tag>`, tags, pushes commit + tag.
4. **Dispatches the release workflow at that tag** — `gh workflow run <workflow> -R diagrammo/<repo> --ref <tag>`.
5. Finds the run **by tag** — not "the newest run", because several sessions release here — and watches it with `gh run watch --exit-status`.
6. Verifies the registry actually serves the new version: a green run is the deploy log, not the running system. For `dgmo` it checks the standalone package too.

`--wait` is still accepted and is now redundant; waiting is the default again. It was
opt-in from 2026-07-22, correctly, because nothing was publishing.

What the workflows themselves do, uniformly as of 2026-08-14:

- `workflow_dispatch` only, with an optional `tag` input.
- a **Resolve the tag being released** step: the tag comes from the input or `GITHUB_REF_NAME`, is validated to look like a version tag, and every later step reads its outputs rather than `GITHUB_REF_NAME`. A run started the wrong way fails there instead of publishing a version named `main`. `dgmo`'s rejects a `cli-v*` tag and vice versa.
- checkout **at that tag**, then verify the tag matches the manifest(s). `dgmo` checks `standalone/package.json` too, because `element.js` bakes the library version into its basemap URL.
- an **idempotency gate** — "is this version already on npm?" — so a re-run skips the publish instead of failing on npm's `cannot publish over the previously published versions`, which reads like a credential error and has been misread as one here before.
- `npm publish --access public --provenance` under `permissions: id-token: write`.
- a GitHub release with an explicit `tag_name`.

`dgmo-mcp`'s run also publishes to the MCP registry with `mcp-publisher login
github-oidc` — the only credential-free path there, since that registry's interactive
login mints a JWT lasting about five minutes.

**Registration hazard**: if the package's trusted publisher is not registered at
npmjs.com, the workflow gets through every step (build, lint, test, tarball pack) and
only fails at the publish step, **failing to authenticate**. The tag has already been
pushed by then. Recovery is in "Recovery — CI publish failed" below.

## The `npm login` trap (NEVER run it)

Still live, because the fallback token lives in the same file. User authenticates to npm with a WebAuthn security key (Apple Passwords) — no TOTP. The npm CLI's "enter OTP" prompt has no answer in this setup.

**Working state**: `~/.npmrc` contains a granular access token with **Bypass 2FA for publishing** enabled, stored as `//registry.npmjs.org/:_authToken=npm_xxx...`. The token has bypass-2FA, so a fallback `npm publish` succeeds without OTP.

**Broken state**: `npm login` overwrites `~/.npmrc`. Since 2025-12-09 it returns a **two-hour session token**, which does **NOT** have bypass-2FA. Next `npm publish` returns `EOTP`; there's no way to satisfy it; ~1 hour of debugging.

**Rules:**
- **Never run `npm login` or `npm logout`.** Both rewrite `~/.npmrc`.
- **Never suggest `npm login` to the user.**
- To swap or refresh the local token: `npm config set //registry.npmjs.org/:_authToken=npm_<new-token>` — direct file write, preserves bypass-2FA.
- If the user runs `npm login` by accident, fix immediately: generate a new bypass-2FA token and `npm config set` it.

## The local token — fallback only, and going away

**One token matters now:**

| Token name | Where stored | Used by |
|------------|--------------|---------|
| `local-deploy` | 🗑 **Deleted 2026-08-15.** `~/.npmrc` no longer exists on this machine | Nothing. `npm whoami` answers `need auth`, which is correct. |
| `diagrammo-ci` | GitHub diagrammo-org Actions secret `NPM_TOKEN` | 🔴 **Nothing.** No workflow reads it — verified 2026-08-14. Do not rotate it; rotating restores nothing. |

🗑 **It is gone.** `~/.npmrc` was deleted on **2026-08-15**, the day after `vitepress-dgmo`
0.6.5 proved a release could publish with no credential at all. The token itself stays
valid at npmjs.com until it expires 2026-08-19T02:01Z unless revoked there, but nothing
on the machine holds it.

🔴 **Do not mint a replacement to "unblock" a release.** A publish that fails to
authenticate is a trusted-publisher problem — read the settings page, not the token
docs. The section below survives only for the case where a genuinely new package needs
its first publish before it can have a trusted publisher.

**The critical setting** on a granular token is **"Bypass two-factor authentication (2FA)"** — a checkbox under the **Security settings** section of the token-edit page, **far below** Packages and Organizations. It's the single most-missed field.

**It's easy to edit an existing token instead of generating a new one**. From https://www.npmjs.com/settings/demian0311/tokens, click the token name → edit. The Bypass 2FA checkbox is editable and the change applies to the existing token value (no need to update `~/.npmrc`). This is the fastest fix when EOTP fires after a rotation.

**If a brand-new package needs its first publish before it can have a trusted publisher** — the one remaining case for a token, and it should be revoked again straight afterwards:

1. https://www.npmjs.com/settings/demian0311/tokens → revoke the expiring token (or skip if not expired yet and just editing).
2. **Generate New Token → Granular Access Token**. The form has many sections; pay attention to all of them, especially:
   - **Token name**: `local-deploy`
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

**Lifetime — npm's rules changed, and every older note about this is wrong:**

| Date | Change |
|---|---|
| 2025-10 | write-enabled granular tokens: default expiry 7 days, **maximum 90** (was unlimited) |
| 2025-11-19 | classic tokens permanently revoked; granular only, and all of them expire |
| 2025-12-09 | `npm login` returns a two-hour session token |
| 2026-07-31 | bypass-2FA tokens lose admin operations, including changing trusted-publishing config |
| **2027-01** | bypass-2FA tokens **lose direct publish** — reduced to reading private packages and staging a publish a maintainer approves with 2FA |

So "classic tokens have no enforced expiry" and "rotate yearly" are both false, and
**there is no such thing as a non-expiring npm token.** Any note here or in memory that
says otherwise predates 2025-11-19.

**Hard-won lesson (2026-05-20 0.16.0 recovery)**: the bypass-2FA checkbox on granular tokens was missed twice in a row when generating fresh tokens. `npm whoami` returned demian0311 both times. `npm publish` returned EOTP both times. Switching to a Classic Publish token resolved it — ⚠️ **that escape hatch no longer exists**; classic tokens were permanently revoked 2025-11-19. The user's npm account uses WebAuthn (no TOTP), so EOTP is unsolvable in CLI — bypass-2FA isn't optional.

**Affected repos**: the ten in the "What ships what" table above, plus future additions. Every new package needs its own trusted-publisher registration before its first release.

## Cross-repo ordering

When releasing multiple repos in one session:

1. **`dgmo` first** — every other repo depends on it transitively.
2. **`dgmo-mcp` and `remark-dgmo`** next, in parallel. Both consume `@diagrammo/dgmo`.
3. **Host wrappers** (`astro-dgmo`, `docusaurus-plugin-dgmo`, `fumadocs-dgmo`, `nextra-dgmo`, `vitepress-dgmo`) — all five depend on `remark-dgmo`. Release only after remark is live on npm.
   **Homebrew**: `brew install dgmo` installs `@diagrammo/dgmo-cli`, not the library. After a CLI release, bump the tap — `gh workflow run bump-homebrew.yml -R diagrammo/dgmo -f version=X.Y.Z`.
4. **`obsidian-dgmo`** — separate convention: plain semver tag (no `v` prefix). Per `reference_obsidian_community_store`, the community store auto-picks up new versions from GH releases.
5. **`diagrammo-app`** — uses its own `diagrammo-app/release.sh` with code-signing + notarization. Releases go on `diagrammo/releases` repo (NOT `diagrammo/app`). Single `v*` tag triggers both desktop build + `online.diagrammo.app` Cloudflare Pages deploy.
6. **`diagrammo_app_site`** — 🔴 **a push to `main` deploys nothing.** That repo is **private**, so its Actions runs are billing-blocked: its newest run still failed with zero steps when checked 2026-08-14. Ship it by hand with `pnpm build && npx wrangler deploy`. This does not touch the ten package repos — they are public and their Actions run free.

`scripts/release.sh` waits by default: it watches the dispatched run to completion and then verifies the version is actually being served by the registry. That wait is necessary because the wrapper repos' CI runs `pnpm install` and needs the upstream version available — so don't pass `--no-wait` when releasing several repos in sequence.

## Recovery — common failures

### Local token returns `401 Unauthorized`

**Expected, as of 2026-08-15** — there is no local token any more, and `npm whoami` answering `need auth` or `401` is the correct state. It blocks nothing: the OIDC path uses no token at all. Only mint one for a brand-new package's first publish (above), and revoke it afterwards.

### Local publish returns `EOTP`

Symptom: `npm publish` returns `EOTP` (One-time password required). `npm whoami` works (token authenticates), but publish fails.

Diagnosis: the token in `~/.npmrc` lacks bypass-2FA. Either someone ran `npm login`, or the token was generated without the **Bypass two-factor authentication when publishing** checkbox ticked. This checkbox is easy to miss — it's typically near the top of the form, separate from the Permissions section, and the form will save without it.

Recovery: delete the no-bypass token, generate a new granular token with **Bypass 2FA: ON** checked explicitly, then `npm config set //registry.npmjs.org/:_authToken=npm_<new-token>`. The bypass flag is the FIRST thing to verify when generating any `local-deploy` replacement token — `whoami` passing only tells you the token authenticates, not that it can publish.

This trap fired again on the 0.16.0 recovery (2026-05-20): user rotated to a 90-day token, `npm whoami` returned `demian0311`, but `npm publish` returned `EOTP`. Solved by regenerating with the bypass-2FA checkbox.

### CI publish failed to authenticate

Symptom: the dispatched run gets through build, lint, test and pack, and dies at the `npm publish` step on authentication.

**First suspect: the package's trusted publisher is missing or does not match.** All ten were registered 2026-08-14, so on those the likely fault is a **mismatch** — most often a workflow filename that was renamed on our side and never updated on npm's. For a package added since, it is simply not registered. Either way nothing about the run, the token or the workflow needs changing — a human has to fix it at npmjs.com.

Diagnosis steps:
1. `npm view <pkg> dist.attestations` — empty means the package has never published from CI, which is consistent with an unregistered trusted publisher.
2. Open the package at npmjs.com → Settings → Trusted Publisher, and check it against the "What ships what" table: org `diagrammo`, the right repo, the right **workflow filename**, environment blank. A mismatched workflow filename fails exactly like no registration at all.
3. 🔴 Do **not** go looking at `NPM_TOKEN`. No workflow reads it (verified 2026-08-14), so it cannot be the cause and rotating it changes nothing.

Recovery: register the package at npmjs.com — the field values are in the runbook,
<https://docs.diagrammo.app/infrastructure/npm-trusted-publishers/> — then:

```bash
# Option A — re-dispatch the workflow at the same tag (tag already pushed)
gh workflow run <workflow> -R diagrammo/<repo> --ref <tag>
# the idempotency gate skips anything already on npm, so a re-run is safe
```

Option B — publishing locally from a clean checkout at the tag — still works **only until
the `~/.npmrc` token expires 2026-08-19**, and it produces a release with no provenance
attestation. Prefer Option A; registration takes minutes and is needed anyway.

If the failure is instead `cannot publish over the previously published versions`, that is not a credential error — it means the version is already live, and the idempotency gate should have caught it. Check what the registry serves before touching anything.

### Tag pushed, publish failed — how to redo cleanly?

Usually you don't need to: fix the cause and re-dispatch at the same tag, since the workflow resolves the tag from the input and the idempotency gate makes a re-run safe. If you'd rather erase the tag and republish from scratch:

```bash
git push --delete origin v<version>
git tag -d v<version>
git reset --hard HEAD^  # if the "Release v<version>" commit also needs reverting
git push --force-with-lease  # force-push only after `--delete` of the tag
```

Then fix the cause — almost always the missing trusted-publisher registration — and re-run `scripts/release.sh`. **Avoid** force-push if any external consumer may have already fetched the tag.

## Common pitfalls (history-informed)

- **`npm login`** — see the trap section. Never.
- **Forgetting to update `CHANGELOG.md`** before bumping version. The release commits will include the version bump only; the changelog entry must already be present.
- **Releasing `dgmo` then immediately releasing a wrapper** before npm has propagated. The wrapper's CI will fail at `pnpm install`. `scripts/release.sh` waits by default; don't pass `--no-wait` across multiple repos.
- **Treating a green run as a shipped package.** A green run is the deploy log, not the running system — `scripts/release.sh` verifies the registry itself, and so should you if you dispatched by hand.
- **diagrammo-app version-triple drift**: `package.json`, `src-tauri/tauri.conf.json`, and `src-tauri/Cargo.toml` must all match. `release.sh` validates and fails if any is out of sync.
- **`scheduled_tasks.lock` and similar untracked files** — fine; `release.sh` only checks tracked files. Don't `git stash` to "make it clean" — you'll lose work-in-progress on adjacent features.
- **Token expiry "feels recent" but isn't** — when in doubt, check the expiry date at https://www.npmjs.com/settings/demian0311/tokens. Memory of "rotated last week" has been wrong before. Every npm token now expires; there is no non-expiring kind left.

## Memory cross-references

- `reference_npm_token_rotation` — token mechanics + the 90-day cap. ⚠️ Its CI-side framing is stale: CI publishes over OIDC and reads no token.
- `feedback_local_npm_token_bypass_2fa` — local-token + WebAuthn + the `npm login` trap. Still true of the fallback token; its "local publish is how we ship" framing is not, since 2026-08-14.
- `reference_obsidian_community_store` — Obsidian's plain-semver tag + community store auto-pickup
- `feedback_release_notes_feature_callouts` — surface major features in release notes
- `feedback_no_gpgsign_false_flag` — don't add `-c commit.gpgsign=false` to release commits
- `feedback_command_cat_for_heredocs` — use `command cat` when piping commit messages through heredoc (avoids `cat → bat` aliasing)
- `feedback_pipefail_with_tee` — `tee` returns 0 regardless; use `pipefail` to propagate upstream errors when teeing release output

## What this skill does NOT cover

- Building the desktop app (`diagrammo-app/release.sh` — signing, notarization, draft GH release on `diagrammo/releases`). Surface area too specialized; lives in its own per-repo script + workspace memory.
- Manual `npm unpublish` / `npm deprecate` for retracting bad releases.
- npm registry incidents (rare; check https://status.npmjs.org).

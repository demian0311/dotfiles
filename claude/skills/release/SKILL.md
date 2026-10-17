---
name: release
description: Cut an npm / GitHub release across the diagrammo workspace (dgmo, dgmo-mcp, obsidian-dgmo, remark-dgmo, astro-dgmo, docusaurus-plugin-dgmo, fumadocs-dgmo, diagrammo-app). Use when the user says "release", "cut a release", "ship it", "publish", "release X.Y.Z", or names one of the workspace repos + a version. Encodes the dispatched-CI trusted-publishing path (canonical, and the only one that ships), what a new package needs registered before it can publish, the npm-token landmines, and the cross-repo dependency order.
---

# Diagrammo release skill

## Reference files — read only when the condition holds

- Read `reference-trusted-publishers.md` before releasing a package that has never published, after renaming a release workflow, or to learn which workflow and tag ship a package.
- Read `reference-cross-repo-ordering.md` before releasing several repos by hand instead of with `release-cascade.sh`, or before a Homebrew, Obsidian or app release outside release-all.
- Read `reference-recovery.md` if a CI publish fails, a tag was pushed but the publish failed, a local token returns 401 or EOTP, or a step hangs after its log says it passed.
- Read `reference-resume.md` if release-all exits partway.
- Read `reference-release-all-automation.md` if release-all or release-cascade refuses on the Mac pre-push, a site submodule, the gate budget, or prints `::warning::LOAD, not code`.
- Read `reference-ci-workflows.md` before editing a release workflow or reading a failed run step by step.
- Read `reference-local-token.md` only if a brand-new package needs its first publish with a token.
- Read `reference-history.md` if you need why a stage runs on anchor or this Mac, someone proposes avoiding CI for Actions minutes, or you need the memory note behind a rule.

## Where the work runs — read this before choosing a command (2026-09-03, #676)

A release is four kinds of work and only one of them belongs on the laptop.
`scripts/release-all.sh` is now the entry point for a full cascade; the
per-repo `scripts/release.sh` is still correct for a single package.

```bash
# Everything: npm cascade on `anchor`, desktop app on this Mac, at the same time
scripts/release-all.sh --app 0.54.0 --publish dgmo=0.83.0 remark-dgmo=0.15.5 …

# Packages only, dependency graph walked a LEVEL at a time
scripts/release-cascade.sh dgmo=0.83.0 remark-dgmo=0.15.5 astro-dgmo=0.11.5

# Gate everything, release nothing
scripts/release-all.sh --dry-run --app 0.54.0 dgmo=0.83.0
```

Which stage runs on anchor, GitHub Actions or this Mac, and why: `reference-history.md`.

- 🔴 **The desktop app does NOT wait for the npm publish.** It declares
  `@diagrammo/dgmo` as `workspace:*` through the `packages/dgmo` symlink, so it
  consumes the dgmo **commit**. Releasing it last was habit, not a dependency.
- 🔴 **The marketing site DOES.** It declares dgmo, the standalone, `astro-dgmo`
  and `remark-dgmo` from the registry, so it is the single rejoin point — hence
  `diagrammo-app/release.sh --defer-tail` / `--tail-only`, and hence the draft
  being published only at the join (the auto-updater reads `latest.json` off
  the site, so publishing earlier hands users a 404).
- 🔴 **A remote gate proves the sha.** `scripts/release-remote.sh` fetches on
  anchor, requires that exact commit to exist there, and gates a throwaway
  worktree at it. A checkout that never fetched is how 0.51.0 shipped without
  15 commits.
- ⚠️ **anchor cannot do the Linux release either** — no `patchelf`, no Tauri
  signing key, and AppImage is the only Linux target the updater supports
  (#614).

## Before starting — checks release-all does NOT do yet (2026-10-08)

The 0.89.0 / app 0.61.0 release took ~4 hours for ~1 hour of work. Each item
below cost a restart. Run them first, until the linked issue makes them automatic.

1. **Changelog coverage** — the release-preflight checks issue (#1161). Per repo, `git log <file's last commit>..HEAD -- src/`
   against `CHANGELOG.md` (dgmo) and `RELEASE_NOTES.md` (app). A dated section
   written days ago is not proof that later commits are in it — dgmo's 0.89.0
   section missed 10.
2. **App licenses** (#1161): `cd diagrammo-app && ./scripts/generate-licenses.sh --check`.
   Stale after ANY dep bump; release.sh otherwise aborts the desktop half ~40
   min in. Regenerating also rewrites two files in `diagrammo_app_site` — commit both.

- Automatic checks release-all now runs (Mac pre-push, site submodule, gate budget, retry): `reference-release-all-automation.md`.

## After release-all — steps it skips (2026-10-08)

- **Site floors** (#1160) — automatic since 2026-10-09. Before the tail,
  release-all runs `scripts/site-floors.sh --raise --commit`: raises the four
  floors, `pnpm install`, checks `pnpm-lock.yaml` resolves exactly the versions
  in this workspace's manifests, then commits + pushes only `package.json` and
  `pnpm-lock.yaml`. Any other change in the site → it refuses and the tail does
  not run. By hand: `scripts/site-floors.sh` (check only) or `--raise --commit`.
- **Floor-bump commits**: the cascade leaves them uncommitted in every repo plus
  `diagrammo-cloud` and `factory/`. Stage only the `M` files it touched.
  🔴 In zsh `git add $files` does not word-split — pipe through `xargs git add`.
- **MCP registry** (#1164): `release.yml` 404s at "Publish to MCP Registry"
  when npm is not serving yet (~10 min after publish). Wait for
  `npm view @diagrammo/dgmo-mcp version`, then re-dispatch the same tag.
- **Homebrew**: `release-cascade.sh` dispatches `bump-homebrew.yml`, which
  opens a PR on `diagrammo/homebrew-dgmo` and squash-merges it (since
  2026-10-08). Proven by bumping 0.88.0 then 0.89.0, tap PRs 42 and 43. Check
  with `gh pr list -R diagrammo/homebrew-dgmo`: there should be nothing open.

## Finishing a release-all that died partway (until the resume issue, #1159, adds `--resume`)

Read `reference-resume.md`.

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

Why the old path is gone, and why Actions minutes are not a reason to avoid CI: `reference-history.md`.

### What ships what, and the trusted-publisher prerequisite

The package/repo/workflow/tag table and the registration procedure: `reference-trusted-publishers.md`.

🔴 **Registration state can only be read off each package's settings page — never from
a terminal, and never from `dist.attestations`.**
The 2026-08-14 evidence behind this rule: `reference-history.md`.

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

⚠️ `npm access list packages` returning 403 (fallback token only): `reference-local-token.md`.

## Pre-flight (always, before any path)

1. `git status` in the target repo — **must be clean** (no modified tracked files).
2. `pnpm test` green.
3. `pnpm typecheck` green.
4. `pnpm build` green.
5. `CHANGELOG.md` has an entry under `## [Unreleased]` describing this release. Major user-facing features deserve marquee callouts per `feedback_release_notes_feature_callouts`.
6. Version-bump check: `grep '"version"' package.json` matches what you intend to ship; for `dgmo-mcp` also check `manifest.json` and `server.json`; for `obsidian-dgmo` also check `manifest.json`.
7. **The package's trusted publisher is registered at npmjs.com** (see `reference-trusted-publishers.md`). This is the check that used to be `npm whoami`. All ten were registered 2026-08-14, so it bites only for a **new** package or after a workflow file is renamed. `npm whoami` returning `demian0311` matters only if you are falling back to a local publish before the token expires 2026-08-19.

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
separately — see `reference-cross-repo-ordering.md`.

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

What the workflows themselves do, and the `--wait` history: `reference-ci-workflows.md`.


**Registration hazard**: if the package's trusted publisher is not registered at
npmjs.com, the workflow gets through every step (build, lint, test, tarball pack) and
only fails at the publish step, **failing to authenticate**. The tag has already been
pushed by then. Recovery is in "CI publish failed to authenticate" in `reference-recovery.md`.

## The `npm login` trap (NEVER run it)

Background on the working and broken `~/.npmrc` states: `reference-local-token.md`.


**Rules:**
- **Never run `npm login` or `npm logout`.** Both rewrite `~/.npmrc`.
- **Never suggest `npm login` to the user.**
- To swap or refresh the local token: `npm config set //registry.npmjs.org/:_authToken=npm_<new-token>` — direct file write, preserves bypass-2FA.
- If the user runs `npm login` by accident, fix immediately: generate a new bypass-2FA token and `npm config set` it.

## The local token — fallback only, and going away

Token table, the bypass-2FA checkbox, first-publish procedure and lifetime rules: `reference-local-token.md`.

🔴 **Do not mint a replacement to "unblock" a release.** A publish that fails to
authenticate is a trusted-publisher problem — read the settings page, not the token
docs. The section in `reference-local-token.md` survives only for the case where a genuinely new package needs
its first publish before it can have a trusted publisher.

## Cross-repo ordering

`scripts/release-cascade.sh` encodes the dependency order. Driving it by hand: `reference-cross-repo-ordering.md`.

6. **`diagrammo_app_site`** — 🔴 **a push to `main` deploys nothing.** That repo is **private**, so its Actions runs are billing-blocked: its newest run still failed with zero steps when checked 2026-08-14. Ship it by hand with `pnpm build && npx wrangler deploy`. This does not touch the ten package repos — they are public and their Actions run free.

## Recovery — common failures

Read `reference-recovery.md`.

## Common pitfalls (history-informed)

- **`npm login`** — see the trap section. Never.
- **Forgetting to update `CHANGELOG.md`** before bumping version. The release commits will include the version bump only; the changelog entry must already be present.
- **Releasing `dgmo` then immediately releasing a wrapper** before npm has propagated. The wrapper's CI will fail at `pnpm install`. `scripts/release.sh` waits by default; don't pass `--no-wait` across multiple repos.
- **Treating a green run as a shipped package.** A green run is the deploy log, not the running system — `scripts/release.sh` verifies the registry itself, and so should you if you dispatched by hand.
- **diagrammo-app version-triple drift**: `package.json`, `src-tauri/tauri.conf.json`, and `src-tauri/Cargo.toml` must all match. `release.sh` validates and fails if any is out of sync.
- **`scheduled_tasks.lock` and similar untracked files** — fine; `release.sh` only checks tracked files. Don't `git stash` to "make it clean" — you'll lose work-in-progress on adjacent features.
- **Token expiry**: see `reference-local-token.md`.

## Memory cross-references

See `reference-history.md`.

## What this skill does NOT cover

- Building the desktop app (`diagrammo-app/release.sh` — signing, notarization, draft GH release on `diagrammo/releases`). Surface area too specialized; lives in its own per-repo script + workspace memory.
- Manual `npm unpublish` / `npm deprecate` for retracting bad releases.
- npm registry incidents (rare; check https://status.npmjs.org).

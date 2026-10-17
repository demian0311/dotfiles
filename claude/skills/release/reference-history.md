# Release skill — history and evidence

## Where each stage runs, and why

| Stage | Runs on | Why |
|---|---|---|
| Gates for every repo | **anchor** | measured 2026-09-03: `dgmo`'s suite costs 442 user-seconds here, on a laptop already at load 103.63 across ten sessions, while anchor sat at 1.31 |
| Bump, tag, push, dispatch, watch, verify on npm | anchor | its `gh` has `workflow` scope and git push works over HTTPS |
| `npm publish` | GitHub Actions | trusted publishing; the identity token cannot be minted anywhere else |
| `tauri build`, codesign, notarize, staple | **this Mac** | needs this keychain and the Apple credentials. Nothing moves this |
| site + web-editor `wrangler deploy` | this Mac | portable, but it would put a deploy credential on a second machine — deliberately not moved |

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

## Trusted-publisher registration — the 2026-08-14 evidence

This skill said "no package is
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

## Memory cross-references

- `reference_npm_token_rotation` — token mechanics + the 90-day cap. ⚠️ Its CI-side framing is stale: CI publishes over OIDC and reads no token.
- `feedback_local_npm_token_bypass_2fa` — local-token + WebAuthn + the `npm login` trap. Still true of the fallback token; its "local publish is how we ship" framing is not, since 2026-08-14.
- `reference_obsidian_community_store` — Obsidian's plain-semver tag + community store auto-pickup
- `feedback_release_notes_feature_callouts` — surface major features in release notes
- `feedback_no_gpgsign_false_flag` — don't add `-c commit.gpgsign=false` to release commits
- `feedback_command_cat_for_heredocs` — use `command cat` when piping commit messages through heredoc (avoids `cat → bat` aliasing)
- `feedback_pipefail_with_tee` — `tee` returns 0 regardless; use `pipefail` to propagate upstream errors when teeing release output

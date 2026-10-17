# Release skill — cross-repo ordering by hand

## Cross-repo ordering

`scripts/release-cascade.sh` encodes this graph and walks it a level at a time,
running the repos within a level concurrently. What follows is the same order,
for when a cascade is being driven by hand.

When releasing multiple repos in one session:

1. **`dgmo` first** — every other repo depends on it transitively.
2. **`dgmo-mcp` and `remark-dgmo`** next, in parallel. Both consume `@diagrammo/dgmo`.
3. **Host wrappers** (`astro-dgmo`, `docusaurus-plugin-dgmo`, `fumadocs-dgmo`, `nextra-dgmo`, `vitepress-dgmo`) — all five depend on `remark-dgmo`. Release only after remark is live on npm.
   **Homebrew**: `brew install dgmo` installs `@diagrammo/dgmo-cli`, not the library. After a CLI release, bump the tap — `gh workflow run bump-homebrew.yml -R diagrammo/dgmo -f version=X.Y.Z`. It opens and merges a PR on the tap.
4. **`obsidian-dgmo`** — separate convention: plain semver tag (no `v` prefix). Per `reference_obsidian_community_store`, the community store auto-picks up new versions from GH releases.
5. **`diagrammo-app`** — uses its own `diagrammo-app/release.sh` with code-signing + notarization. Releases go on `diagrammo/releases` repo (NOT `diagrammo/app`). Single `v*` tag triggers both desktop build + `online.diagrammo.app` Cloudflare Pages deploy.


`scripts/release.sh` waits by default: it watches the dispatched run to completion and then verifies the version is actually being served by the registry. That wait is necessary because the wrapper repos' CI runs `pnpm install` and needs the upstream version available — so don't pass `--no-wait` when releasing several repos in sequence.

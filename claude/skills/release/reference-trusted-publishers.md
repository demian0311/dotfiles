# Release skill — what ships what, and trusted-publisher registration

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

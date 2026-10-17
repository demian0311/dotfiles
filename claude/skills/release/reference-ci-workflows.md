# Release skill — what the release workflows do

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

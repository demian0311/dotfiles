# Release skill — recovery from common failures

## Recovery — common failures

### Local token returns `401 Unauthorized`

**Expected, as of 2026-08-15** — there is no local token any more, and `npm whoami` answering `need auth` or `401` is the correct state. It blocks nothing: the OIDC path uses no token at all. Only mint one for a brand-new package's first publish (`reference-local-token.md`), and revoke it afterwards.

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
2. Open the package at npmjs.com → Settings → Trusted Publisher, and check it against the "What ships what" table in `reference-trusted-publishers.md`: org `diagrammo`, the right repo, the right **workflow filename**, environment blank. A mismatched workflow filename fails exactly like no registration at all.
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

**A step that "hangs" after its log says it passed** is waiting for EOF on a
pipe that a leftover child process still holds. Check with `sample <pid>`, then
`lsof | grep <pipe id>`. On 2026-10-08 the culprit was `bin/anchor`'s timeout
watcher, fixed in dotfiles f89d2d0. Every gate had waited 40 min after passing.

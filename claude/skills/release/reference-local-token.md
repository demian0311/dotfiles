# Release skill — the local npm token (fallback only)

## The `npm login` trap — background

Still live, because the fallback token lives in the same file. User authenticates to npm with a WebAuthn security key (Apple Passwords) — no TOTP. The npm CLI's "enter OTP" prompt has no answer in this setup.

**Working state**: `~/.npmrc` contains a granular access token with **Bypass 2FA for publishing** enabled, stored as `//registry.npmjs.org/:_authToken=npm_xxx...`. The token has bypass-2FA, so a fallback `npm publish` succeeds without OTP.

**Broken state**: `npm login` overwrites `~/.npmrc`. Since 2025-12-09 it returns a **two-hour session token**, which does **NOT** have bypass-2FA. Next `npm publish` returns `EOTP`; there's no way to satisfy it; ~1 hour of debugging.

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


**Affected repos**: the ten in the "What ships what" table in `reference-trusted-publishers.md`, plus future additions. Every new package needs its own trusted-publisher registration before its first release.

⚠️ **`npm access list packages` returning 403 does not mean the token can't publish.**
(Fallback token only — nothing on the OIDC path uses it.) That endpoint is
`GET /-/org/<user>/package`, and the local token is deliberately issued with
**Organizations → No access**, so a 403 there is expected. The check that actually
settles it is `npm publish --dry-run`: if it reaches the tarball summary and the
version check, credentials are fine. Verified 2026-07-31 during the 0.15.1 release.

- **Token expiry "feels recent" but isn't** — when in doubt, check the expiry date at https://www.npmjs.com/settings/demian0311/tokens. Memory of "rotated last week" has been wrong before. Every npm token now expires; there is no non-expiring kind left.

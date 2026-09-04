# anchor — the front door for its dev servers

Anchor serves its dev servers over Tailscale, at real HTTPS, to any device on
the tailnet. `https://anchor.tailb10eb2.ts.net/` lists them and links to the
ones that are running.

It also carries the addresses that are **not** on this box — production, and
the vendor consoles — so the page is the one place you start from rather than a
launcher for half of it.

The front page groups everything, and the groups are the point rather than
decoration:

| Group | What is in it | On this box? |
|---|---|---|
| Diagrammo apps | the web editor, the marketing site | yes |
| Diagrammo Cloud | the Worker, the online console | yes |
| Reference | ecosystem docs, MCP studio, the API reference | yes |
| Other projects | anything that is **not** Diagrammo — currently OpenClaw | yes |
| Production | online / api / docs / diagrammo.app | no |
| Consoles | Tailscale, Cloudflare, PostHog, Issues, npm, Stripe, Resend, Google Cloud, Apple Developer, App Store Connect | no |

**Other projects** exists so OpenClaw is not read as a seventh Diagrammo
service. It runs here and it can be pointed at Diagrammo; it is a separate
project with its own repo, and the page says so in words rather than leaving a
reader to infer it from a row sitting among Diagrammo ones.

Each local entry is one row rather than a card — eight links do not need a
screen and a half of scrolling, which is what the card grid had become — and
each external one is a tile with its host under it, opening in a new tab
because reaching it is a departure rather than a navigation.

## Colour

The palette is **dgmo's own `slate`** — `palettes.slate` in `@diagrammo/dgmo`,
the one rendered at <https://diagrammo.app/slate/>. Not Tailwind's slate, which
is a different set of colours wearing the same name.

🔴 **The hexes in `hub.mjs` are a COPY, and there is no way for them not to
be.** This file has no dependencies on purpose, so it cannot import the palette
the way the marketing site does at build time. If dgmo's slate changes, this is
the second place to edit. Read the real values rather than nudging one by eye:

```bash
node -e "console.log(require('$HOME/code/diagrammo/dgmo/dist/index.js').palettes.slate)"
```

Two colour systems, deliberately disjoint, because one is identity and the
other is health:

- **The group tint** colours every icon in a group, its heading and its nav
  badge, and names a hue slot in the palette: blue, purple, teal, orange, red,
  cyan. 🔴 **Never green, yellow or gray** — those three are status, and a tint
  borrowing one could be read as a health claim.
- **The pip** on the corner of each icon is the status: green ready, yellow
  running-but-not-shared, gray stopped. **External tiles have no pip**, because
  nothing on this box can honestly say whether `dash.cloudflare.com` is up, and
  a dot that always read green would be a health check nobody performed. Their
  nav badge is a plain count for the same reason, not `4/4`.

🔴 **A hue slot is a FILL colour in this palette, not a text colour**, and
using one as text is how the first pass got it wrong. Measured against the
light ground (`surface`, `#f3f5f8`) on 2026-09-04:

| Used for | Was | Ratio | Now |
|---|---|---|---|
| the "Running, not shared" line | `yellow` `#c9a227` | **2.21:1** | `text` — the pip keeps the colour |
| detail, host and port text | `gray` `#7e8a97` | **3.22:1** | `textMuted` `#5b6672`, 5.36:1 |
| the blurb | `textMuted` | 5.36:1 | `text` `#1f2933`, 13.51:1 |

So the text ramp is the palette's own two roles — `text` for a name and a
blurb, `textMuted` for the detail beneath it — and the separation between name
and blurb comes from **weight**, not from a third colour the palette does not
have. `gray` is now used for exactly one thing: the stopped pip, where 3.22:1
clears the 3:1 a graphic needs.

⚠️ **The group headings still sit between 2.96:1 (cyan) and 4.91:1 (purple)**,
which is under the 4.5 a small bold label wants. That is accepted: there are
six groups and six usable hues, so no reassignment escapes it, and the heading
is a landmark next to full-contrast prose rather than something you read. The
alternative — darkening a hue for text — would leave the page on colours that
are not in the palette, which is the thing this section exists to prevent.

## Where the external addresses came from

🔴 **Every one of them traces to the ecosystem docs' own vendor pages**
(`infrastructure/vendors/*.md`), not to memory — including the Cloudflare
account id and the PostHog project number, both of which those pages record.
Each address was then fetched on 2026-09-04. **A redirect to a login page is
the right answer for a console**, and a 403 is a bot challenge rather than a
wrong URL.

| Tile | Address | How it checked out |
|---|---|---|
| Tailscale | `login.tailscale.com/admin/machines` | 302 → login |
| Cloudflare | `dash.cloudflare.com/<account>` | 403, bot challenge |
| PostHog | `us.posthog.com/project/351484` | 302 → login |
| Issues | `github.com/diagrammo/diagrammo/issues` | 404 to curl; repo confirmed private via `gh repo view` |
| npm | `npmjs.com` | 403 to curl **and** to a real browser |
| Stripe | `dashboard.stripe.com` | 200 → `/login` |
| Resend | `resend.com` | 200 → `/login` |
| Google Cloud | `console.cloud.google.com` | 200 → `accounts.google.com` |
| Apple Developer | `developer.apple.com/account` | 200 → `idmsa.apple.com` |
| App Store Connect | `appstoreconnect.apple.com` | 200 → `/login` |

⚠️ **npm points at the root deliberately.** `npmjs.com` answers a Cloudflare
challenge to curl *and* to a headless browser, so `/org/diagrammo` and
`/settings/diagrammo/packages` could not be confirmed either way — and an
unconfirmed deep link is a guess wearing the clothes of a fact. Package
**Settings → Trusted Publisher**, which is what you actually go there for, is
two clicks from the root. Same reasoning for Resend: the docs name an
**Emails** section but `resend.com/emails` and a nonexistent path both bounce
to the same login, so the root is what goes in.

`api.diagrammo.app` is linked at `/health` rather than at its root, because the
root has no route and its 404 reads as an outage.

## The port arithmetic

Three numbers per service, and the gaps are load-bearing:

- **local** — what the dev server binds, from the workspace port table
- **public** = local + 10000 — what `tailscale serve` terminates TLS on
- **proxy** = local + 20000 — the hub's Host-rewriting listener in between

🔴 **Public must never equal local.** Serving on the port the dev server uses
puts a tailscaled listener on that number; Vite's own availability check reads
it as busy and the dev server slides to the next port, after which the proxy
points at nothing.

🔴 **The rewriting proxy is not optional.** Vite refuses any request whose
`Host` header it does not recognise. The obvious fix is an `allowedHosts` line
in each repo's config, and it does not survive contact with git — the edit sits
in a tracked file, so stashing to take a pull removes it, the dev server
restarts without it, and the site starts answering 403 with nothing in the log
saying why. Rewriting the header in one place keeps every checkout clean.

## Adding a service

One row in `SERVICES` in `hub.mjs`, restart the hub, then on anchor:

```bash
tailscale serve --bg --https=<local+10000> http://localhost:<local+20000>
```

The proxy dials `localhost`, not a literal address, so it reaches a service on
either loopback family. That matters: Astro and vite bind `[::1]` on that box
while wrangler binds `127.0.0.1`, and pinning either one leaves half of them
answering 502.

## Notes

- The full runbook, with what breaks and why, is on the ecosystem docs site at
  `infrastructure/anchor-over-tailscale`.
- `loginctl enable-linger` is what lets the units run with nobody logged in.
- The `PATH` line in each unit is not decoration: a systemd user unit gets no
  login shell, so none of mise's tools are on its path — the same trap that
  makes `ssh anchor '<cmd>'` fail to find node.

## What each service actually needs

| Service | Local | State |
|---|---|---|
| Web editor | 5173 | unit (`anchor-editor`); serves a BUILD — see below |
| Marketing site | 4330 | unit; survives a reboot |
| Cloud API | 8787 | unit; local D1 and R2 report healthy on `/health` |
| Online console | 5190 | unit; needs a `.dev.vars` — see below |
| Ecosystem docs | 4321 | unit; survives a reboot |
| MCP studio | 4347 | unit (`anchor-studio`); gallery renders 156 of 156 |
| OpenClaw | 18789 | its own unit (`openclaw-gateway`), not installed by `install.sh` |

🔴 **A unit with `--strictPort` and `Restart=` loops forever against an orphan
holding its port, and nothing in its own log says that is what is happening.**
`anchor-studio` was found on 2026-09-03 with a **restart counter of 9,885** —
roughly fourteen hours at `RestartSec=5`, ~92 MB peak per attempt — because a
`vite` from an earlier by-hand `pnpm studio` still had `[::1]:4347`. The hub
reported the service *ready* throughout, correctly: something was serving it.
Before believing a unit is broken, run `ss -ltnp | grep ':<port> '` and read
the pid. ⚠️ `pkill -f 'vite --config …'` does not match it — the real command
line is `node …/vite/bin/vite.js --config …`, the same shape that makes the
wrangler warning below necessary.

🔴 **Killing a wrangler dev server needs the JOB, not the listener.** wrangler
runs `workerd` as a supervised child and respawns it the instant it dies, so
`pkill` on the listener frees the port for about a second. Worse, `pkill -f
"wrangler dev --port 8787"` matches nothing at all — the real command line is
`node … wrangler-dist/cli.js dev --port 8787`, and `wrangler dev` is not
contiguous in it. Kill the process group of the `wrangler-dist/cli.js` process.
Getting this wrong put both wrangler units into a restart loop against their
own orphans: 34 restarts on one, 23 on the other, ~300 MB peak per attempt.

## The web editor

`https://anchor.tailb10eb2.ts.net:15173` — the same app `online.diagrammo.app`
serves, pointed at the Cloud API on this box.

🔴 **`anchor-editor` serves a BUILD (`vite preview`), not a dev server.** Vite's
dev server hands the browser one request per module; over the tailnet the
editor's module graph did not reach `DOMContentLoaded` in 90 seconds (measured
2026-09-03, with the modules themselves answering fine — 30 concurrent fetches
in 6.9s). The build loads in 2.4s and behaves like the real thing, which is the
entire point of having it here. Rendering was compared against production in
the same headless browser and matches.

🔴 **The build is made by hand, and the two variables are read at BUILD time.**
`vite`'s `envPrefix` is `DGMO_`, so nothing set in the unit would reach the
bundle. `pnpm build:web` also rebuilds the shared dgmo checkout, which a unit
with `Restart=` would do on every crash.

```bash
cd ~/code/diagrammo/diagrammo-app
DGMO_CLOUD_API_URL=https://anchor.tailb10eb2.ts.net:18787 \
DGMO_CLOUD_WEB_URL=https://anchor.tailb10eb2.ts.net:15173 \
pnpm build:web
systemctl --user restart anchor-editor
```

🔴 **That origin must also be in `DEV_ORIGINS` in the Cloud API's `.dev.vars`.**
A browser sends the origin it was *loaded* from, which is the `:15173` https
one, not `localhost:5173` — so without it the editor loads, signs in, and every
Cloud answer is thrown away by the browser with a 200 sitting in the network
tab. `.dev.vars` REPLACES the `DEV_ORIGINS` in `wrangler.jsonc` rather than
adding to it, so the localhost entries have to be repeated there.

⚠️ A build-time API override makes the environment picker inert (by design —
`src/platform/cloud/environment.ts` says so). This editor therefore talks to
anchor's Cloud and nothing else; production would refuse the origin anyway.

🔴 **The studio's unit runs `vite` alone, never `pnpm studio`.** That command
rebuilds the shared dgmo checkout and rewrites a tracked `registry.json`, so a
unit with `Restart=` would do both on every crash. It serves what `pnpm studio`
produced; run that by hand once after a dgmo change, then restart the unit.

## The console's `.dev.vars`

It answers **503 `operation: configuration`** without one. The file is
gitignored (`online-console/.gitignore:7`) and holds three keys:

| Key | Copy from the Mac? |
|---|---|
| `GITHUB_TOKEN` | yes — must match the real GitHub account |
| `POSTHOG_PERSONAL_API_KEY` | yes — must match the real PostHog project |
| `SESSION_KEYS` | **no** — generate a fresh one per machine |

`SESSION_KEYS` is local signing material and nothing upstream checks it, so
sharing the Mac's would make a session minted on one box valid on the other for
no benefit. Generate anchor's own:

```bash
cd ~/code/diagrammo/online-console && umask 077 && node -e \
  'const b=crypto.getRandomValues(new Uint8Array(32));console.log("SESSION_KEYS="+JSON.stringify({current:{id:"anchor",key:Buffer.from(b).toString("base64url")}}))' \
  >> .dev.vars && chmod 600 .dev.vars
```

⚠️ Copying the other two puts a GitHub token and a PostHog key on a second
machine. Minting a separate GitHub token scoped for anchor would let the two be
revoked independently; that has not been done.

## The Cloud API reference

`https://anchor.tailb10eb2.ts.net/api-docs` — every endpoint, rendered by Redoc
from the spec the Worker on this box generates from its own zod schemas. There
is nothing to keep in sync: the Worker serves `/openapi.json` itself
(`app.doc(...)` in `cloud-api/src/index.ts`), so the page always shows what that
Worker is actually running.

The hub **proxies** that spec onto its own origin at `/openapi.json` rather than
pointing the browser at the Worker's port. Same origin means no cross-origin
request, so the Worker's CORS allowlist never enters into it — and the page
keeps working if that allowlist changes.

It is a **view**, not a service: no port of its own, and only as available as
the Cloud API it reads from. When that is stopped the card says which service to
start, and the spec route answers 502 with a sentence rather than a stack trace.

Redoc is pinned (`redoc@2.5.0` on jsdelivr) and loaded from the CDN, so the page
needs internet as well as the tailnet.

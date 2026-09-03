# anchor — the front door for its dev servers

Anchor serves its dev servers over Tailscale, at real HTTPS, to any device on
the tailnet. `https://anchor.tailb10eb2.ts.net/` lists them and links to the
ones that are running.

Nothing here is public. Tailscale answers only devices on your own tailnet, and
no port is open to the internet.

## Contents

| File | What |
|---|---|
| `hub.mjs` | the front door, plus one Host-rewriting proxy per service, and the Cloud API reference at `/api-docs` |
| `systemd/` | user units for the hub, the ecosystem docs and the marketing site |
| `install.sh` | run it on anchor from a checkout of this repo |

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
| Ecosystem docs | 4321 | unit; survives a reboot |
| Marketing site | 4330 | unit; survives a reboot |
| Cloud API | 8787 | unit; local D1 and R2 report healthy on `/health` |
| Online console | 5190 | unit; needs a `.dev.vars` — see below |
| MCP studio | 4347 | unit (`anchor-studio`); gallery renders 156 of 156 |

🔴 **Killing a wrangler dev server needs the JOB, not the listener.** wrangler
runs `workerd` as a supervised child and respawns it the instant it dies, so
`pkill` on the listener frees the port for about a second. Worse, `pkill -f
"wrangler dev --port 8787"` matches nothing at all — the real command line is
`node … wrangler-dist/cli.js dev --port 8787`, and `wrangler dev` is not
contiguous in it. Kill the process group of the `wrangler-dist/cli.js` process.
Getting this wrong put both wrangler units into a restart loop against their
own orphans: 34 restarts on one, 23 on the other, ~300 MB peak per attempt.

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

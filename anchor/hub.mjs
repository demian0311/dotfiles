// anchor-hub — the front door for the servers on this box, served over
// Tailscale so no port numbers have to be remembered. Each one is exposed by
// `tailscale serve` on its own https port; this page sits on 443, groups them,
// and links to the ones that are reachable.
//
// No dependencies on purpose: a hub that needs `pnpm install` to come back
// after a reboot is a hub that is down when you need it.
import http from 'node:http';
import net from 'node:net';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';

const execFileP = promisify(execFile);
const HOST = process.env.ANCHOR_HUB_HOST || 'anchor.tailb10eb2.ts.net';
const PORT = Number(process.env.ANCHOR_HUB_PORT || 7777);
// The public https port is the local port plus 10000. They must NOT match:
// tailscaled's own listener on the public port makes Vite believe the local
// port is taken, and the dev server slides to the next one.
const PUBLIC = (p) => p + 10000;
// Every service is reached through a local proxy on port + 20000, whose only
// job is to rewrite the Host header to the one the dev server expects. Vite
// refuses a Host it does not recognise, and the alternative -- an
// `allowedHosts` line in each repo's config -- means an uncommitted edit in
// every repo, which a `git stash` cycle silently drops. One place, no repo dirt.
const PROXY = (p) => p + 20000;

// The sections of the page, in order. `blurb` is what a stranger needs to know
// before reading the cards under it -- above all which of these are Diagrammo
// and which are simply other things that happen to run on this machine.
const GROUPS = [
  {
    id: 'apps',
    name: 'Diagrammo apps',
    blurb: 'What a person opens: the editor, and the page that sells it.',
  },
  {
    id: 'cloud',
    name: 'Diagrammo Cloud',
    blurb:
      'The Worker the app talks to, and the console that watches it. Its database is throwaway and lives on this box — nothing here is production data.',
  },
  {
    id: 'reference',
    name: 'Reference',
    blurb: 'How the system fits together, and what it exposes.',
  },
  {
    id: 'other',
    name: 'Other projects',
    blurb:
      'Not Diagrammo. Separate projects that happen to run on this machine. One of them drives Diagrammo; none of them are part of it.',
  },
];

// Adding a service is one row here plus one `tailscale serve` line; the
// runbook in the ecosystem docs has the whole recipe.
//
// `unit` is the systemd user unit that actually runs it, and it is what the
// card prints when the thing is stopped. Everything here is started by systemd
// rather than by hand, so a `cd … && pnpm dev` hint would be a command nobody
// runs and would leave an unsupervised second copy behind if anybody did.
const SERVICES = [
  {
    id: 'editor',
    group: 'apps',
    name: 'Web editor',
    blurb: 'The diagram editor in a browser — the same app online.diagrammo.app serves.',
    detail:
      'A dev build, so the Cloud environment picker is in Settings. It reaches the Cloud API on this box; production refuses this origin on purpose.',
    port: 5173,
    unit: 'anchor-editor',
  },
  {
    id: 'site',
    group: 'apps',
    name: 'Marketing site',
    blurb: 'The public diagrammo.app front page.',
    port: 4330,
    unit: 'anchor-site',
  },
  {
    id: 'api',
    group: 'cloud',
    name: 'Cloud API',
    blurb: 'The one Cloudflare Worker, run here by wrangler against a local database.',
    detail: 'Sign-in mail is logged rather than sent — read the link out of journalctl --user -u anchor-api.',
    port: 8787,
    unit: 'anchor-api',
  },
  {
    id: 'console',
    group: 'cloud',
    name: 'Online console',
    blurb: 'Cloud health and the issue board.',
    detail: 'Sign in to see anything — every data route needs a session.',
    port: 5190,
    unit: 'anchor-console',
  },
  {
    id: 'docs',
    group: 'reference',
    name: 'Ecosystem docs',
    blurb: 'How the app, the Workers and the vendors fit together.',
    port: 4321,
    unit: 'anchor-docs',
  },
  {
    id: 'mcp',
    group: 'reference',
    name: 'MCP studio',
    blurb: 'Inspector for the dgmo MCP server, with a rendered gallery per chart type.',
    detail: 'It serves what pnpm studio last produced, so run that by hand after a dgmo change.',
    port: 4347,
    unit: 'anchor-studio',
  },
  {
    // Not a dev server and not in the diagrammo tree.
    //
    // hostRewrite is off because the gateway checks the Origin it was reached
    // on; rewriting Host to localhost makes it refuse the pairing routes.
    id: 'openclaw',
    group: 'other',
    name: 'OpenClaw',
    blurb: 'A personal agent gateway and its control page, on the Claude CLI backend.',
    detail:
      'Its own project, with its own repo and no Diagrammo code in it. It can be pointed at Diagrammo — draw a diagram, drive the CLI — the way it can be pointed at anything else.',
    port: 18789,
    hostRewrite: false,
    unit: 'openclaw-gateway',
  },
];

// Views the hub serves itself, off the back of a service that is already
// running. A view is not a second server: it has no port of its own, it lives
// on a path of this page's origin, and it is only as available as the service
// it reads from.
const VIEWS = [
  {
    id: 'api-docs',
    group: 'reference',
    name: 'Cloud API reference',
    blurb: 'Every endpoint, generated from the schemas the Worker on this box is serving.',
    path: '/api-docs',
    dependsOn: 'api',
  },
];

// A TCP connect on both loopback families: Astro 7 binds [::1] only on this
// box, wrangler binds 127.0.0.1, and probing one family reports the other down.
function probe(port) {
  return new Promise((resolve) => {
    let open = false;
    let pending = 2;
    const finish = () => {
      if (--pending <= 0) resolve(open);
    };
    for (const host of ['127.0.0.1', '::1']) {
      const s = net.connect({ host, port });
      s.setTimeout(700);
      const end = (ok) => {
        if (ok) open = true;
        s.destroy();
        finish();
      };
      s.once('connect', () => end(true));
      s.once('error', () => end(false));
      s.once('timeout', () => end(false));
    }
  });
}

// Which https ports tailscaled is actually terminating. This is the difference
// between "running" and "you can reach it from your laptop", and conflating
// the two is what makes a link that goes nowhere.
async function exposedPorts() {
  try {
    const { stdout } = await execFileP('tailscale', ['serve', 'status', '--json']);
    const cfg = JSON.parse(stdout);
    const ports = new Set();
    for (const key of Object.keys(cfg.Web || {})) {
      const p = Number(key.slice(key.lastIndexOf(':') + 1));
      if (Number.isFinite(p)) ports.add(p);
    }
    return ports;
  } catch {
    return new Set();
  }
}

async function snapshot() {
  const ports = await exposedPorts();
  const services = await Promise.all(
    SERVICES.map(async (s) => {
      const up = await probe(s.port);
      const exposed = ports.has(PUBLIC(s.port));
      return {
        ...s,
        kind: 'service',
        up,
        exposed,
        state: !up ? 'stopped' : exposed ? 'ready' : 'unexposed',
        url: `https://${HOST}:${PUBLIC(s.port)}/`,
        short: `:${PUBLIC(s.port)}`,
        start: `systemctl --user start ${s.unit}`,
        expose: `tailscale serve --bg --https=${PUBLIC(s.port)} http://localhost:${PROXY(s.port)}`,
      };
    })
  );
  const views = VIEWS.map((v) => {
    const on = services.find((r) => r.id === v.dependsOn);
    return {
      ...v,
      kind: 'view',
      up: Boolean(on?.up),
      state: on?.up ? 'ready' : 'stopped',
      url: v.path,
      short: v.path,
      requires: on?.name ?? v.dependsOn,
    };
  });
  return { services, views };
}

const esc = (s) =>
  String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]);

// Every row is an <a>, with the href present only when it leads somewhere. An
// <a> without href is inert and takes no hover, so the state can change without
// the tag changing -- which is what lets the 5-second refresh repaint in place
// instead of reloading the whole page and throwing away the scroll position.
//
// For the same reason all three notes are rendered up front and CSS shows the
// one matching the row's state class. The refresh then never has to build
// HTML, and there is no second copy of this markup living in a <script>.
function row(s) {
  const href = s.state === 'ready' ? ` href="${esc(s.url)}"` : '';
  const detail = s.detail ? ` <span class="detail">${esc(s.detail)}</span>` : '';
  const notes =
    s.kind === 'view'
      ? `<p class="note stopped">Needs ${esc(s.requires)} running.</p>`
      : `<p class="note unexposed">On anchor:<code>${esc(s.expose)}</code></p>
        <p class="note stopped">On anchor:<code>${esc(s.start)}</code></p>`;
  return `<a class="row ${s.state}" id="card-${esc(s.id)}" data-id="${esc(s.id)}"${href}>
        <span class="dot" aria-hidden="true"></span>
        <span class="name">${esc(s.name)}</span>
        <span class="what">${esc(s.blurb)}${detail}
          <span class="state">
            <span class="s ready">Ready</span>
            <span class="s unexposed">Running, not shared</span>
            <span class="s stopped">Not running</span>
          </span>
          ${notes}
        </span>
        <span class="where">${esc(s.short)}</span>
      </a>`;
}

function section(group, rows) {
  return `<section id="${esc(group.id)}" class="group" data-group="${esc(group.id)}">
      <div class="group-head">
        <h2>${esc(group.name)}</h2>
        <p>${esc(group.blurb)}</p>
      </div>
      <div class="rows">
        ${rows.map(row).join('\n        ')}
      </div>
    </section>`;
}

// The counts are rendered here as well as patched by the refresh. A badge that
// is blank until the first fetch lands reads as a broken badge, and on a page
// whose whole job is to say what is up, blank is the wrong first impression.
function nav(groups, rows) {
  return groups
    .map((g) => {
      const mine = rows.filter((r) => r.group === g.id);
      const ready = mine.filter((r) => r.state === 'ready').length;
      return `<a class="nav-link" href="#${esc(g.id)}" data-nav="${esc(g.id)}">${esc(g.name)}<span class="count" data-count="${esc(g.id)}">${ready}/${mine.length}</span></a>`;
    })
    .join('\n      ');
}

const SLATE = `
  :root {
    color-scheme: light dark;
    --bg: #f1f5f9;          /* slate-100 */
    --raise: #f8fafc;       /* slate-50  */
    --card: #ffffff;
    --ink: #0f172a;         /* slate-900 */
    --ink-soft: #334155;    /* slate-700 */
    --muted: #64748b;       /* slate-500 */
    --line: #cbd5e1;        /* slate-300 */
    --line-soft: #e2e8f0;   /* slate-200 */
    --ready: #15803d;
    --warn: #b45309;
    --off: #94a3b8;         /* slate-400 */
    --accent: #0369a1;
    --bar: rgba(248, 250, 252, .88);
    --hover: #f8fafc;
    --chip: #e2e8f0;
  }
  @media (prefers-color-scheme: dark) {
    :root {
      --bg: #0f172a;        /* slate-900 */
      --raise: #1e293b;     /* slate-800 */
      --card: #1e293b;
      --ink: #e2e8f0;       /* slate-200 */
      --ink-soft: #cbd5e1;  /* slate-300 */
      --muted: #94a3b8;     /* slate-400 */
      --line: #334155;      /* slate-700 */
      --line-soft: #1e293b;
      --ready: #4ade80;
      --warn: #fbbf24;
      --off: #64748b;       /* slate-500 */
      --accent: #7dd3fc;
      --bar: rgba(15, 23, 42, .88);
      --hover: #243044;
      --chip: #334155;
    }
  }`;

function page(services, views) {
  const rows = [...services, ...views];
  const byGroup = (id) => rows.filter((r) => r.group === id);
  const groups = GROUPS.filter((g) => byGroup(g.id).length);
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>anchor</title>
<style>
${SLATE}
  * { box-sizing: border-box; }
  html { scroll-behavior: smooth; scroll-padding-top: 4.5rem; }
  body {
    margin: 0; background: var(--bg); color: var(--ink);
    font: 14px/1.5 ui-sans-serif, system-ui, -apple-system, "Segoe UI", sans-serif;
  }
  main { max-width: 72rem; margin: 0 auto; padding: 0 1.5rem 2.5rem; }

  .bar {
    position: sticky; top: 0; z-index: 5;
    background: var(--bar); backdrop-filter: blur(8px);
    border-bottom: 1px solid var(--line-soft);
  }
  .bar-inner {
    max-width: 72rem; margin: 0 auto; padding: .55rem 1.5rem;
    display: flex; align-items: center; gap: 1.3rem; flex-wrap: wrap;
  }
  .brand { font-weight: 650; letter-spacing: -.01em; color: var(--ink); text-decoration: none; }
  nav { display: flex; gap: 1.05rem; flex-wrap: wrap; align-items: center; }
  .nav-link {
    display: inline-flex; align-items: baseline; gap: .38rem;
    color: var(--muted); text-decoration: none; font-size: .84rem;
  }
  .nav-link:hover { color: var(--ink); }
  .count {
    font: 11px/1 ui-monospace, SFMono-Regular, Menlo, monospace;
    padding: .2rem .34rem; border-radius: 5px;
    background: var(--chip); color: var(--ink-soft);
  }
  .bar .raw { margin-left: auto; font-size: .8rem; color: var(--muted); text-decoration: none; }
  .bar .raw:hover { color: var(--accent); }

  header { padding: 1.7rem 0 .2rem; }
  h1 { margin: 0 0 .25rem; font-size: 1.4rem; letter-spacing: -.02em; }
  header p { margin: 0; color: var(--muted); font-size: .87rem; }

  /* Heading on the left, its rows on the right: one band per category, so
     eight links are eight lines rather than eight boxes. */
  .group {
    display: grid; grid-template-columns: 12.5rem 1fr; gap: 0 1.75rem;
    padding: 1.15rem 0; border-top: 1px solid var(--line-soft);
  }
  .group:first-of-type { border-top: 0; }
  .group-head h2 { margin: 0 0 .12rem; font-size: .92rem; font-weight: 650; letter-spacing: -.01em; }
  .group-head p { margin: 0; color: var(--muted); font-size: .78rem; }
  #other { border-top: 2px solid var(--line); margin-top: .5rem; }
  @media (max-width: 52rem) {
    .group { grid-template-columns: 1fr; gap: .6rem; }
  }

  .rows { display: flex; flex-direction: column; }
  .row {
    display: grid; grid-template-columns: .55rem 9.5rem 1fr auto;
    align-items: baseline; gap: 0 .75rem;
    padding: .42rem .6rem; margin: 0 -.6rem; border-radius: 7px;
    text-decoration: none; color: inherit;
  }
  .row[href]:hover { background: var(--hover); }
  .row { position: relative; }
  .dot {
    width: .5rem; height: .5rem; border-radius: 50%;
    background: var(--off); transform: translateY(-.1rem);
  }
  .row.ready .dot { background: var(--ready); }
  .row.unexposed .dot { background: var(--warn); }
  .name { font-weight: 600; }
  .row[href]:hover .name { color: var(--accent); }
  .what { color: var(--muted); font-size: .86rem; max-width: 74ch; }
  .detail { color: var(--off); }
  .where {
    font: 12px/1 ui-monospace, SFMono-Regular, Menlo, monospace;
    color: var(--off); white-space: nowrap;
  }
  .row.ready .where { color: var(--accent); }

  /* One note and one state word per row; CSS picks the pair that matches the
     state class, so the refresh only has to swap that class. A ready row says
     so with its dot and its link, and keeps the word for a screen reader. */
  .state .s, .note { display: none; }
  .state { display: block; font-size: .8rem; font-weight: 600; margin-top: .1rem; }
  .row.ready .state {
    position: absolute; width: 1px; height: 1px; overflow: hidden; clip-path: inset(50%);
  }
  .row.unexposed .state { color: var(--warn); }
  .row.stopped .state { color: var(--off); }
  .row.ready .state .s.ready,
  .row.unexposed .state .s.unexposed,
  .row.stopped .state .s.stopped { display: inline; }
  .row.unexposed .note.unexposed,
  .row.stopped .note.stopped { display: block; }
  .note { margin: .2rem 0 .35rem; font-size: .8rem; color: var(--muted); }
  code {
    display: inline-block; margin-top: .2rem; padding: .18rem .4rem; border-radius: 5px;
    background: var(--raise); border: 1px solid var(--line-soft);
    font: 12px/1.45 ui-monospace, SFMono-Regular, Menlo, monospace;
    white-space: pre-wrap; word-break: break-all; color: var(--ink-soft);
  }
  footer { margin-top: 1.4rem; color: var(--off); font-size: .78rem; }
</style>
</head>
<body>
<div class="bar">
  <div class="bar-inner">
    <a class="brand" href="#top">anchor</a>
    <nav>
      ${nav(groups, rows)}
    </nav>
    <a class="raw" href="/status.json">Raw status</a>
  </div>
</div>
<main id="top">
  <header>
    <h1>anchor</h1>
    <p>Everything running on the Linux box, reachable from any device signed in to Tailscale. Nothing here is open to the internet.</p>
  </header>
  ${groups.map((g) => section(g, byGroup(g.id))).join('\n  ')}
  <footer>Checked <span id="stamp">${new Date().toLocaleTimeString('en-GB')}</span>, and every 5 seconds after.</footer>
</main>
<script>
  // Repaint in place rather than reloading: a reload every 5 seconds throws
  // away the scroll position, which on a page you are reading is the one thing
  // you were holding on to.
  const paint = (r) => {
    const el = document.getElementById('card-' + r.id);
    if (!el) return;
    el.className = 'row ' + r.state;
    if (r.state === 'ready') el.setAttribute('href', r.url);
    else el.removeAttribute('href');
  };
  const counts = (rows) => {
    for (const link of document.querySelectorAll('[data-count]')) {
      const g = link.dataset.count;
      const mine = rows.filter((r) => r.group === g);
      link.textContent = mine.filter((r) => r.state === 'ready').length + '/' + mine.length;
    }
  };
  async function tick() {
    try {
      const res = await fetch('/status.json', { cache: 'no-store' });
      const { services, views } = await res.json();
      const rows = [...services, ...views];
      rows.forEach(paint);
      counts(rows);
      document.getElementById('stamp').textContent =
        new Date().toLocaleTimeString('en-GB');
    } catch {
      /* the hub itself is down; the page stays as it was rather than blanking */
    }
  }
  tick();
  setInterval(tick, 5000);
</script>
</body>
</html>`;
}

// Redoc renders the spec this page proxies. The spec is served from THIS
// origin rather than from the Worker's own port, so the browser never makes a
// cross-origin request and the Worker's CORS allowlist is irrelevant.
function docsPage() {
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Cloud API reference</title>
<style>
${SLATE}
  body { margin: 0; background: var(--bg); }
  .bar {
    display: flex; align-items: center; gap: .75rem;
    padding: .6rem 1rem; border-bottom: 1px solid var(--line-soft); background: var(--raise);
    font: 14px/1.4 ui-sans-serif, system-ui, -apple-system, sans-serif;
  }
  .bar a { color: var(--accent); text-decoration: none; }
  .bar a:hover { text-decoration: underline; }
  .bar span { color: var(--muted); }
  #redoc { background: #fff; }
</style>
</head>
<body>
<div class="bar">
  <a href="/">&larr; anchor</a>
  <span>Generated from the schemas the Cloud API on this box is serving right now.</span>
  <a href="/openapi.json">Raw spec</a>
</div>
<div id="redoc"></div>
<script src="https://cdn.jsdelivr.net/npm/redoc@2.5.0/bundles/redoc.standalone.js"></script>
<script>
  Redoc.init('/openapi.json', { hideDownloadButton: false, expandResponses: '200,201' },
    document.getElementById('redoc'));
</script>
</body>
</html>`;
}

// One Host-rewriting proxy per service. It stays up whether or not the service
// behind it is, so a request that arrives early gets a readable message rather
// than a bare connection reset from tailscaled.
function startProxy(svc) {
  // `localhost` rather than a literal address, so Node tries both loopback
  // families. The servers here disagree about which one they bind -- Astro and
  // vite take [::1], wrangler takes 127.0.0.1 -- and pinning either one here
  // means half of them answer 502.
  const to = { host: 'localhost', port: svc.port, autoSelectFamily: true };
  // Vite refuses an unknown Host, so it is rewritten by default. Services that
  // validate the Origin they were reached on set hostRewrite: false instead.
  const rewrite = (req) =>
    svc.hostRewrite === false ? req.headers : { ...req.headers, host: `localhost:${svc.port}` };

  const srv = http.createServer((req, res) => {
    const up = http.request(
      { ...to, path: req.url, method: req.method, headers: rewrite(req) },
      (r) => {
        res.writeHead(r.statusCode || 502, r.headers);
        r.pipe(res);
      }
    );
    up.on('error', () => {
      if (!res.headersSent) res.writeHead(502, { 'content-type': 'text/plain; charset=utf-8' });
      res.end(`anchor-hub: ${svc.name} is not running on port ${svc.port}.`);
    });
    req.pipe(up);
  });

  // Vite's hot reload is a websocket; without this the page loads and then
  // reconnects forever.
  srv.on('upgrade', (req, socket, head) => {
    const up = http.request({ ...to, path: req.url, method: req.method, headers: rewrite(req) });
    up.on('upgrade', (r, upSocket, upHead) => {
      const lines = Object.entries(r.headers).map(([k, v]) => `${k}: ${v}`);
      socket.write(`HTTP/1.1 101 Switching Protocols\r\n${lines.join('\r\n')}\r\n\r\n`);
      if (upHead && upHead.length) upSocket.unshift(upHead);
      upSocket.pipe(socket);
      socket.pipe(upSocket);
      upSocket.on('error', () => socket.destroy());
      socket.on('error', () => upSocket.destroy());
    });
    up.on('error', () => socket.destroy());
    if (head && head.length) up.write(head);
    up.end();
  });

  srv.on('error', (e) => console.error(`proxy for ${svc.id} on ${PROXY(svc.port)}: ${e.message}`));
  srv.listen(PROXY(svc.port), '127.0.0.1', () =>
    console.log(`  ${svc.id}: ${PROXY(svc.port)} -> ${svc.port}`)
  );
}

for (const svc of SERVICES) startProxy(svc);

http
  .createServer(async (req, res) => {
    const url = req.url || '/';

    if (url.startsWith('/api-docs')) {
      res.writeHead(200, { 'content-type': 'text/html; charset=utf-8' });
      res.end(docsPage());
      return;
    }

    // Same-origin copy of the Worker's own generated spec. Proxied rather than
    // linked so the browser makes no cross-origin request for it.
    if (url.startsWith('/openapi.json')) {
      const api = SERVICES.find((x) => x.id === 'api');
      const up = http.request(
        { host: 'localhost', port: api.port, path: '/openapi.json', method: 'GET' },
        (r) => {
          res.writeHead(r.statusCode || 502, { 'content-type': 'application/json' });
          r.pipe(res);
        }
      );
      up.on('error', () => {
        res.writeHead(502, { 'content-type': 'application/json' });
        res.end(JSON.stringify({ error: `Cloud API is not running on port ${api.port}` }));
      });
      up.end();
      return;
    }

    const { services, views } = await snapshot();
    if (url.startsWith('/status.json')) {
      res.writeHead(200, { 'content-type': 'application/json' });
      res.end(JSON.stringify({ groups: GROUPS, services, views }, null, 2));
      return;
    }
    res.writeHead(200, { 'content-type': 'text/html; charset=utf-8' });
    res.end(page(services, views));
  })
  .listen(PORT, '127.0.0.1', () => {
    console.log(`anchor-hub on http://127.0.0.1:${PORT}/ for ${HOST}`);
  });

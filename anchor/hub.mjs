// anchor-hub — the front door for dev servers on this box, served over
// Tailscale so no port numbers have to be remembered. Each service is exposed
// by `tailscale serve` on its OWN https port, same number as the local one;
// this page sits on 443 and links to them.
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
const ROOT = process.env.ANCHOR_HUB_ROOT || `${process.env.HOME}/code/diagrammo`;

// Adding a service is one row here plus one `tailscale serve` line; the
// runbook in the ecosystem docs has the whole recipe.
const SERVICES = [
  {
    id: 'docs',
    name: 'Ecosystem docs',
    blurb: 'How the app, Workers and vendors fit together',
    port: 4321,
    dir: 'diagrammo-ecosystem-docs',
    cmd: 'pnpm dev',
    vite: true,
  },
  {
    id: 'site',
    name: 'Marketing site',
    blurb: 'The public diagrammo.app front page',
    port: 4330,
    dir: 'diagrammo_app_site',
    cmd: 'pnpm dev',
    vite: true,
  },
  {
    id: 'console',
    name: 'Online console',
    blurb: 'Cloud health and the issue board. Sign in to see anything: the data routes need a session.',
    port: 5190,
    dir: 'online-console',
    cmd: 'pnpm dev',
    vite: true,
  },
  {
    id: 'api',
    name: 'Cloud API',
    blurb: 'The one Cloudflare Worker, run here by wrangler',
    port: 8787,
    dir: 'diagrammo-cloud/packages/cloud-api',
    cmd: 'pnpm dev',
    vite: false,
  },
  {
    id: 'mcp',
    name: 'MCP studio',
    blurb: 'Inspector for the dgmo MCP server. Its gallery is currently empty - every block fails to render.',
    port: 4347,
    dir: 'dgmo-mcp',
    cmd: 'pnpm studio',
    vite: false,
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
  return Promise.all(
    SERVICES.map(async (s) => {
      const up = await probe(s.port);
      const exposed = ports.has(PUBLIC(s.port));
      return {
        ...s,
        up,
        exposed,
        state: !up ? 'stopped' : exposed ? 'ready' : 'unexposed',
        url: `https://${HOST}:${PUBLIC(s.port)}/`,
        start: `cd ~/code/diagrammo/${s.dir} && ${s.cmd}`,
        expose: `tailscale serve --bg --https=${PUBLIC(s.port)} http://localhost:${PROXY(s.port)}`,
      };
    })
  );
}

const esc = (s) =>
  String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]);

function card(s) {
  const link = s.state === 'ready';
  const tag = link ? 'a' : 'div';
  const href = link ? ` href="${esc(s.url)}"` : '';
  const note =
    s.state === 'ready'
      ? `<p class="url">${esc(s.url)}</p>`
      : s.state === 'unexposed'
        ? `<p class="hint">Running here, but not reachable from your laptop yet. On anchor:<code>${esc(s.expose)}</code></p>`
        : `<p class="hint">Not running. On anchor:<code>${esc(s.start)}</code></p>`;
  return `<${tag} class="card ${s.state}"${href}>
      <span class="dot" aria-hidden="true"></span>
      <h2>${esc(s.name)}</h2>
      <p class="blurb">${esc(s.blurb)}</p>
      <p class="state">${s.state === 'ready' ? 'Ready' : s.state === 'unexposed' ? 'Running, not shared' : 'Not running'}</p>
      ${note}
    </${tag}>`;
}

function page(rows) {
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>anchor</title>
<style>
  :root {
    color-scheme: light dark;
    --bg: #f6f6f4; --card: #fff; --ink: #1c1c1a; --muted: #6b6b66;
    --line: #e2e2dd; --ready: #2f8f4e; --warn: #c9a227; --off: #b3b3ac;
    --accent: #3b6ea5;
  }
  @media (prefers-color-scheme: dark) {
    :root {
      --bg: #17171a; --card: #202024; --ink: #ececea; --muted: #9a9a95;
      --line: #303036; --ready: #5fbd7e; --warn: #d9b840; --off: #55555c;
      --accent: #7fa9d8;
    }
  }
  * { box-sizing: border-box; }
  body {
    margin: 0; padding: 3rem 1.5rem 4rem; background: var(--bg); color: var(--ink);
    font: 15px/1.55 ui-sans-serif, system-ui, -apple-system, "Segoe UI", sans-serif;
  }
  main { max-width: 62rem; margin: 0 auto; }
  header { margin-bottom: 2rem; }
  h1 { margin: 0 0 .35rem; font-size: 1.7rem; letter-spacing: -.02em; }
  header p { margin: 0; color: var(--muted); }
  .grid { display: grid; gap: 1rem; grid-template-columns: repeat(auto-fill, minmax(19rem, 1fr)); }
  .card {
    position: relative; display: block; padding: 1.15rem 1.25rem 1.25rem 2.3rem;
    background: var(--card); border: 1px solid var(--line); border-radius: 12px;
    text-decoration: none; color: inherit;
  }
  a.card:hover { border-color: var(--accent); transform: translateY(-1px); }
  a.card { transition: border-color .12s, transform .12s; }
  .dot {
    position: absolute; left: 1.1rem; top: 1.5rem; width: .55rem; height: .55rem;
    border-radius: 50%; background: var(--off);
  }
  .ready .dot { background: var(--ready); }
  .unexposed .dot { background: var(--warn); }
  h2 { margin: 0 0 .15rem; font-size: 1.02rem; font-weight: 600; }
  .blurb { margin: 0 0 .6rem; color: var(--muted); font-size: .9rem; }
  .state { margin: 0; font-size: .82rem; font-weight: 600; color: var(--off); }
  .ready .state { color: var(--ready); }
  .unexposed .state { color: var(--warn); }
  .url { margin: .3rem 0 0; font-size: .82rem; color: var(--accent); word-break: break-all; }
  .hint { margin: .45rem 0 0; font-size: .82rem; color: var(--muted); }
  code {
    display: block; margin-top: .35rem; padding: .4rem .55rem; border-radius: 6px;
    background: var(--bg); border: 1px solid var(--line);
    font: 12px/1.5 ui-monospace, SFMono-Regular, Menlo, monospace;
    white-space: pre-wrap; word-break: break-all; color: var(--ink);
  }
  footer { margin-top: 2.5rem; color: var(--muted); font-size: .82rem; }
</style>
</head>
<body>
<main>
  <header>
    <h1>anchor</h1>
    <p>Dev servers on the Linux box, reachable anywhere you are signed in to Tailscale.</p>
  </header>
  <div class="grid">
    ${rows.map(card).join('\n    ')}
  </div>
  <footer>Refreshes every 5 seconds. Checked ${new Date().toLocaleTimeString('en-GB')}.</footer>
</main>
<script>
  setTimeout(() => location.reload(), 5000);
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
  const rewrite = (req) => ({ ...req.headers, host: `localhost:${svc.port}` });

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
    const rows = await snapshot();
    if (req.url && req.url.startsWith('/status.json')) {
      res.writeHead(200, { 'content-type': 'application/json' });
      res.end(JSON.stringify(rows, null, 2));
      return;
    }
    res.writeHead(200, { 'content-type': 'text/html; charset=utf-8' });
    res.end(page(rows));
  })
  .listen(PORT, '127.0.0.1', () => {
    console.log(`anchor-hub on http://127.0.0.1:${PORT}/ for ${HOST}`);
  });

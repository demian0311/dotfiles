// anchor-hub — the front door for the servers on this box, plus the consoles
// and production addresses you would otherwise keep in bookmarks. Served over
// Tailscale so no port numbers have to be remembered: each local service is
// exposed by `tailscale serve` on its own https port, and this page sits on
// 443, groups everything, and links to what is reachable.
//
// No dependencies on purpose: a hub that needs `pnpm install` to come back
// after a reboot is a hub that is down when you need it. That extends to the
// icons -- they are hand-written SVG primitives below rather than an icon
// package, so nothing here can break on an install.
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

// Icons, as SVG primitives rather than path data copied from an icon set.
// Authoring them from circles, rects and short paths means none of it is
// remembered wrongly, and the whole set costs nothing to serve.
const ICONS = {
  // a pencil — you write here
  editor: '<path d="M4 20h16"/><path d="M14.6 4.4a2.1 2.1 0 0 1 3 3L8.2 16.8 4 18l1.2-4.2Z"/>',
  // a globe — the public web
  globe:
    '<circle cx="12" cy="12" r="8.5"/><path d="M3.5 12h17"/><path d="M12 3.5a13 13 0 0 1 0 17a13 13 0 0 1 0-17Z"/>',
  // stacked racks — a server
  server:
    '<rect x="3" y="4.5" width="18" height="6.5" rx="2"/><rect x="3" y="13" width="18" height="6.5" rx="2"/><path d="M6.8 7.75h.01M6.8 16.25h.01"/>',
  // a trace — something being watched
  pulse: '<path d="M3 12h3.5L9 5.5 13 18.5l2.4-6.5H21"/>',
  // an open book
  book: '<path d="M12 6.6C10.4 5 8.4 4.4 4.4 4.4v13c4 0 6 .6 7.6 2.2 1.6-1.6 3.6-2.2 7.6-2.2v-13c-4 0-6 .6-7.6 2.2Z"/><path d="M12 6.6v13"/>',
  // four panes — a gallery
  grid:
    '<rect x="3.5" y="3.5" width="7" height="7" rx="1.6"/><rect x="13.5" y="3.5" width="7" height="7" rx="1.6"/><rect x="3.5" y="13.5" width="7" height="7" rx="1.6"/><rect x="13.5" y="13.5" width="7" height="7" rx="1.6"/>',
  // braces — a generated schema
  braces:
    '<path d="M8.5 3.5H7.5a2 2 0 0 0-2 2v3.2a2 2 0 0 1-2 2 2 2 0 0 1 2 2v3.6a2 2 0 0 0 2 2h1"/><path d="M15.5 3.5h1a2 2 0 0 1 2 2v3.2a2 2 0 0 0 2 2 2 2 0 0 0-2 2v3.6a2 2 0 0 1-2 2h-1"/>',
  // a machine with an antenna — an agent
  bot: '<rect x="3.5" y="8" width="17" height="12" rx="3.5"/><path d="M12 8V4.6"/><circle cx="12" cy="3.4" r="1.3" fill="currentColor" stroke="none"/><path d="M8.8 13.5h.01M15.2 13.5h.01"/><path d="M9.6 16.8h4.8"/>',
  // nine dots — Tailscale's own mark
  tailscale:
    '<g fill="currentColor" stroke="none"><circle cx="6" cy="6" r="1.7" opacity=".45"/><circle cx="12" cy="6" r="1.7"/><circle cx="18" cy="6" r="1.7" opacity=".45"/><circle cx="6" cy="12" r="1.7"/><circle cx="12" cy="12" r="1.7"/><circle cx="18" cy="12" r="1.7"/><circle cx="6" cy="18" r="1.7" opacity=".45"/><circle cx="12" cy="18" r="1.7"/><circle cx="18" cy="18" r="1.7" opacity=".45"/></g>',
  // a cloud
  cloud: '<path d="M6.8 18.5h10a3.6 3.6 0 0 0 .4-7.2 5.6 5.6 0 0 0-10.7-1.1A3.9 3.9 0 0 0 6.8 18.5Z"/>',
  // bars — product analytics
  bars: '<path d="M3.5 20h17"/><path d="M6.5 20v-6"/><path d="M12 20V4.5"/><path d="M17.5 20v-9"/>',
  // a dot in a ring — an open issue
  issue: '<circle cx="12" cy="12" r="8.5"/><circle cx="12" cy="12" r="2.3" fill="currentColor" stroke="none"/>',
};

// The sections of the page, in order. `blurb` says what a stranger needs to
// know before reading the rows under it -- above all which of these are
// Diagrammo and which are simply other things that happen to run here.
//
// `tint` is the group's colour, carried by every icon in it and by its
// heading. It names a hue slot in dgmo's slate palette. It is identity, NOT
// status: the pip on each icon is what says whether a thing is up, and no tint
// is ever green, yellow or gray, so the two can never be read for each other.
//
// `probed` says whether the rows in it are servers on this box. The last two
// groups are addresses elsewhere on the internet -- nothing here can know
// whether they are up, and pretending otherwise with a dot would be a lie.
const GROUPS = [
  {
    id: 'apps',
    name: 'Diagrammo apps',
    blurb: 'What a person opens: the editor, and the page that sells it.',
    tint: 'blue',
    probed: true,
  },
  {
    id: 'cloud',
    name: 'Diagrammo Cloud',
    blurb:
      'The Worker the app talks to, and the console that watches it. Its database is throwaway and lives on this box — nothing here is production data.',
    tint: 'purple',
    probed: true,
  },
  {
    id: 'reference',
    name: 'Reference',
    blurb: 'How the system fits together, and what it exposes.',
    tint: 'teal',
    probed: true,
  },
  {
    id: 'other',
    name: 'Other projects',
    blurb:
      'Not Diagrammo. Separate projects that happen to run on this machine — one of them can drive Diagrammo without being part of it.',
    tint: 'orange',
    probed: true,
  },
  {
    id: 'production',
    name: 'Production',
    blurb: 'The real thing, on the real internet, with real customer data behind it.',
    tint: 'red',
    probed: false,
  },
  {
    id: 'consoles',
    name: 'Consoles',
    blurb: 'The vendor dashboards and the tracker. Each one wants you signed in.',
    tint: 'cyan',
    probed: false,
  },
];

// Adding a service is one row here plus one `tailscale serve` line; the
// runbook in the ecosystem docs has the whole recipe.
//
// `unit` is the systemd user unit that actually runs it, and it is what the
// row prints when the thing is stopped. Everything here is started by systemd
// rather than by hand, so a `cd … && pnpm dev` hint would be a command nobody
// runs and would leave an unsupervised second copy behind if anybody did.
const SERVICES = [
  {
    id: 'editor',
    group: 'apps',
    icon: 'editor',
    name: 'Web editor',
    blurb: 'The diagram editor in a browser — the same app online.diagrammo.app serves.',
    detail:
      'Built against the Cloud API on this box, so its diagrams are throwaway. Rebuilding it is by hand — see the README.',
    port: 5173,
    unit: 'anchor-editor',
  },
  {
    id: 'site',
    group: 'apps',
    icon: 'globe',
    name: 'Marketing site',
    blurb: 'The public diagrammo.app front page.',
    port: 4330,
    unit: 'anchor-site',
  },
  {
    id: 'api',
    group: 'cloud',
    icon: 'server',
    name: 'Cloud API',
    blurb: 'The one Cloudflare Worker, run here by wrangler against a local database.',
    detail: 'Sign-in mail is logged rather than sent — read the link out of journalctl --user -u anchor-api.',
    port: 8787,
    unit: 'anchor-api',
  },
  {
    id: 'console',
    group: 'cloud',
    icon: 'pulse',
    name: 'Online console',
    blurb: 'Cloud health and the issue board.',
    detail: 'Sign in to see anything — every data route needs a session.',
    port: 5190,
    unit: 'anchor-console',
  },
  {
    id: 'docs',
    group: 'reference',
    icon: 'book',
    name: 'Ecosystem docs',
    blurb: 'How the app, the Workers and the vendors fit together.',
    port: 4321,
    unit: 'anchor-docs',
  },
  {
    id: 'mcp',
    group: 'reference',
    icon: 'grid',
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
    icon: 'bot',
    name: 'OpenClaw',
    blurb: 'A personal agent gateway and its control page, on the Claude CLI backend.',
    detail: 'Its own repo, with no Diagrammo code in it. It can drive Diagrammo the way it can drive anything else.',
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
    icon: 'braces',
    name: 'Cloud API reference',
    blurb: 'Every endpoint, generated from the schemas the Worker on this box is serving.',
    path: '/api-docs',
    dependsOn: 'api',
  },
];

// Addresses that are not on this box. They get no dot, because nothing here
// can honestly say whether they are up, and they open in a new tab, because
// leaving the hub to reach one is a departure rather than a navigation.
//
// 🔴 Every id below was checked against a source in the repo rather than
// recalled: the Cloudflare account and the PostHog project are the ones the
// ecosystem docs record (infrastructure/vendors/cloudflare.md and
// .../posthog.md), and each address was fetched on 2026-09-04 -- a 302 to a
// login page is the right answer for a console, and a 403 from curl is
// Cloudflare declining a non-browser, not a wrong URL.
const LINKS = [
  {
    id: 'prod-editor',
    group: 'production',
    icon: 'editor',
    name: 'Web editor',
    host: 'online.diagrammo.app',
    url: 'https://online.diagrammo.app',
  },
  {
    id: 'prod-site',
    group: 'production',
    icon: 'globe',
    name: 'Marketing site',
    host: 'diagrammo.app',
    url: 'https://diagrammo.app',
  },
  {
    id: 'prod-api',
    group: 'production',
    icon: 'server',
    name: 'Cloud API',
    // Its root has no route and answers 404, which reads as an outage. /health
    // is the endpoint that says something true about the Worker.
    host: 'api.diagrammo.app/health',
    url: 'https://api.diagrammo.app/health',
  },
  {
    id: 'prod-docs',
    group: 'production',
    icon: 'book',
    name: 'Ecosystem docs',
    host: 'docs.diagrammo.app',
    url: 'https://docs.diagrammo.app',
  },
  {
    id: 'tailscale',
    group: 'consoles',
    icon: 'tailscale',
    name: 'Tailscale',
    host: 'login.tailscale.com',
    url: 'https://login.tailscale.com/admin/machines',
  },
  {
    id: 'cloudflare',
    group: 'consoles',
    icon: 'cloud',
    name: 'Cloudflare',
    host: 'dash.cloudflare.com',
    url: 'https://dash.cloudflare.com/e073da7b4a152b6c8feea8ee1d7c6eb9',
  },
  {
    id: 'posthog',
    group: 'consoles',
    icon: 'bars',
    name: 'PostHog',
    host: 'us.posthog.com · project 351484',
    url: 'https://us.posthog.com/project/351484',
  },
  {
    id: 'tracker',
    group: 'consoles',
    icon: 'issue',
    name: 'Issues',
    host: 'github.com/diagrammo/diagrammo',
    url: 'https://github.com/diagrammo/diagrammo/issues',
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
  const links = LINKS.map((l) => ({ ...l, kind: 'link', state: 'link' }));
  return { services, views, links };
}

const esc = (s) =>
  String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]);

// The icon plus, for anything on this box, a status pip riding its corner.
// Putting the pip ON the icon rather than beside it keeps one object per row
// where there would otherwise be two competing for the same glance.
function mark(id, withPip) {
  return `<span class="mark">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"
               stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${ICONS[id] ?? ''}</svg>
          ${withPip ? '<span class="pip" aria-hidden="true"></span>' : ''}
        </span>`;
}

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
        ${mark(s.icon, true)}
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

// An address elsewhere is a tile rather than a row: there is no status to
// report and no command to print, so all it owes you is what it is and where
// it goes.
function tile(l) {
  return `<a class="tile" id="card-${esc(l.id)}" href="${esc(l.url)}" target="_blank" rel="noreferrer">
        ${mark(l.icon, false)}
        <span class="tile-body">
          <span class="name">${esc(l.name)}</span>
          <span class="host">${esc(l.host)}</span>
        </span>
      </a>`;
}

function section(group, rows) {
  const body = group.probed
    ? `<div class="rows">
        ${rows.map(row).join('\n        ')}
      </div>`
    : `<div class="tiles">
        ${rows.map(tile).join('\n        ')}
      </div>`;
  return `<section id="${esc(group.id)}" class="group" data-group="${esc(group.id)}"
      style="--tint: var(--t-${esc(group.tint)})">
      <div class="group-head">
        <h2>${esc(group.name)}</h2>
        <p>${esc(group.blurb)}</p>
      </div>
      ${body}
    </section>`;
}

// The counts are rendered here as well as patched by the refresh. A badge that
// is blank until the first fetch lands reads as a broken badge, and on a page
// whose whole job is to say what is up, blank is the wrong first impression.
// A group of external addresses gets a plain total: `4/4` there would claim a
// health check nobody performed.
function nav(groups, rows) {
  return groups
    .map((g) => {
      const mine = rows.filter((r) => r.group === g.id);
      const badge = g.probed
        ? `${mine.filter((r) => r.state === 'ready').length}/${mine.length}`
        : `${mine.length}`;
      return `<a class="nav-link" href="#${esc(g.id)}" data-nav="${esc(g.id)}"
        style="--tint: var(--t-${esc(g.tint)})">${esc(g.name)}<span class="count"
        data-count="${esc(g.id)}" data-probed="${g.probed ? '1' : '0'}">${badge}</span></a>`;
    })
    .join('\n      ');
}

// The palette is dgmo's own `slate` -- `palettes.slate` in @diagrammo/dgmo,
// the one rendered at https://diagrammo.app/slate/. Not Tailwind's slate,
// which is a different set of colours wearing the same name.
//
// 🔴 These hexes are a COPY, and there is no way for them not to be: this file
// has no dependencies on purpose, so it cannot import the palette that the
// marketing site imports at build time. If dgmo's slate ever changes, this is
// the second place to edit. Read the real values rather than adjusting one by
// eye:
//
//   node -e "console.log(require('~/code/diagrammo/dgmo/dist/index.js').palettes.slate)"
//
// The mapping from the palette's roles to this page's variables:
//   page ground = surface · code + chips = overlay · rules = border
//   name = text · blurb = textMuted · detail, host, port = gray / secondary
//   links = primary · ready = green · running-not-shared = yellow
const SLATE = `
  :root {
    color-scheme: light dark;
    --bg: #f3f5f8;          /* surface */
    --raise: #eaeef3;       /* overlay  */
    --card: #ffffff;        /* bg       */
    --ink: #1f2933;         /* text     */
    --muted: #5b6672;       /* textMuted */
    --line: #d4dae1;        /* border   */
    --line-soft: #eaeef3;   /* overlay  */
    --off: #7e8a97;         /* gray — the stopped pip ONLY, never text */
    --ready: #5b9357;       /* green    */
    --warn: #c9a227;        /* yellow   */
    --accent: #3b6ea5;      /* primary  */
    --bar: rgba(243, 245, 248, .88);
    --chip: #eaeef3;
    /* Group identity, from the palette's nine hue slots. 🔴 Never green,
       yellow or gray -- those three are status, and a tint that borrowed one
       could be read as a health claim. */
    --t-blue: #3b6ea5;
    --t-purple: #7d5ba6;
    --t-teal: #3a9188;
    --t-orange: #cc7a33;
    --t-red: #c0504d;
    --t-cyan: #4f96c4;
  }
  @media (prefers-color-scheme: dark) {
    :root {
      --bg: #161b22;        /* bg       */
      --raise: #29323e;     /* overlay  */
      --card: #202833;      /* surface  */
      --ink: #e6eaef;       /* text     */
      --muted: #9aa5b1;     /* textMuted */
      --line: #38424f;      /* border   */
      --line-soft: #29323e; /* overlay  */
      --off: #8593a3;       /* secondary — the stopped pip ONLY */
      --ready: #74b56e;     /* green    */
      --warn: #d9bd5a;      /* yellow   */
      --accent: #5b9bd5;    /* primary  */
      --bar: rgba(22, 27, 34, .88);
      --chip: #29323e;
      --t-blue: #5b9bd5;
      --t-purple: #a585c9;
      --t-teal: #45b3a3;
      --t-orange: #e0975a;
      --t-red: #e07b6e;
      --t-cyan: #62b0d9;
    }
  }`;

function page(services, views, links) {
  const rows = [...services, ...views, ...links];
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
    display: flex; align-items: center; gap: 1.15rem; flex-wrap: wrap;
  }
  .brand { font-weight: 650; letter-spacing: -.01em; color: var(--ink); text-decoration: none; }
  nav { display: flex; gap: .95rem; flex-wrap: wrap; align-items: center; }
  .nav-link {
    display: inline-flex; align-items: baseline; gap: .38rem;
    color: var(--muted); text-decoration: none; font-size: .84rem;
  }
  .nav-link:hover { color: var(--tint); }
  .count {
    font: 11px/1 ui-monospace, SFMono-Regular, Menlo, monospace;
    padding: .2rem .34rem; border-radius: 5px;
    background: color-mix(in srgb, var(--tint) 16%, transparent); color: var(--tint);
  }
  .bar .raw { margin-left: auto; font-size: .8rem; color: var(--muted); text-decoration: none; }
  .bar .raw:hover { color: var(--accent); }

  header { padding: 1.7rem 0 .2rem; }
  h1 { margin: 0 0 .25rem; font-size: 1.4rem; letter-spacing: -.02em; }
  header p { margin: 0; color: var(--muted); font-size: .87rem; }

  /* Heading on the left, its entries on the right: one band per category, so
     eight links are eight lines rather than eight boxes. */
  .group {
    display: grid; grid-template-columns: 12.5rem 1fr; gap: 0 1.75rem;
    padding: 1.15rem 0; border-top: 1px solid var(--line-soft);
  }
  .group:first-of-type { border-top: 0; }
  .group-head h2 {
    margin: 0 0 .12rem; font-size: .92rem; font-weight: 650;
    letter-spacing: -.01em; color: var(--tint);
  }
  .group-head p { margin: 0; color: var(--muted); font-size: .78rem; }
  #other, #production { border-top: 2px solid var(--line); }
  #other { margin-top: .5rem; }
  @media (max-width: 52rem) {
    .group { grid-template-columns: 1fr; gap: .6rem; }
  }

  .mark {
    position: relative; width: 1.65rem; height: 1.65rem; border-radius: 8px;
    display: inline-flex; align-items: center; justify-content: center;
    background: var(--chip);
    background: color-mix(in srgb, var(--tint) 15%, transparent);
    color: var(--tint); flex: none;
  }
  .mark svg { width: 1rem; height: 1rem; }
  .pip {
    position: absolute; right: -3px; bottom: -3px; width: .48rem; height: .48rem;
    border-radius: 50%; background: var(--off); box-shadow: 0 0 0 2px var(--bg);
  }
  .row.ready .pip { background: var(--ready); }
  .row.unexposed .pip { background: var(--warn); }

  .rows { display: flex; flex-direction: column; gap: .1rem; }
  .row {
    position: relative;
    display: grid; grid-template-columns: 1.65rem 9rem 1fr auto;
    align-items: start; gap: 0 .75rem;
    padding: .38rem .6rem; margin: 0 -.6rem; border-radius: 8px;
    text-decoration: none; color: inherit;
  }
  .row[href]:hover { background: color-mix(in srgb, var(--tint) 9%, transparent); }
  .name { font-weight: 600; }  /* text, bold */
  .row[href]:hover .name { color: var(--tint); }
  .what { color: var(--ink); font-size: .86rem; max-width: 74ch; }
  .name, .what, .where { padding-top: .2rem; }
  .detail { color: var(--muted); }
  .where {
    font: 12px/1.5 ui-monospace, SFMono-Regular, Menlo, monospace;
    color: var(--muted); white-space: nowrap;
  }
  .row.ready .where { color: var(--accent); }

  /* One note and one state word per row; CSS picks the pair that matches the
     state class, so the refresh only has to swap that class. A ready row says
     so with its pip and its link, and keeps the word for a screen reader. */
  .state .s, .note { display: none; }
  .state { display: block; font-size: .8rem; font-weight: 600; }
  .row.ready .state {
    position: absolute; width: 1px; height: 1px; overflow: hidden; clip-path: inset(50%);
  }
  .row.unexposed .state { color: var(--ink); }
  .row.stopped .state { color: var(--ink); }
  .row.ready .state .s.ready,
  .row.unexposed .state .s.unexposed,
  .row.stopped .state .s.stopped { display: inline; }
  .row.unexposed .note.unexposed,
  .row.stopped .note.stopped { display: block; }
  .note { margin: .1rem 0 .3rem; font-size: .8rem; color: var(--muted); }
  code {
    display: inline-block; margin-top: .2rem; padding: .18rem .4rem; border-radius: 5px;
    background: var(--raise); border: 1px solid var(--line-soft);
    font: 12px/1.45 ui-monospace, SFMono-Regular, Menlo, monospace;
    white-space: pre-wrap; word-break: break-all; color: var(--ink);
  }

  .tiles {
    display: grid; gap: .35rem .75rem;
    grid-template-columns: repeat(auto-fill, minmax(15rem, 1fr));
  }
  .tile {
    display: flex; align-items: center; gap: .65rem;
    padding: .4rem .6rem; margin: 0 -.6rem; border-radius: 8px;
    text-decoration: none; color: inherit; min-width: 0;
  }
  .tile:hover { background: color-mix(in srgb, var(--tint) 9%, transparent); }
  .tile-body { display: flex; flex-direction: column; min-width: 0; }
  .tile:hover .name { color: var(--tint); }
  .tile .name { line-height: 1.35; }
  .host {
    font: 11.5px/1.4 ui-monospace, SFMono-Regular, Menlo, monospace;
    color: var(--muted); overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
  }

  footer { margin-top: 1.4rem; color: var(--muted); font-size: .78rem; }
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
    <p>Everything running on the Linux box, reachable from any device signed in to Tailscale — and the addresses off it that you would otherwise keep in bookmarks.</p>
  </header>
  ${groups.map((g) => section(g, byGroup(g.id))).join('\n  ')}
  <footer>Checked <span id="stamp">${new Date().toLocaleTimeString('en-GB')}</span>, and every 5 seconds after. Nothing on this box is open to the internet.</footer>
</main>
<script>
  // Repaint in place rather than reloading: a reload every 5 seconds throws
  // away the scroll position, which on a page you are reading is the one thing
  // you were holding on to. External addresses are never touched -- they carry
  // no state to repaint.
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
      link.textContent =
        link.dataset.probed === '1'
          ? mine.filter((r) => r.state === 'ready').length + '/' + mine.length
          : String(mine.length);
    }
  };
  async function tick() {
    try {
      const res = await fetch('/status.json', { cache: 'no-store' });
      const { services, views, links } = await res.json();
      [...services, ...views].forEach(paint);
      counts([...services, ...views, ...links]);
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

    const { services, views, links } = await snapshot();
    if (url.startsWith('/status.json')) {
      res.writeHead(200, { 'content-type': 'application/json' });
      res.end(JSON.stringify({ groups: GROUPS, services, views, links }, null, 2));
      return;
    }
    res.writeHead(200, { 'content-type': 'text/html; charset=utf-8' });
    res.end(page(services, views, links));
  })
  .listen(PORT, '127.0.0.1', () => {
    console.log(`anchor-hub on http://127.0.0.1:${PORT}/ for ${HOST}`);
  });

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
//
// Three jobs, one set: the mark on a row, the mark on a section heading, and
// the two realm marks. A glyph is never used for both a row and the heading
// above it -- two identical marks in a column read as a repeat rather than as
// a hierarchy.
const ICONS = {
  // a magnifier — the filter
  search: '<circle cx="11" cy="11" r="6.4"/><path d="m15.9 15.9 4.6 4.6"/>',
  // a box with an arrow leaving it — addresses that are not on this machine
  outbound:
    '<path d="M13.8 4.2h6v6"/><path d="M19.8 4.2 11.2 12.8"/><path d="M18.2 13.8v4.4a2.1 2.1 0 0 1-2.1 2.1H5.7a2.1 2.1 0 0 1-2.1-2.1V7.8a2.1 2.1 0 0 1 2.1-2.1h4.5"/>',
  // an anchor — this page
  anchor:
    '<circle cx="12" cy="4.6" r="2"/><path d="M12 6.6V21"/><path d="M7.6 10.1h8.8"/><path d="M3.8 14.2a8.4 8.4 0 0 0 8.2 6.8 8.4 8.4 0 0 0 8.2-6.8"/>',
  // two nodes and an edge — the Diagrammo realm
  flow: '<rect x="3" y="4" width="8" height="5.4" rx="1.6"/><rect x="13" y="14.6" width="8" height="5.4" rx="1.6"/><path d="M6.4 9.4v4.5a3.4 3.4 0 0 0 3.4 3.4H13"/>',
  // three hooked talons — the OpenClaw realm
  claw: '<path d="M6.2 3.6c-2 4.4-2.2 9.1-.6 13.7a3 3 0 0 0 2.9 2.1"/><path d="M12 3c-1.4 4.6-1.4 9.4 0 14a3 3 0 0 0 2.9 2.1"/><path d="M17.8 3.6c.9 4.5.5 9-1.2 13.3a3 3 0 0 0 2.9 2.1"/>',
  // stacked planes — the apps section
  layers:
    '<path d="M12 3.2 3.6 7.4 12 11.6l8.4-4.2Z"/><path d="M3.6 12.1 12 16.3l8.4-4.2"/><path d="M3.6 16.6 12 20.8l8.4-4.2"/>',
  // a cloud with an upload — the cloud section
  cloudUp:
    '<path d="M7.2 17.6h9.4a3.5 3.5 0 0 0 .4-7 5.5 5.5 0 0 0-10.3-1 3.8 3.8 0 0 0 .5 8Z"/><path d="M12 21.2v-6.6"/><path d="M9.7 16.7 12 14.4l2.3 2.3"/>',
  // a compass — the reference section
  compass: '<circle cx="12" cy="12" r="8.5"/><path d="m15.6 8.4-2.1 5.1-5.1 2.1 2.1-5.1Z"/>',
  // a rocket — the production section
  rocket:
    '<path d="M12 3.2c2.8 2 4.5 5.1 4.5 8.6v4H7.5v-4c0-3.5 1.7-6.6 4.5-8.6Z"/><path d="M7.5 12.3 4.6 15v3.3l2.9-1.6"/><path d="M16.5 12.3 19.4 15v3.3l-2.9-1.6"/><circle cx="12" cy="9.9" r="1.6"/><path d="M10.3 19.2h3.4"/>',
  // two sliders — the consoles section
  dials:
    '<path d="M3.5 7.6h8.2"/><path d="M15.9 7.6h4.6"/><circle cx="13.8" cy="7.6" r="2.1"/><path d="M3.5 16.4h3.6"/><path d="M11.3 16.4h9.2"/><circle cx="9.2" cy="16.4" r="2.1"/>',
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
  // a box — a published package
  package:
    '<path d="M12 3.2 3.9 7.3v9.4L12 20.8l8.1-4.1V7.3Z"/><path d="M3.9 7.3 12 11.4l8.1-4.1"/><path d="M12 11.4v9.4"/>',
  // an envelope — mail we send
  mail: '<rect x="2.8" y="5" width="18.4" height="14" rx="2.4"/><path d="M3.4 6.8 12 12.9l8.6-6.1"/>',
  // a card — money
  card: '<rect x="2.5" y="5" width="19" height="14" rx="2.4"/><path d="M2.5 9.9h19"/><path d="M6.3 15.2h3.6"/>',
  // a key — an OAuth client and its consent screen
  key: '<circle cx="8.2" cy="12" r="3.5"/><path d="M11.7 11.4H21"/><path d="M18.2 11.4v3.1"/><path d="M15.2 11.4v2.3"/>',
  // a rosette — signing certificates and identifiers
  badge:
    '<circle cx="12" cy="9.1" r="5.1"/><path d="M8.7 13.3 7.5 20.6l4.5-2.4 4.5 2.4-1.2-7.3"/>',
  // a window — an app in review
  window:
    '<rect x="3" y="4.6" width="18" height="14.8" rx="2.4"/><path d="M3 9.3h18"/><path d="M6.3 6.95h.01M9 6.95h.01"/>',
};

// The page's outermost cut: the two projects that run on this box, then
// everything that does not. It exists because the older flat list buried "not
// Diagrammo" as one section among six -- a reader scanning headings had to
// notice a word to tell a project boundary from a category boundary.
//
// 🔴 `elsewhere` is not a project, and putting it here is deliberate. The first
// question this page answers is "can I reach it, and is it up", and the honest
// answer for the fourteen addresses off this box is that nothing here can say.
// Filing them by owner instead put four unprobeable addresses in the middle of
// a column of pips that all mean something. OpenClaw has no production and no
// vendor consoles, so the move costs that realm nothing.
//
// A band is a heading, a hairline and a tally -- no fill, no rail. The filled
// band and the tinted rail this replaced on 2026-09-05 were two of the four
// nested devices the page was spending on a hierarchy that is one list of
// twenty-two links.
//
// Adding a third project is a realm here plus `realm:` on its groups.
const REALMS = [
  {
    id: 'diagrammo',
    name: 'Diagrammo',
    glyph: 'flow',
    tint: 'blue',
    blurb: 'The product, on this box, against a throwaway database.',
  },
  {
    id: 'openclaw',
    name: 'OpenClaw',
    glyph: 'claw',
    tint: 'orange',
    blurb: 'A separate project that happens to run on this box. No Diagrammo code in it.',
  },
  {
    id: 'elsewhere',
    name: 'Elsewhere',
    glyph: 'outbound',
    tint: 'cyan',
    blurb: 'Addresses that are not on this machine.',
  },
];

// The sections of the page, in order, each inside a realm. `blurb` is one line
// on purpose: it sits beside the heading rather than under it, so a second
// sentence costs the whole page a row of height.
//
// `glyph` is the section's own mark. It is never the same as any row mark
// beneath it.
//
// `tint` is the section's colour, carried by its glyph, its heading and its
// nav entry. It names a hue slot in dgmo's slate palette. It is identity, NOT
// status: the pip on each row icon is what says whether a thing is up, and no
// tint is ever green, yellow or gray, so the two can never be read for each
// other.
//
// `probed` says whether the rows in it are servers on this box. The sections
// under `elsewhere` are addresses on the internet -- nothing here can know
// whether they are up, and pretending otherwise with a dot would be a lie.
//
// `bare` drops the section heading, for a section whose realm band already
// said everything the heading would have. OpenClaw is one project with one
// address; a band, a heading and a row for it would be three lines of chrome
// on one link.
const GROUPS = [
  {
    id: 'apps',
    realm: 'diagrammo',
    name: 'Apps',
    glyph: 'layers',
    blurb: 'What a person opens.',
    tint: 'blue',
    probed: true,
  },
  {
    id: 'cloud',
    realm: 'diagrammo',
    name: 'Cloud',
    glyph: 'cloudUp',
    blurb: 'The Worker the app talks to, and the console that watches it. Its database here is throwaway.',
    tint: 'purple',
    probed: true,
  },
  {
    id: 'reference',
    realm: 'diagrammo',
    name: 'Reference',
    glyph: 'compass',
    blurb: 'How it fits together, and what it exposes.',
    tint: 'teal',
    probed: true,
  },
  {
    id: 'production',
    realm: 'elsewhere',
    name: 'Production',
    glyph: 'rocket',
    blurb: 'The real internet, with real customer data behind it.',
    tint: 'red',
    probed: false,
  },
  {
    id: 'consoles',
    realm: 'elsewhere',
    name: 'Consoles',
    glyph: 'dials',
    blurb: 'Vendor dashboards and the tracker, plus the tailnet serving this page. Each wants you signed in.',
    tint: 'cyan',
    probed: false,
  },
  {
    id: 'openclaw',
    realm: 'openclaw',
    name: 'OpenClaw',
    glyph: 'bot',
    blurb: '',
    tint: 'orange',
    probed: true,
    bare: true,
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
    blurb: 'The diagram editor, the same app online.diagrammo.app serves.',
    detail: 'Its diagrams are throwaway, and rebuilding it is by hand — see the README.',
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
    blurb: 'The one Cloudflare Worker, run by wrangler against a local database.',
    detail: 'Sign-in mail is logged, not sent: journalctl --user -u anchor-api.',
    port: 8787,
    unit: 'anchor-api',
  },
  {
    id: 'console',
    group: 'cloud',
    icon: 'pulse',
    name: 'Online console',
    blurb: 'Cloud health and the issue board.',
    detail: 'Every data route needs a session.',
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
    blurb: 'Inspector for the dgmo MCP server, with a gallery per chart type.',
    detail: 'Serves what pnpm studio last produced; rerun it after a dgmo change.',
    port: 4347,
    unit: 'anchor-studio',
  },
  {
    // Not a dev server and not in the diagrammo tree.
    //
    // hostRewrite is off because the gateway checks the Origin it was reached
    // on; rewriting Host to localhost makes it refuse the pairing routes.
    id: 'openclaw',
    group: 'openclaw',
    icon: 'bot',
    name: 'Gateway',
    blurb: 'The personal agent gateway and its control page, on the Claude CLI backend.',
    detail: 'Its own repo. It can drive Diagrammo the way it can drive anything else.',
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
    blurb: 'Every endpoint, generated from the schemas the Worker here is serving.',
    path: '/api-docs',
    dependsOn: 'api',
  },
];

// Addresses that are not on this box. They get no dot, because nothing here
// can honestly say whether they are up, and they open in a new tab, because
// leaving the hub to reach one is a departure rather than a navigation.
//
// 🔴 Every address below came from the ecosystem docs' own vendor pages
// (infrastructure/vendors/*.md), not from memory -- including the Cloudflare
// account id and the PostHog project number. Each was then fetched on
// 2026-09-04: a 302 or a redirect to a login page is the right answer for a
// console, and a 403 is a bot challenge rather than a wrong URL.
//
// ⚠️ Where a deeper path could not be confirmed, the ROOT is used instead of a
// guess. npm is the one that matters -- see its row.
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
    host: 'us.posthog.com · 351484',
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
  {
    id: 'npm',
    group: 'consoles',
    icon: 'package',
    // 🔴 The ROOT on purpose. An org or settings path could not be confirmed:
    // npmjs.com answers a Cloudflare challenge to curl AND to a headless
    // browser, so a deeper link would be a guess dressed as a fact. The docs
    // record this address, and package Settings -> Trusted Publisher is two
    // clicks from it.
    name: 'npm',
    host: 'npmjs.com',
    url: 'https://www.npmjs.com',
  },
  {
    id: 'stripe',
    group: 'consoles',
    icon: 'card',
    name: 'Stripe',
    host: 'dashboard.stripe.com',
    url: 'https://dashboard.stripe.com',
  },
  {
    id: 'resend',
    group: 'consoles',
    icon: 'mail',
    name: 'Resend',
    host: 'resend.com',
    url: 'https://resend.com',
  },
  {
    id: 'google',
    group: 'consoles',
    icon: 'key',
    name: 'Google Cloud',
    host: 'console.cloud.google.com',
    url: 'https://console.cloud.google.com',
  },
  {
    id: 'apple-dev',
    group: 'consoles',
    icon: 'badge',
    name: 'Apple Developer',
    host: 'developer.apple.com',
    url: 'https://developer.apple.com/account',
  },
  {
    id: 'apple-asc',
    group: 'consoles',
    icon: 'window',
    name: 'App Store Connect',
    host: 'appstoreconnect.apple.com',
    url: 'https://appstoreconnect.apple.com',
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

// One mark renderer for all four sizes. `extra` picks the size class; the pip
// only ever rides a row's mark.
//
// Putting the pip ON the icon rather than beside it keeps one object per row
// where there would otherwise be two competing for the same glance.
// The icon, plus — for anything on this box — a status pip riding its corner.
// Putting the pip ON the icon rather than beside it keeps one object per row
// where there would otherwise be two competing for the same glance.
function mark(id, withPip, extra = '') {
  return `<span class="mark${extra ? ' ' + extra : ''}">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"
               stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${ICONS[id] ?? ''}</svg>
          ${withPip ? '<span class="pip" aria-hidden="true"></span>' : ''}
        </span>`;
}

// Everything the filter matches on, in one lowercased attribute. Building it
// server-side means the client never walks the DOM for text, and a row whose
// port or host is only in a mono span is still findable by typing it.
const haystack = (...parts) => esc(parts.filter(Boolean).join(' ').toLowerCase());

// A service or a view. Four lanes, fixed: mark, name, port, prose. The lanes
// are the whole point of this layout -- the older row put the port in an `auto`
// column at the far right edge, a thousand pixels from the name it belongs to,
// and let the prose run to 92ch in full-contrast ink between them. The name you
// are looking for was the lightest thing on its own row.
//
// The prose lane always renders both lines, blurb then detail, so every row is
// the same height whether or not it has a caveat. Uniform rows are what let the
// eye run down the name lane without re-finding it on each line.
//
// Every row is an <a>, with the href present only when it leads somewhere. An
// <a> without href is inert and takes no hover, so the state can change without
// the tag changing -- which is what lets the 5-second refresh repaint in place
// instead of reloading the whole page and throwing away the scroll position.
//
// For the same reason all the notes are rendered up front and CSS shows the one
// matching the row's state class. The refresh then never has to build HTML, and
// there is no second copy of this markup living in a <script>.
function row(s) {
  const href = s.state === 'ready' ? ` href="${esc(s.url)}"` : '';
  const notes =
    s.kind === 'view'
      ? `<p class="note stopped">Needs ${esc(s.requires)} running.</p>`
      : `<p class="note unexposed">On anchor:<code>${esc(s.expose)}</code></p>
        <p class="note stopped">On anchor:<code>${esc(s.start)}</code></p>`;
  return `<a class="row ${s.state}" id="card-${esc(s.id)}" data-id="${esc(s.id)}"
        data-find="${haystack(s.name, s.blurb, s.detail, s.short)}"${href}>
        ${mark(s.icon, true)}
        <span class="name">${esc(s.name)}</span>
        <span class="where">${esc(s.short)}</span>
        <span class="what">
          <span class="blurb">${esc(s.blurb)}</span>
          <span class="detail">${s.detail ? esc(s.detail) : ''}</span>
          <span class="state">
            <span class="s ready">Ready</span>
            <span class="s unexposed">Running, not shared</span>
            <span class="s stopped">Not running</span>
          </span>
          ${notes}
        </span>
      </a>`;
}

// An address elsewhere is a tile rather than a row: there is no status to
// report and no command to print, so all it owes you is what it is and where it
// goes. Fourteen of these used to carry as much page height as the eight
// servers above them; they are the cheapest thing here and now read that way.
function tile(l) {
  return `<a class="tile" id="card-${esc(l.id)}" data-find="${haystack(l.name, l.host)}"
        href="${esc(l.url)}" target="_blank" rel="noreferrer">
        ${mark(l.icon, false, 'flat')}
        <span class="tile-body">
          <span class="name">${esc(l.name)}</span>
          <span class="host">${esc(l.host)}</span>
        </span>
      </a>`;
}

// Heading, blurb and rows, with no rule and no fill. A section is the inner of
// only two levels now: the band above it is the one that gets a rule and a
// tally, and this one is told apart by size and by the smaller glyph. The tint
// lives on the glyphs rather than on the heading, because four of the six hues
// fall under 4.5:1 against the light ground and a heading is text.
function section(group, rows) {
  const body = group.probed
    ? `<div class="rows">
        ${rows.map(row).join('\n        ')}
      </div>`
    : `<div class="tiles">
        ${rows.map(tile).join('\n        ')}
      </div>`;
  const head = group.bare
    ? ''
    : `<div class="group-head">
        ${mark(group.glyph, false, 'sm')}
        <h3>${esc(group.name)}</h3>
        ${group.blurb ? `<p>${esc(group.blurb)}</p>` : ''}
      </div>`;
  return `<section id="${esc(group.id)}" class="group" data-group="${esc(group.id)}"
      style="--tint: var(--t-${esc(group.tint)})">
      ${head}
      ${body}
    </section>`;
}

// A band is the page's outermost cut, and there are three: the two projects
// that run on this box, then everything that does not.
//
// 🔴 The cut CHANGED here on 2026-09-05, and it is the one decision in this
// rewrite that moves data rather than pixels. Production and the vendor
// consoles used to hang under Diagrammo, because they are Diagrammo's. They now
// hang under `elsewhere`, because the question this page answers first is "can I
// reach it, and is it up" -- and the honest answer for those fourteen addresses
// is that nothing here can say. Grouping by owner put four addresses this page
// cannot probe in the middle of a column of pips that all mean something.
// OpenClaw has no production and no consoles, so nothing is lost by the move.
function band(r, sections, stat) {
  return `<section class="band" id="band-${esc(r.id)}" style="--tint: var(--t-${esc(r.tint)})">
    <div class="band-head">
      ${mark(r.glyph, false, 'big')}
      <h2>${esc(r.name)}</h2>
      <p>${esc(r.blurb)}</p>
      <span class="rule" aria-hidden="true"></span>
      ${stat}
    </div>
    <div class="groups">
      ${sections.join('\n      ')}
    </div>
  </section>`;
}

// What a band is worth in one glance: how much of it is up, or -- for the band
// this page cannot probe -- how many addresses it holds and the fact that no
// dot under it is a health claim. The fraction carries a data attribute so the
// 5-second refresh patches it without rebuilding anything.
function bandStat(r, groups, rows) {
  const mine = groups.filter((g) => g.realm === r.id);
  const here = rows.filter((x) => mine.some((g) => g.id === x.group && g.probed));
  if (!here.length) {
    const away = rows.filter((x) => mine.some((g) => g.id === x.group));
    return `<span class="band-stat">${away.length} addresses · no status from here</span>`;
  }
  return `<span class="band-stat"><b data-band-up="${esc(r.id)}">${
    here.filter((x) => x.state === 'ready').length
  }/${here.length}</b> running</span>`;
}

// The one sentence the bar owes you before you read anything else. All-clear is
// the normal state, so it is the quiet one; anything else names the count that
// is wrong, because "7 of 8" without saying which kind of wrong sends you
// hunting down the page for the odd row.
function tallyText(rows) {
  const probed = rows.filter((r) => r.kind === 'service' || r.kind === 'view');
  const up = probed.filter((r) => r.state === 'ready').length;
  const unexposed = probed.filter((r) => r.state === 'unexposed').length;
  const stopped = probed.filter((r) => r.state === 'stopped').length;
  const tail = [
    stopped ? `${stopped} stopped` : '',
    unexposed ? `${unexposed} not shared` : '',
  ].filter(Boolean);
  return {
    cls: stopped ? 'bad' : unexposed ? 'warn' : 'ok',
    text: `${up} of ${probed.length} running${tail.length ? ' · ' + tail.join(' · ') : ''}`,
  };
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
//
// 🔴 A tint is NEVER used for text. Measured against the light ground on
// 2026-09-05: teal 3.44:1, red 4.28:1, orange 3.00:1, cyan 2.96:1 -- four of
// the six fail 4.5:1, and slate has no darker variant to reach for. Headings
// are therefore `--ink` and the hue rides the glyph beside them, which is a
// graphic and answers to 3:1. Do not "fix" a heading back to its tint.
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
    /* Redoc's sample panel only; deliberately dark in both themes. */
    --panel: #202833;       /* dark surface */
    --panel-ink: #e6eaef;   /* dark text    */
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
      --panel: #202833;      /* surface — one step above the ground */
      --panel-ink: #e6eaef;
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
  const bands = REALMS.filter((r) => groups.some((g) => g.realm === r.id));
  const t = tallyText(rows);
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>anchor</title>
<style>
${SLATE}
  * { box-sizing: border-box; }
  html { scroll-behavior: smooth; scroll-padding-top: 3.6rem; }
  body {
    margin: 0; background: var(--bg); color: var(--ink);
    font: 14px/1.5 ui-sans-serif, system-ui, -apple-system, "Segoe UI", sans-serif;
    -webkit-font-smoothing: antialiased;
  }
  main { max-width: 74rem; margin: 0 auto; padding: .9rem 1.5rem 2.5rem; }

  /* The surfaces nobody draws still belong to the page. Left alone they ship
     the browser's own blue, which is the cheapest tell that a page was
     assembled rather than built. */
  ::selection { background: color-mix(in srgb, var(--accent) 28%, transparent); }
  :focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; border-radius: 6px; }
  * { scrollbar-width: thin; scrollbar-color: var(--line) transparent; }

  /* The bar carries the identity, the one sentence of status and the filter,
     so the page under it needs neither a title block nor a footer. */
  .bar {
    position: sticky; top: 0; z-index: 5;
    background: var(--bar); backdrop-filter: blur(10px);
    border-bottom: 1px solid var(--line-soft);
  }
  .bar-inner {
    max-width: 74rem; margin: 0 auto; padding: .45rem 1.5rem;
    display: flex; align-items: center; gap: .85rem; flex-wrap: wrap;
  }
  .brand {
    display: inline-flex; align-items: center; gap: .42rem;
    font-weight: 650; letter-spacing: -.01em; color: var(--ink); text-decoration: none;
  }
  .brand svg { width: 1.1rem; height: 1.1rem; color: var(--accent); }

  /* The answer to the page's first question, before any scanning. All-clear is
     the normal state and so the quiet one. */
  .tally {
    display: inline-flex; align-items: center; gap: .42rem;
    font-size: .84rem; color: var(--ink); white-space: nowrap;
  }
  .tally .dot {
    width: .5rem; height: .5rem; border-radius: 50%; background: var(--ready); flex: none;
  }
  .tally.warn .dot { background: var(--warn); }
  .tally.bad .dot { background: var(--warn); }
  .tally.warn, .tally.bad { font-weight: 600; }

  .find {
    margin-left: auto; margin-right: .35rem;
    display: flex; align-items: center; gap: .55rem;
  }
  .find-field {
    display: flex; align-items: center; gap: .4rem;
    padding: .2rem .5rem .2rem .55rem; border-radius: 7px;
    background: var(--raise); border: 1px solid var(--line);
    transition: border-color 120ms ease-out;
  }
  /* The ring belongs to the field, not to the bare input inside it: an input
     left to focus for itself draws Chromium's own 3px ring in its own colour,
     which is nobody's design system. */
  .find-field:focus-within {
    border-color: var(--accent);
    box-shadow: 0 0 0 3px color-mix(in srgb, var(--accent) 22%, transparent);
  }
  .find-field svg { width: .82rem; height: .82rem; color: var(--muted); flex: none; }
  /* A fixed width, not one that grows on focus: widening an input animates a
     layout property, and the field is already wide enough for anything anyone
     types into it. */
  #q {
    width: 12rem; border: 0; background: none; color: var(--ink);
    caret-color: var(--accent); font: inherit; font-size: .82rem; padding: 0;
  }
  #q:focus, #q:focus-visible { outline: none; box-shadow: none; }
  #q::placeholder { color: var(--muted); }
  /* type=search buys the semantics and, unasked, an OS-drawn clear button that
     belongs to no design system. Escape is the clear. */
  #q::-webkit-search-cancel-button, #q::-webkit-search-decoration { -webkit-appearance: none; display: none; }
  .kbd {
    font: 11px/1 ui-monospace, SFMono-Regular, Menlo, monospace;
    color: var(--muted); border: 1px solid var(--line); border-radius: 4px;
    padding: .18rem .3rem; flex: none;
  }
  .find-field:focus-within .kbd { display: none; }
  .hits {
    font: 11.5px/1 ui-monospace, SFMono-Regular, Menlo, monospace;
    font-variant-numeric: tabular-nums; color: var(--muted); white-space: nowrap;
  }
  .hits:empty { display: none; }
  .meta {
    display: flex; align-items: center; gap: .8rem;
    font-size: .78rem; color: var(--muted); white-space: nowrap;
  }
  .meta a { color: var(--muted); text-decoration: none; }
  .meta a:hover { color: var(--accent); }

  .sr { position: absolute; width: 1px; height: 1px; overflow: hidden; clip-path: inset(50%); }
  .lede {
    margin: .1rem 0 1.15rem; color: var(--muted); font-size: .84rem;
    max-width: 74ch; text-wrap: balance;
  }

  /* Two levels of heading and nothing else: a band with a rule and a tally, a
     section with a smaller glyph. The older page spent four devices -- a filled
     band, a tinted rail, a section head with its own rule, then the row -- on a
     hierarchy that is one list of twenty-two links. */
  .band { margin: 0 0 1.65rem; }
  .band:last-child { margin-bottom: 0; }
  .band-head { display: flex; align-items: center; gap: .55rem; margin-bottom: .7rem; }
  .band-head h2 {
    margin: 0; font-size: 1.02rem; font-weight: 650;
    letter-spacing: -.015em; color: var(--ink); white-space: nowrap;
  }
  .band-head p { margin: 0; color: var(--muted); font-size: .8rem; }
  .band-head .rule { flex: 1 1 2rem; height: 1px; min-width: 1.5rem; background: var(--line); }
  .band-stat { color: var(--muted); font-size: .8rem; white-space: nowrap; }
  .band-stat b {
    font: 12.5px/1 ui-monospace, SFMono-Regular, Menlo, monospace;
    font-variant-numeric: tabular-nums; color: var(--ink); font-weight: 600;
  }
  .groups { display: flex; flex-direction: column; gap: 1rem; }

  .group-head { display: flex; align-items: center; gap: .42rem; margin-bottom: .3rem; }
  .group-head h3 {
    margin: 0; font-size: .82rem; font-weight: 650;
    letter-spacing: -.005em; color: var(--ink); white-space: nowrap;
  }
  .group-head p { margin: 0; color: var(--muted); font-size: .78rem; }

  .mark {
    position: relative; width: 1.6rem; height: 1.6rem; border-radius: 7px;
    display: inline-flex; align-items: center; justify-content: center;
    background: var(--chip);
    background: color-mix(in srgb, var(--tint) 14%, transparent);
    color: var(--tint); flex: none;
  }
  .mark svg { width: .95rem; height: .95rem; }
  .mark.sm { width: 1.15rem; height: 1.15rem; border-radius: 5px; }
  .mark.sm svg { width: .78rem; height: .78rem; }
  .mark.big { width: 1.7rem; height: 1.7rem; border-radius: 8px; }
  .mark.big svg { width: 1.05rem; height: 1.05rem; }
  /* An address elsewhere carries the glyph without the chip: fourteen filled
     chips down there out-weighed the eight servers they sit under. */
  .mark.flat { width: 1.15rem; height: 1.15rem; background: none; border-radius: 0; }
  .mark.flat svg { width: 1.15rem; height: 1.15rem; }
  /* One variable holds the row's state colour, and the pip, the ring, the
     border and the wash all read it. Three places naming their own hex is how
     a stopped row ends up with a grey dot inside a yellow frame. */
  .row { --pip: var(--off); }
  .row.ready { --pip: var(--ready); }
  .row.unexposed { --pip: var(--warn); }
  .pip {
    position: absolute; right: -3px; bottom: -3px; width: .46rem; height: .46rem;
    border-radius: 50%; background: var(--pip);
    box-shadow: 0 0 0 2px var(--bg);
  }

  /* The page's one authored moment, and it is spent where attention is owed:
     a pip that is not green breathes until somebody deals with it. Nothing
     else on the page moves by itself. */
  @keyframes breathe {
    0%, 100% { box-shadow: 0 0 0 2px var(--bg), 0 0 0 2px color-mix(in srgb, var(--pip) 60%, transparent); }
    55%      { box-shadow: 0 0 0 2px var(--bg), 0 0 0 6px color-mix(in srgb, var(--pip) 0%, transparent); }
  }
  .row.unexposed .pip, .row.stopped .pip { animation: breathe 2.6s ease-out infinite; }

  .rows { display: flex; flex-direction: column; gap: .04rem; }

  /* Four lanes: mark, name, port, prose. Fixed, so the eye runs down the name
     lane and the port lane without re-finding either on every line. */
  .row {
    display: grid; grid-template-columns: 1.6rem 9.75rem 5.2rem 1fr;
    align-items: start; gap: 0 .65rem;
    padding: .3rem .55rem; margin: 0 -.55rem; border-radius: 8px;
    border: 1px solid transparent;
    text-decoration: none; color: inherit;
    transition: background-color 120ms ease-out;
  }
  .row[href]:hover { background: color-mix(in srgb, var(--tint) 10%, transparent); }
  .name { font-weight: 600; letter-spacing: -.005em; }
  .row[href]:hover .name, .tile:hover .name { color: var(--tint); }
  .name, .where, .what { padding-top: .1rem; }
  .where {
    font: 12px/1.5 ui-monospace, SFMono-Regular, Menlo, monospace;
    font-variant-numeric: tabular-nums;
    color: var(--muted); white-space: nowrap;
  }
  .row[href]:hover .where { color: var(--tint); }

  /* Blurb then detail, both lines always present so every row is the same
     height. The blurb used to be set in full-contrast ink at 92ch, which made
     the explanation heavier on the page than the thing you came to click. */
  .what { min-width: 0; }
  .blurb { display: block; color: var(--ink); font-size: .84rem; }
  /* 🔴 The caveat line is a second COLOUR, never the same colour at a lower
     opacity: muted at .74 measures 3.6:1 on the light ground and fails. */
  .detail { display: block; color: var(--muted); font-size: .79rem; }
  .detail:empty { display: none; }

  /* One note and one state word per row; CSS picks the pair that matches the
     state class, so the refresh only has to swap that class. A ready row says
     so with its pip and its link, and keeps the word for a screen reader. */
  .state .s, .note { display: none; }
  .state { display: block; font-size: .8rem; font-weight: 600; margin-top: .1rem; }
  .row.ready .state {
    position: absolute; width: 1px; height: 1px; overflow: hidden; clip-path: inset(50%);
  }
  .row.unexposed .state, .row.stopped .state { color: var(--ink); }
  .row.ready .state .s.ready,
  .row.unexposed .state .s.unexposed,
  .row.stopped .state .s.stopped { display: inline; }
  .row.unexposed .note.unexposed,
  .row.stopped .note.stopped { display: block; }
  /* A row that is not ready gets a real frame rather than relying on a 7px
     pip. Yellow reaches only 2.2:1 on the light ground, so the dot can never be
     the whole signal there -- the bold state word in --ink is, and the frame
     and the wash are what make the row findable from across the page. */
  .row.unexposed, .row.stopped {
    border-color: color-mix(in srgb, var(--pip) 55%, var(--line));
    background: color-mix(in srgb, var(--pip) 7%, transparent);
  }
  .note { margin: .15rem 0 .2rem; font-size: .8rem; color: var(--muted); }
  code {
    display: inline-block; margin-top: .2rem; padding: .18rem .4rem; border-radius: 5px;
    background: var(--raise); border: 1px solid var(--line-soft);
    font: 12px/1.45 ui-monospace, SFMono-Regular, Menlo, monospace;
    white-space: pre-wrap; word-break: break-all; color: var(--ink);
  }

  .tiles {
    display: grid; gap: .04rem .45rem;
    grid-template-columns: repeat(auto-fill, minmax(14.75rem, 1fr));
  }
  .tile {
    display: flex; align-items: center; gap: .62rem;
    padding: .28rem .55rem; margin: 0 -.55rem; border-radius: 8px;
    text-decoration: none; color: inherit; min-width: 0;
    transition: background-color 120ms ease-out;
  }
  .tile:hover { background: color-mix(in srgb, var(--tint) 10%, transparent); }
  .tile-body { display: flex; flex-direction: column; min-width: 0; }
  .tile .name { line-height: 1.3; font-size: .87rem; }
  .host {
    font: 11.5px/1.4 ui-monospace, SFMono-Regular, Menlo, monospace;
    color: var(--muted); overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
  }

  /* Filtering. A hidden row is display:none rather than moved, so nothing
     reflows sideways and the lanes hold their positions as the list shortens. */
  [hidden] { display: none !important; }
  .row.sel, .tile.sel {
    background: color-mix(in srgb, var(--tint) 16%, transparent);
    outline: 2px solid color-mix(in srgb, var(--tint) 55%, transparent);
    outline-offset: -1px;
  }
  .empty {
    display: none; margin: .5rem 0 0; color: var(--muted); font-size: .86rem;
  }
  .empty b { color: var(--ink); font-weight: 600; }
  body.no-hits .empty { display: block; }

  @media (prefers-reduced-motion: reduce) {
    * { animation: none !important; transition: none !important; scroll-behavior: auto !important; }
  }

  /* Narrow: the name and the port keep line one, the prose drops under both.
     Left to auto-placement the port landed on a third row under the mark and
     read as a row of its own. */
  @media (max-width: 56rem) {
    main { padding-top: .75rem; }
    .row { grid-template-columns: 1.6rem 1fr auto; gap: 0 .6rem; }
    .row .where { grid-column: 3; grid-row: 1; }
    .row .what { grid-column: 2 / -1; grid-row: 2; }
    .band-head { flex-wrap: wrap; }
    .band-head .rule { display: none; }
    .band-head p { order: 3; flex: 1 0 100%; margin-top: -.1rem; }
    .group-head { flex-wrap: wrap; }
    main { padding-left: 1.1rem; padding-right: 1.1rem; }
    /* Two up rather than one: fourteen stacked addresses were a third of the
       page's height on a phone, for the cheapest links on it. */
    .tiles { grid-template-columns: repeat(2, minmax(0, 1fr)); gap: .04rem .5rem; }
    .find { margin-left: 0; margin-right: 0; order: 3; flex: 1 0 100%; }
    #q, #q:focus { width: 100%; }
    .find-field { flex: 1; }
    .meta { margin-left: auto; }
  }
</style>
</head>
<body>
<div class="bar">
  <div class="bar-inner">
    <a class="brand" href="#top">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"
           stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${ICONS.anchor}</svg>
      anchor
    </a>
    <span class="tally ${t.cls}" id="tally">
      <span class="dot" aria-hidden="true"></span><span id="tally-text">${esc(t.text)}</span>
    </span>
    <div class="find">
      <label class="find-field" for="q">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9"
             stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${ICONS.search}</svg>
        <input id="q" type="search" autocomplete="off" spellcheck="false"
               placeholder="Filter" aria-label="Filter this page">
        <span class="kbd" aria-hidden="true">/</span>
      </label>
      <span class="hits" id="hits" role="status"></span>
    </div>
    <div class="meta">
      <span>Checked <span id="stamp">${new Date().toLocaleTimeString('en-GB')}</span> · every 5s</span>
      <a href="/status.json">Raw status</a>
    </div>
  </div>
</div>
<main id="top">
  <h1 class="sr">anchor</h1>
  <p class="lede">Everything on this box, reachable from any device on the tailnet, plus the addresses off it. Nothing here is open to the internet.</p>
  ${bands
    .map((r) =>
      band(
        r,
        groups.filter((g) => g.realm === r.id).map((g) => section(g, byGroup(g.id))),
        bandStat(r, groups, rows)
      )
    )
    .join('\n  ')}
  <p class="empty" id="empty">Nothing here matches <b id="empty-q"></b>.</p>
</main>
<script>
  // Repaint in place rather than reloading: a reload every 5 seconds throws
  // away the scroll position, which on a page you are reading is the one thing
  // you were holding on to. External addresses are never touched -- they carry
  // no state to repaint.
  const paint = (r) => {
    const el = document.getElementById('card-' + r.id);
    if (!el) return;
    el.className = 'row ' + r.state + (el.classList.contains('sel') ? ' sel' : '');
    if (r.state === 'ready') el.setAttribute('href', r.url);
    else el.removeAttribute('href');
  };
  const G = ${JSON.stringify(
    Object.fromEntries(groups.map((g) => [g.id, { realm: g.realm, probed: g.probed }]))
  )};
  const counts = (rows) => {
    for (const el of document.querySelectorAll('[data-band-up]')) {
      const mine = rows.filter((r) => G[r.group] && G[r.group].probed && G[r.group].realm === el.dataset.bandUp);
      el.textContent = mine.filter((r) => r.state === 'ready').length + '/' + mine.length;
    }
    const probed = rows.filter((r) => G[r.group] && G[r.group].probed);
    const up = probed.filter((r) => r.state === 'ready').length;
    const un = probed.filter((r) => r.state === 'unexposed').length;
    const off = probed.filter((r) => r.state === 'stopped').length;
    const tail = [];
    if (off) tail.push(off + ' stopped');
    if (un) tail.push(un + ' not shared');
    document.getElementById('tally-text').textContent =
      up + ' of ' + probed.length + ' running' + (tail.length ? ' \\u00b7 ' + tail.join(' \\u00b7 ') : '');
    document.getElementById('tally').className =
      'tally ' + (off ? 'bad' : un ? 'warn' : 'ok');
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

  // Twenty-two links is more than a glance and fewer than a search box usually
  // earns -- but the fastest route to any of them is two letters and Enter, so
  // the field is here and the whole keyboard opens it. Matching is on a
  // data-find attribute built server-side, so nothing walks the DOM for text.
  const q = document.getElementById('q');
  const hits = document.getElementById('hits');
  const items = [...document.querySelectorAll('[data-find]')];
  let sel = -1;

  const visible = () => items.filter((el) => !el.hidden);

  function select(i) {
    for (const el of items) el.classList.remove('sel');
    const list = visible();
    if (!list.length) { sel = -1; return; }
    sel = (i + list.length) % list.length;
    const el = list[sel];
    el.classList.add('sel');
    el.scrollIntoView({ block: 'nearest' });
  }

  function apply() {
    const term = q.value.trim().toLowerCase();
    let shown = 0;
    for (const el of items) {
      const ok = !term || el.dataset.find.includes(term);
      el.hidden = !ok;
      if (ok) shown++;
    }
    // A heading with nothing under it is noise; a band with no headings left is
    // worse. Both fold away as the list shortens.
    for (const g of document.querySelectorAll('.group')) {
      g.hidden = !g.querySelector('[data-find]:not([hidden])');
    }
    for (const b of document.querySelectorAll('.band')) {
      b.hidden = !b.querySelector('.group:not([hidden])');
    }
    hits.textContent = term ? shown + ' of ' + items.length : '';
    document.body.classList.toggle('no-hits', Boolean(term) && shown === 0);
    document.getElementById('empty-q').textContent = q.value.trim();
    if (term && shown) select(0); else { for (const el of items) el.classList.remove('sel'); sel = -1; }
  }

  q.addEventListener('input', apply);
  q.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') { q.value = ''; apply(); q.blur(); return; }
    if (e.key === 'ArrowDown') { e.preventDefault(); select(sel + 1); return; }
    if (e.key === 'ArrowUp') { e.preventDefault(); select(sel - 1); return; }
    if (e.key === 'Enter') {
      const el = visible()[sel < 0 ? 0 : sel];
      if (el && el.hasAttribute('href')) { e.preventDefault(); el.click(); }
    }
  });

  // Any printable key starts a filter, the way a file list does. A key that
  // would type into something else is left alone.
  addEventListener('keydown', (e) => {
    if (e.metaKey || e.ctrlKey || e.altKey) return;
    const tag = document.activeElement && document.activeElement.tagName;
    if (tag === 'INPUT' || tag === 'TEXTAREA') return;
    if (e.key === '/' || (e.key.length === 1 && /\\S/.test(e.key))) {
      e.preventDefault();
      q.focus();
      if (e.key !== '/') { q.value += e.key; apply(); }
    }
  });
</script>
</body>
</html>`;
}

// Redoc renders the spec this page proxies. The spec is served from THIS
// origin rather than from the Worker's own port, so the browser never makes a
// cross-origin request and the Worker's CORS allowlist is irrelevant.
//
// 🔴 The theme is READ OUT OF THE PAGE'S OWN CSS VARIABLES at init rather than
// written again as a JS object. Redoc wants hex strings and the palette lives
// in `SLATE` as custom properties, so the obvious move is a second copy in
// JavaScript -- and a second copy of a palette is a second thing to forget
// when the first one changes. `getComputedStyle` already resolves the media
// query, so light and dark both fall out of the block that is already there.
//
// ⚠️ Every key below was read from Redoc 2.5.0's own `src/theme.ts` on
// 2026-09-04, not recalled. A key it does not know is dropped silently, so a
// misremembered name reads as "the theme did not apply".
function docsPage() {
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Cloud API reference</title>
<style>
${SLATE}
  body { margin: 0; background: var(--bg); color: var(--ink); }
  .bar {
    display: flex; align-items: center; gap: .75rem;
    padding: .6rem 1rem; border-bottom: 1px solid var(--line-soft); background: var(--raise);
    font: 14px/1.4 ui-sans-serif, system-ui, -apple-system, "Segoe UI", sans-serif;
  }
  .bar a { color: var(--accent); text-decoration: none; }
  .bar a:hover { text-decoration: underline; }
  .bar span { color: var(--muted); }
  /* Redoc shouts two kinds of label and only one of them has a theme key.
     The sidebar.groupItems.textTransform key handles the nav; these h5 section
     labels (Authorizations, query Parameters, Response schema) have none, so
     they are undone here. Redoc's own class names are emotion-generated and
     change between builds, so the selector is the element, never the class.

     The source text is mid-sentence ("query Parameters"), hence the
     first-letter rule -- without it, removing the caps leaves a lowercase
     heading, which is a different kind of wrong. */
  #redoc h5 { text-transform: none; color: var(--muted); }
  #redoc h5::first-letter { text-transform: uppercase; }

  /* 🔴 The colour above is a fix, not a preference. Redoc hard-codes these
     labels at rgba(38, 50, 56, .5) with no theme key -- measured 2026-09-04 at
     2.61:1 on the light ground, and on the dark one it is a near-black at half
     alpha, which is all but invisible. textMuted is 5.36:1 and 6.91:1. */
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
  const v = (name) =>
    getComputedStyle(document.documentElement).getPropertyValue(name).trim();

  const theme = () => ({
    colors: {
      primary: { main: v('--accent') },
      success: { main: v('--ready') },
      warning: { main: v('--warn') },
      error: { main: v('--t-red') },
      gray: { 50: v('--raise'), 100: v('--line-soft') },
      text: { primary: v('--ink'), secondary: v('--muted') },
      border: { dark: v('--line'), light: v('--line-soft') },
      // One hue per method, from the same six slots the front page groups use.
      http: {
        get: v('--t-blue'),
        post: v('--t-teal'),
        put: v('--t-purple'),
        options: v('--t-cyan'),
        patch: v('--t-orange'),
        delete: v('--t-red'),
        basic: v('--muted'),
        link: v('--t-cyan'),
        head: v('--t-purple'),
      },
    },
    schema: { nestedBackground: v('--raise') },
    typography: {
      fontSize: '14px',
      fontFamily: 'ui-sans-serif, system-ui, -apple-system, "Segoe UI", sans-serif',
      headings: {
        fontFamily: 'ui-sans-serif, system-ui, -apple-system, "Segoe UI", sans-serif',
        fontWeight: '650',
      },
      code: {
        fontFamily: 'ui-monospace, SFMono-Regular, Menlo, monospace',
        color: v('--t-red'),
        backgroundColor: v('--raise'),
      },
      links: { color: v('--accent') },
    },
    sidebar: {
      backgroundColor: v('--raise'),
      textColor: v('--ink'),
      // The house rule is no shouted headings anywhere.
      groupItems: { textTransform: 'none' },
    },
    rightPanel: { backgroundColor: v('--panel'), textColor: v('--panel-ink') },
  });

  const draw = () =>
    Redoc.init('/openapi.json',
      { hideDownloadButton: false, expandResponses: '200,201', theme: theme() },
      document.getElementById('redoc'));

  draw();
  // Redoc takes its theme once, at init. The rest of this hub follows the OS
  // theme live through CSS, so redrawing on the change keeps the two honest.
  window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', draw);
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
      res.end(JSON.stringify({ realms: REALMS, groups: GROUPS, services, views, links }, null, 2));
      return;
    }
    res.writeHead(200, { 'content-type': 'text/html; charset=utf-8' });
    res.end(page(services, views, links));
  })
  .listen(PORT, '127.0.0.1', () => {
    console.log(`anchor-hub on http://127.0.0.1:${PORT}/ for ${HOST}`);
  });

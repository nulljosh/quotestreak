// Checks that every `art` URL in quotes.json actually resolves, at both the size the
// game uses and the thumbnail size the landing-page hero wall requests.
//
//   node scripts/check-art.mjs
//
// Exits non-zero if anything 404s. Needs network — a Claude Code web session cannot run
// this, because image.tmdb.org and mzstatic.com are refused by the egress policy (403 on
// CONNECT). Run it locally.

import { readFile } from 'node:fs/promises';

const thumb = (url) => url.replace('/w500/', '/w185/').replace('/600x600bb.jpg', '/200x200bb.jpg');

const quotes = JSON.parse(await readFile(new URL('../quotes.json', import.meta.url), 'utf8'));

const seen = new Set();
const targets = [];
for (const q of quotes) {
  if (!q.art || seen.has(q.art)) continue;
  seen.add(q.art);
  targets.push({ answer: q.answer, full: q.art, thumb: thumb(q.art) });
}

async function head(url) {
  try {
    const r = await fetch(url, { method: 'HEAD', redirect: 'follow' });
    return r.status;
  } catch (e) {
    return `ERR ${e.cause?.code || e.message}`;
  }
}

console.log(`Checking ${targets.length} unique artwork URLs (full + thumbnail)...\n`);

const bad = [];
let done = 0;
const QUEUE = 8; // keep it gentle; TMDB and iTunes both throttle

async function worker(list) {
  for (const t of list) {
    const [full, small] = await Promise.all([head(t.full), head(t.thumb)]);
    if (full !== 200) bad.push({ answer: t.answer, url: t.full, status: full, which: 'full' });
    if (small !== 200) bad.push({ answer: t.answer, url: t.thumb, status: small, which: 'thumb' });
    if (++done % 25 === 0) process.stdout.write(`  ${done}/${targets.length}\n`);
  }
}

const chunk = Math.ceil(targets.length / QUEUE);
await Promise.all(
  Array.from({ length: QUEUE }, (_, i) => worker(targets.slice(i * chunk, (i + 1) * chunk)))
);

if (bad.length === 0) {
  console.log(`\nAll ${targets.length} titles resolve at both sizes. The hero wall will render.`);
  process.exit(0);
}

console.log(`\n${bad.length} failure(s):\n`);
for (const b of bad) console.log(`  [${b.status}] ${b.which.padEnd(5)} ${b.answer} — ${b.url}`);
process.exit(1);

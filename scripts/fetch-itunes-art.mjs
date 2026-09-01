#!/usr/bin/env node
// Backfills `art` (iTunes album artwork) onto the music entries in quotes.json that
// are missing it — 45 of 94 as of 2026-09-01, which is most of the reason the
// correct-answer art flash looks unreliable.
//
//   node scripts/fetch-itunes-art.mjs
//
// Needs network. A Claude Code web session cannot run this: itunes.apple.com is
// refused by the egress policy (403 on CONNECT), same as check-art.mjs. Run it locally.
//
// No API key, but the Search API throttles around 20 calls/minute, hence the delay.

import { readFileSync, writeFileSync } from 'node:fs';

const path = new URL('../quotes.json', import.meta.url);
const quotes = JSON.parse(readFileSync(path, 'utf8'));

// The bank's existing music art is 600x600; the API hands back a 100x100 thumbnail URL
// off the same path, so the size segment is all that changes.
const full = (url) => url.replace(/\/100x100bb\.jpg$/, '/600x600bb.jpg');

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const norm = (s) => s.toLowerCase().replace(/[^a-z0-9]/g, '');

let found = 0;
let missed = 0;

for (const q of quotes) {
  if (q.type !== 'music' || q.art) continue;

  const url = `https://itunes.apple.com/search?term=${encodeURIComponent(q.answer)}`
    + '&entity=album&attribute=artistTerm&limit=1';
  const res = await fetch(url);
  if (!res.ok) {
    console.warn('http', res.status, q.answer);
    missed++;
    await sleep(3000);
    continue;
  }
  const hit = (await res.json()).results?.[0];

  // Only take art whose artist actually matches the answer. A near-miss here would
  // hang the wrong album on a correct answer, which is worse than no flash at all.
  if (hit?.artworkUrl100 && norm(hit.artistName) === norm(q.answer)) {
    q.art = full(hit.artworkUrl100);
    console.log('found', q.answer, '->', hit.collectionName);
    found++;
  } else {
    console.warn('no match', q.answer, hit ? `(got ${hit.artistName})` : '');
    missed++;
  }
  await sleep(3000);
}

writeFileSync(path, JSON.stringify(quotes, null, 2) + '\n');
console.log(`\n${found} filled, ${missed} still missing.`);
console.log('Next: node scripts/check-art.mjs, then copy quotes.json to ios/Quotable/Resources/.');

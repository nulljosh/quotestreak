#!/usr/bin/env node
// Backfills `art` (TMDB poster URL) onto quotes.json entries missing it.
// Run once: TMDB_API_KEY=... node scripts/fetch-tmdb-art.mjs
// ponytail: sequential fetches, fine for a one-off 143-item backfill.

import { readFileSync, writeFileSync } from 'node:fs';

const key = process.env.TMDB_API_KEY;
if (!key) {
  console.error('Set TMDB_API_KEY first (get one at themoviedb.org/settings/api).');
  process.exit(1);
}

const path = new URL('../quotes.json', import.meta.url);
const quotes = JSON.parse(readFileSync(path, 'utf8'));

// The bank calls everything that is not music a "movie", but some entries are TV series
// (Game of Thrones, Star Trek, Rick and Morty), and /search/movie never matches those —
// which is why they sat without art. Fall through to /search/tv before giving up.
async function poster(query, year, endpoint) {
  const dateParam = endpoint === 'tv' ? 'first_air_date_year' : 'year';
  const url = `https://api.themoviedb.org/3/search/${endpoint}`
    + `?query=${encodeURIComponent(query)}&${dateParam}=${year}&api_key=${key}`;
  const res = await fetch(url);
  const data = await res.json();
  return data.results?.[0]?.poster_path;
}

for (const q of quotes) {
  if (q.type !== 'movie' || q.art) continue;
  const posterPath = (await poster(q.answer, q.year, 'movie')) || (await poster(q.answer, q.year, 'tv'));
  if (posterPath) {
    q.art = `https://image.tmdb.org/t/p/w500${posterPath}`;
    console.log('found', q.answer);
  } else {
    console.warn('no match', q.answer, q.year);
  }
}

writeFileSync(path, JSON.stringify(quotes, null, 2) + '\n');

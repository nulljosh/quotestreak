// One runnable check for the filtering and validation — the only real logic here.
import assert from 'node:assert/strict';
import { callTool, ToolError, GENRES, TYPES } from './tools.js';

const genres = callTool('list_genres');
assert.ok(genres.total > 0);
assert.equal(genres.genres.reduce((n, g) => n + g.count, 0), genres.total);

const q = callTool('random_quote', { genre: GENRES[0], type: TYPES[0] });
assert.ok(q.options.includes(q.answer), 'the answer must be among its own options');

const hit = callTool('search_quotes', { q: q.answer, limit: 1 });
assert.equal(hit.results.length, 1);
assert.ok(hit.total >= 1);

// Bad input is the caller's to fix, so it has to be named rather than silently ignored.
assert.throws(() => callTool('random_quote', { genre: 'nope' }), ToolError);
assert.throws(() => callTool('search_quotes', { q: '' }), ToolError);
assert.throws(() => callTool('search_quotes', { q: 'a', limit: 999 }), ToolError);
assert.equal(callTool('nope'), null);

console.log('tools: ok');

// node --test — quotes.json is the whole game. A malformed entry does not throw; it
// renders an unwinnable question or an unstyled badge, which only a player would notice.
// ponytail: data integrity only. game.js is a DOM script that runs on import, so its
// logic is not reachable from node without extracting it — do that when a bug demands it.
const { test } = require('node:test');
const assert = require('node:assert/strict');
const quotes = require('./quotes.json');

// Kept in sync by hand with the GENRES map in game.js. An unlisted genre falls back to a
// grey badge rather than failing, so nothing else would catch a typo here.
const GENRES = ['action', 'comedy', 'drama', 'scifi', 'classic', 'pop', 'rock', 'hiphop', 'rnb', 'country'];
const TYPES = ['movie', 'music'];

test('the deck is non-empty', () => {
  assert.ok(Array.isArray(quotes));
  assert.ok(quotes.length > 0);
});

test('every question is answerable', () => {
  for (const q of quotes) {
    // The answer not being among the options is the silent killer: every button is wrong.
    assert.ok(q.options.includes(q.answer), `answer "${q.answer}" missing from its own options`);
    assert.ok(q.options.length >= 2, `"${q.answer}" has fewer than two options`);
    assert.equal(new Set(q.options).size, q.options.length, `"${q.answer}" has duplicate options`);
  }
});

test('every question has the fields nextQuestion() reads', () => {
  for (const q of quotes) {
    for (const field of ['quote', 'answer', 'genre', 'type', 'options']) {
      assert.ok(q[field], `entry "${q.quote || q.answer}" is missing ${field}`);
    }
    assert.ok(GENRES.includes(q.genre), `unknown genre "${q.genre}" — badge would fall back to grey`);
    assert.ok(TYPES.includes(q.type), `unknown type "${q.type}" — prompt would say the wrong thing`);
  }
});

test('no duplicate quotes', () => {
  const seen = new Set(quotes.map(q => q.quote));
  assert.equal(seen.size, quotes.length, 'the same quote can be asked twice in one run');
});

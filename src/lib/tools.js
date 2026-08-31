// The one definition of what Quotable does over the network. Both surfaces — the REST
// routes in functions/api/ and the MCP server in functions/mcp.js — call `callTool` from
// here, so they cannot drift apart.
//
// Deliberately different from webmcp.js: those tools are STATEFUL — they play the game in
// the visitor's browser, mutating score and streak. These are pure reads of the quote set,
// which is what keeps this free of a database, a session store and a Durable Object.
//
// ponytail: quotes.json is imported, not fetched. It is ~100KB of static data that ships
// in the bundle; a KV or D1 round trip would add latency and a binding to maintain for a
// file that changes when someone edits the repo.

import quotes from '../../quotes.json' with { type: 'json' };

const MAX_LIMIT = 50;
const DEFAULT_LIMIT = 10;

export class ToolError extends Error {}

// The answer is the whole point of the game, so the API hands out the question and the
// answer together — anyone can read quotes.json from the site anyway, and pretending
// otherwise would only make the API useless to an agent that wants to check itself.
const shape = (q) => ({
  quote: q.quote,
  answer: q.answer,
  options: q.options,
  year: q.year,
  genre: q.genre,
  type: q.type,
  art: q.art,
});

export const GENRES = [...new Set(quotes.map((q) => q.genre))].sort();
export const TYPES = [...new Set(quotes.map((q) => q.type))].sort();

const oneOf = (v, allowed, name) => {
  if (v === undefined || v === null || v === '') return null;
  if (typeof v !== 'string') throw new ToolError(`${name} must be a string`);
  const hit = v.trim().toLowerCase();
  if (!allowed.includes(hit)) throw new ToolError(`Unknown ${name}: ${v}. Try one of: ${allowed.join(', ')}.`);
  return hit;
};

const limitOf = (v) => {
  if (v === undefined || v === null || v === '') return DEFAULT_LIMIT;
  const n = Number(v);
  if (!Number.isInteger(n) || n < 1 || n > MAX_LIMIT) {
    throw new ToolError(`limit must be a whole number between 1 and ${MAX_LIMIT}`);
  }
  return n;
};

const filtered = (args) => {
  const genre = oneOf(args.genre, GENRES, 'genre');
  const type = oneOf(args.type, TYPES, 'type');
  return quotes.filter((q) => (!genre || q.genre === genre) && (!type || q.type === type));
};

const filterProps = {
  genre: { type: 'string', description: `Restrict to one genre: ${GENRES.join(', ')}.` },
  type: { type: 'string', description: `Restrict to one type: ${TYPES.join(', ')}.` },
};

export const TOOLS = [
  {
    name: 'list_genres',
    description: 'The genres and media types available, with how many quotes each has.',
    inputSchema: { type: 'object', properties: {} },
  },
  {
    name: 'random_quote',
    description: 'One random quote with its multiple-choice options and the correct answer.',
    inputSchema: { type: 'object', properties: filterProps },
  },
  {
    name: 'search_quotes',
    description: 'Quotes whose text, answer or options match a query.',
    inputSchema: {
      type: 'object',
      properties: {
        q: { type: 'string', description: 'Case-insensitive substring to match.' },
        limit: { type: 'integer', description: `Max results, 1-${MAX_LIMIT}. Default ${DEFAULT_LIMIT}.` },
        ...filterProps,
      },
      required: ['q'],
    },
  },
];

export const TOOL_NAMES = TOOLS.map((t) => t.name);

export function callTool(name, args = {}) {
  switch (name) {
    case 'list_genres':
      return {
        total: quotes.length,
        genres: GENRES.map((g) => ({ genre: g, count: quotes.filter((q) => q.genre === g).length })),
        types: TYPES.map((t) => ({ type: t, count: quotes.filter((q) => q.type === t).length })),
      };

    case 'random_quote': {
      const pool = filtered(args);
      // An empty pool is a real combination the caller can ask for (say drama + tv with no
      // entries); saying so beats returning `undefined` and 500ing one line later.
      if (!pool.length) throw new ToolError('No quotes match that combination of filters.');
      return shape(pool[Math.floor(Math.random() * pool.length)]);
    }

    case 'search_quotes': {
      if (typeof args.q !== 'string' || !args.q.trim()) throw new ToolError('q is required');
      const needle = args.q.trim().toLowerCase();
      const limit = limitOf(args.limit);
      const pool = filtered(args);
      const hits = pool.filter(
        (x) =>
          x.quote.toLowerCase().includes(needle) ||
          x.answer.toLowerCase().includes(needle) ||
          x.options.some((o) => o.toLowerCase().includes(needle)),
      );
      // `total` before slicing, so a caller can tell "10 of 40" from "10 of 10".
      return { query: args.q.trim(), total: hits.length, results: hits.slice(0, limit).map(shape) };
    }

    default:
      return null;
  }
}

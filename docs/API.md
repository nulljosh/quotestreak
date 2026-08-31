# Quotable API

Quotable has no HTTP API. It's a client-only game: quotes are loaded from
`quotes.json`, and all state (high score, sound settings) lives in
`localStorage` in the player's browser.

## WebMCP

`webmcp.js` registers tools via `window.modelContext` so an agent visiting
the page can read game state and play, using the same functions the UI
calls (`game.js`) — no logic is duplicated.

### Read-only

| tool | what it does |
|------|---------------|
| `get_high_score` | Returns the player's all-time high score from `localStorage`. |
| `get_game_state` | Returns whether a game is in progress, mode, score, streak, selected genre, and the current question (quote, type, options) if any. |

### Reversible writes

| tool | what it does |
|------|---------------|
| `start_game` | Starts a new game for a given genre and mode (`normal` or `timed`). Resets score/streak. |
| `answer_question` | Answers the current question with one of its option strings. |
| `next_question` | Skips to the next question. |

No tool requires `requiresConfirmation` — nothing here loses user data.
Worst case for any tool is a restarted or skipped game, which the player
(or agent) can always start again from the mode-select screen.

## HTTP API (Cloudflare Pages Functions)

Quotable now has a server surface. The WebMCP tools above still exist and are unchanged —
they *play the game* in the visitor's browser. These read the quote set instead, so an agent
can use it without loading the page.

Both surfaces call the same `callTool()` in `src/lib/tools.js`; REST and MCP cannot describe
different behaviour. `quotes.json` is imported into the bundle — there is no database.

### REST (read-only, `GET`)

| Endpoint | Returns |
|---|---|
| `/api` | The endpoint list and tool names. |
| `/api/genres` | Genres and media types, with counts. |
| `/api/random?genre=&type=` | One random quote, its options and the answer. |
| `/api/search?q=&limit=&genre=&type=` | Quotes matching a query, with a `total`. |

`/api/random` is `no-store`; everything else is cached for an hour. An unknown genre or type
is a 400 naming the valid values, not a silent empty result.

### MCP

`POST /mcp`, JSON-RPC, stateless. Tools: `list_genres`, `random_quote`, `search_quotes`.

The answer ships with the question on purpose: `quotes.json` is public on the site anyway,
and withholding it would only stop an agent from checking its own guess.

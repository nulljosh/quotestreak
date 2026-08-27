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

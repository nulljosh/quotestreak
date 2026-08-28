# Quotestreak Technical Whitepaper

**v1.7.0** | August 2026

Quotestreak is a movie-quote and music-lyric guessing game. Static site, no
build step, no backend. The product is Quotestreak everywhere — App Store,
repo and web. Only the domain (`quotable.heyitsmejosh.com`) and the
`quotable_*` localStorage keys still carry the old name; see below.

## Guessing Engine

`quotes.json` holds a hand-seeded bank of 272 entries (178 movie quotes + 94
song lyrics, all verified — no fabricated attributions) across 10 genres.
Both categories share one `answer` field, so they run through a single
guessing loop: a quote or lyric is shown, the player picks the source from
four options, and the game scores right/wrong with genre-colored feedback.
The genre dropdown is populated dynamically from `quotes.json` rather than
hardcoded, so adding a genre to the data file is enough to surface it in the
UI. A speed round puts a 10-second clock on each question and pays a
multiplier for answering fast. High score persists via `localStorage`.
Sound effects are synthesized with the Web Audio API — no bundled audio
assets — and their settings also persist in `localStorage`.

224 entries carry an optional `art` URL (TMDB posters, iTunes album covers),
resolving to 167 unique images once deduplicated by title. `art` is
advisory: `game.js` no-ops when it is absent and the native apps never use
it.

## Structure

Plain HTML/CSS/JS, no framework, no game library.

- `index.html` — landing page. Self-contained: its own inline `<style>`, no
  `style.css`, no `game.js`. Its hero is a drifting wall of poster and album
  art built at runtime from `quotes.json`, one tile per title, requested at
  thumbnail size (TMDB `w185`, iTunes `200x200`) rather than the full-size
  art the game flashes behind a question. A fetch failure leaves the plain
  hero. `game.js` must never be loaded here — it wires its handlers at parse
  time and throws if any game element id is missing.
- `play.html` / `style.css` / `game.js` — the game.
- `privacy.html` — standalone, self-styled.
- `webmcp.js` — registers five tools on `document.modelContext`
  (`get_high_score`, `get_game_state`, `start_game`, `answer_question`,
  `next_question`), exposing game state and controls to agents. Nothing is
  gated; worst case is a restarted game. See `docs/API.md`.

iOS and macOS are **native SwiftUI**, rewritten 2026-08-23 from an earlier
WKWebView shell — a wrapper is a guaranteed Guideline 4.2 rejection. They
share four sources (`Game.swift`, `ContentView.swift`, `Quote.swift`,
`Theme.swift`); `macos/project.yml` points at the iOS copies rather than
forking them, and `ContentView` branches on `#if os(macOS)`. `Game.swift` is
`@Observable` with no SwiftUI imports, so the whole game loop is testable
headless. Both ship under one Universal Purchase ASC record (6804394619) and
are live.

`quotes.json` is the only file shared between web and native; it is copied
to `ios/Quotable/Resources/quotes.json` whenever the root file changes. The
genre palette in `ios/Quotable/Theme.swift` mirrors the `--g-*` variables in
`style.css` and is kept in step by hand.

A self-check validates the bank and the scoring paths without XCTest:

```
swiftc -o /tmp/quotablecheck ios/Quotable/Quote.swift ios/Quotable/Game.swift ios/Checks/main.swift && /tmp/quotablecheck quotes.json
```

`node scripts/check-art.mjs` separately confirms every artwork URL still
resolves at both sizes.

## Design

Flat backgrounds, no emojis, no decorative border stripes, blue accent only
(no purple) — the standing no-generic-AI-UI rule. Type is San Francisco on
Apple platforms and Helvetica elsewhere, with no webfont to load.

One sanctioned exception to "no gradients": the landing page's `.hero::after`
scrim, which is a legibility mask over the artwork rather than decoration.
Without it the headline is unreadable over the wall. The game UI stays flat.

The hero wall honors `prefers-reduced-motion`, at the specificity of the
`.wall-col.up` / `.wall-col.down` rules it has to override.

## Deploy

GitHub Pages via `.github/workflows/deploy.yml`, which uploads the repo root
verbatim — there is no build step and no `dist/`. Custom domain from `CNAME`.

## Security / Privacy

Fully static, no accounts, no backend, no analytics. All state (high score,
settings) lives in the browser's `localStorage` only. The web pages load
poster and album art from third-party image hosts; the native apps bundle
the bank and use no artwork, so they make no network requests at all.

## License

MIT 2026, Joshua Trommel

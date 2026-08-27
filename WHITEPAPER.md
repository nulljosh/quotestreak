# Quotable Technical Whitepaper

**v1.5.0** | August 2026

Quotable is a movie-quote and music-lyric guessing game. Static site, no
build step, no backend.

## Guessing Engine

`quotes.json` holds a hand-seeded bank (143 movie quotes + 50 music-trivia
entries, all verified — no fabricated attributions) under a shared `answer`
field so both categories run through one guessing loop: a quote/lyric is
shown, the player guesses the source, and the game scores right/wrong with
genre-colored feedback. The genre dropdown is populated dynamically from
`quotes.json` rather than hardcoded, so adding a genre to the data file is
enough to surface it in the UI. High score persists via `localStorage`.
Settings (sound effects, volume) are synthesized with the Web Audio API — no
bundled audio assets — and also persist in `localStorage`.

## Structure

Plain HTML/CSS/JS, no framework, no chart/game library. iOS and macOS ship
under one Universal Purchase ASC record (6804394619). `ios/` and `macos/`
are thin WKWebView/`NSViewRepresentable` wrappers that bundle literal copies
of the root `index.html`/`style.css`/`game.js`/`quotes.json` as resources
(not symlinked, not built) — the four files must be re-copied into both
`Resources/` dirs whenever the root web files change. Both native wrappers
are scaffolds only, not yet built/signed.

## Design

Full-viewport layout, flat backgrounds (no gradients), no emojis, blue accent
only (no purple), matching the standing no-generic-AI-UI rule.

## Deploy

GitHub Pages via `.github/workflows/deploy.yml`.

## Security / Privacy

Fully static, no accounts, no backend. All state (high score, settings) lives
in the browser's `localStorage` only.

## License

MIT 2026, Joshua Trommel

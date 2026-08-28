<img src="icon.svg" width="80" style="border-radius:18px">

# Quotestreak

![version](https://img.shields.io/badge/version-1.7.0-blue) ![license](https://img.shields.io/badge/license-MIT-green) [![GitHub](https://img.shields.io/badge/GitHub-nulljosh%2Fquotestreak-black?logo=github)](https://github.com/nulljosh/quotestreak)

Guess the movie or artist from a quote. Multiple choice, plus a 10-second speed round with a score multiplier for fast answers. 272 entries (178 movie quotes + 94 song lyrics) across 10 genres.

Credits to dad for the idea.

## Run

```
python3 -m http.server
```

Open `http://localhost:8000`.

## Structure

- `index.html` — landing page (self-contained; hero is a drifting wall of poster/album art built from `quotes.json`)
- `play.html` / `style.css` / `game.js` — game
- `quotes.json` — quote bank (`type: movie|music`, `genre`, `quote`, `answer`, `options`)
- `ios/` — native SwiftUI app, published on the App Store as **Quotestreak**
- `macos/` — native SwiftUI, shares the iOS sources; built, not yet submitted

## Roadmap

- **App Store**: iOS shipped as Quotestreak (native SwiftUI rewrite). `macos/` is still a WKWebView wrapper and must be rewritten native before it can be submitted.
- **Music sources**: current 50 lyric entries are hand-seeded. Could pull real metadata (song/artist pairs) from the free, keyless iTunes Search API (`itunes.apple.com/search`) to grow the bank without manually authoring more trivia.
- **Quote bank growth**: same hand-seeding approach could scale movie quotes further via a free quotes API (e.g. movie-quote datasets on GitHub) if a larger bank is wanted.

## License

MIT 2026, Joshua Trommel

## Whitepaper

[Technical whitepaper](WHITEPAPER.md)

## API and agent tools

Quotestreak exposes its game state and controls to agents via WebMCP. See [docs/API.md](docs/API.md).

## Architecture

<img src="architecture.svg" width="600">

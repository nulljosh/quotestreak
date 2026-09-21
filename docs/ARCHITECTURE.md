# Architecture

Quotestreak is a movie and music trivia guessing game. Guess the source from a famous quote or lyric; correct answers build streaks, speed round adds time pressure. No backend, no accounts (web is local-only). iOS/macOS native apps support sign-in and leaderboards via Supabase. Deployed as a static site (GitHub Pages) and native apps.

## How it runs

Web app: `play.html` loads `game.js` and `style.css`. On page load, `game.js` fetches `quotes.json` (hand-seeded, 143 movie quotes + 50 music lyric entries) and `buildBackdrop()` generates a static mosaic backdrop from artwork. `Game` class (ported from Swift) manages state: current quote, answer options, score, streak. User sees four answer buttons, clicks one, script evaluates correctness and updates the score. Speed Round adds a 10-second countdown. High score persists via localStorage. `index.html` is the marketing landing page; no game markup there, game.js only runs on play.html.

iOS/macOS apps: native SwiftUI apps. `Game.swift` implements the game loop (ported from game.js), independent of any view framework, so it is testable headless. `ContentView.swift` wraps it, showing menu/round/game-over UI. `Quote.swift` decodes the shared quotes.json. `Theme.swift` holds the genre palette (mirrored from style.css). On iOS, users can sign in via Apple or Google (via Supabase OAuth); leaderboard reads/writes go to the shared spark database. Accounts are stored in Supabase Auth; account deletion calls the shared `delete-account` Edge Function.

## Files

| File | What it owns |
|---|---|
| `index.html` | Marketing landing page: hero wall of artwork, features, app store links, no game markup |
| `play.html` | Game interface: current quote display, four answer buttons, score/streak/timer, feedback animations, backdrop mosaic |
| `game.js` | Game loop (ported from Swift): quote shuffling, scoring logic, streak calculation, speed-round timer, Web Audio synthesis for SFX, localStorage persistence, backdrop building |
| `style.css` | Game UI styling: layout, colors per genre (drama/action/comedy/sci-fi/romance), flat backgrounds, animations |
| `quotes.json` | Quote bank: array of `{genre, answer, options, year}` objects; 143 movies + 50 music entries; used by web and native apps |
| `webmcp.jsx` | WebMCP tool registration for in-browser agents (not deployed to Pages, used by app testing) |
| `icon.svg` | Pure geometry: two stylized quote marks as paths on a rounded square; 200px viewBox; no text, no font dependency |
| `.github/workflows/deploy.yml` | GitHub Actions: deploy static site to GitHub Pages on push |
| `ios/Quotable/Game.swift` | Observable game state and logic: quote rotation, scoring, streak calculation, speed-round timer; testable headless |
| `ios/Quotable/ContentView.swift` | SwiftUI view hierarchy: menu screen, round in-play, game-over, score display, timer ring, answer reveal animation |
| `ios/Quotable/Quote.swift` | Codable Quote struct: genre, answer, options, year; decodes from shared quotes.json |
| `ios/Quotable/Theme.swift` | Genre palette: colors for drama/action/comedy/sci-fi/romance/pop/rock/hiphop/rnb/country; mirrors style.css |
| `ios/Quotable/SharedStore.swift` | Observation model for leaderboard and profile state (shared with macOS) |
| `ios/Quotable/Account.swift` | Sign-in/out via Apple (GoTrue REST) and Google (Supabase OAuth, quotable:// redirect); leaderboard read/write; account deletion via shared delete-account function |
| `ios/QuotableApp.swift` | iOS app entry: window group, profile overlay |
| `ios/Checks/main.swift` | Self-check (no XCTest): validates quotes.json structure (4 options, answer present, no duplicates, movie years), scoring paths (streaks, speed multiplier, timeout-as-miss) |
| `ios/Assets.xcassets/` | AppIcon (1024px, square, no alpha, corners not rounded; iOS applies its own mask) |
| `macos/QuotableApp.swift` | macOS app entry: window group with min size |
| `macos/project.yml` | XcodeGen: points shared source files at ../ios/Quotable/{Game,Quote,Theme,ContentView}.swift; ContentView branches on #if os(macOS) |
| `macos/Assets.xcassets/` | AppIcon set (16/32/64/128/256/512/1024, rounded corners baked in) |
| `watchos/` | watchOS companion app: syncs game state from iOS app Group container, shows score/streak/phase, no active gameplay |
| `watchos/QuotableWatchApp.swift` | watchOS app entry point with window group |
| `watchos/Models/WatchModels.swift` | QuotestreakSummary struct mirroring iOS SharedStore payload from the shared App Group |
| `watchos/Models/WatchAPI.swift` | Reads shared App Group container (`group.com.heyitsmejosh.quotable`) to fetch synced game state |
| `watchos/Views/StreakGlance.swift` + `SyncInfoView.swift` | Display current score, streak, and game phase; timestamp of last sync from iPhone |
| `Package.swift` + `tui/` | SwiftPM target for macOS command-line player (TUI, non-interactive, reads quotes.json and renders one round) |
| `i18n.js` | Runtime i18n loader: detects user language, fetches locale JSON, replaces `[data-i18n]` attributes, exposes `t()` for dynamic strings |
| `i18n/strings.json` | Master translation file with `_meta` specifying source language and supported locales; source of truth for web and iOS |
| `scripts/i18n-gen.mjs` | Generates `locales/*.json` from `i18n/strings.json` for the web, and `ios/Quotable/Localizable.xcstrings` for SwiftUI |
| `locales/` | Generated per-language JSON files (en, fr, zh, pa); populated by i18n-gen.mjs |
| `auth.js` | Sign-in/out, account creation, leaderboard fetch/submit via Supabase REST client (web-only, native apps use Account.swift) |
| `devices.css` | Device frame styling: realistic iPhone/Android/Mac/Windows shells for landing page demo screens |
| `privacy.html` | Privacy policy page: static HTML, linked from landing page footer |
| `sw.js` | Service Worker: network-first caching for HTML pages (page load time versioning), cache-first for hashed assets |
| `functions/mcp.js` | MCP server (JSON-RPC over HTTP): exposes game tools as MCP resources for agent visitors |
| `functions/api/[[route]].js` | REST router: thin wrapper around callTool() in src/lib/tools.js, handles CORS, routes requests to tool implementations |
| `src/lib/tools.js` | Single source of truth for all quote filtering tools (by genre, by type, search, limit, validation); called by both REST and MCP surfaces |
| `src/lib/tools.test.mjs` | Node test for tools.js validation: filters quotes by genre/type, checks error cases |
| `quotes.test.js` | Validation suite (node --test): checks quote bank structure (4 unique options, correct answer, no duplicates, movie years), scoring paths |
| `scripts/build-site.sh` | Fetches quotes.json, generates locales, concatenates CSS/JS bundles for deployment |
| `scripts/check-art.mjs` | Validates artwork against quotes.json (presence, format) |
| `scripts/fetch-tmdb-art.mjs` + `fetch-itunes-art.mjs` | Tools for populating artwork URLs for movie and music entries (run offline, feeds art URLs into quotes.json) |
| `kmp/` | Kotlin Multiplatform: Android/desktop clients reading static quotes.json from the web; QuotestreakClient in commonMain fetches and deserializes quotes |
| `kmp/composeApp/src/commonMain/kotlin/com/nulljosh/quotestreak/AppScreen.kt` | Shared game UI (Compose Multiplatform) for Android and desktop |
| `kmp/composeApp/src/androidMain/kotlin/com/nulljosh/quotestreak/MainActivity.kt` | Android entry point, activity setup |
| `kmp/composeApp/src/desktopMain/kotlin/com/nulljosh/quotestreak/Main.kt` | Desktop (JVM) entry point, window setup |
| `manifest.webmanifest` | PWA manifest: app name, icons, start URL, display mode |

## Quote bank structure

`quotes.json` is an array of objects. Each object has:
- `genre`: one of movie, music, or other categories
- `answer`: the source (movie title + year, artist name, etc)
- `options`: array of 4 strings (the correct answer plus 3 distractors)
- `year`: (movies only) release year for display

The web app shuffles options per question. iOS/macOS mirror this logic in Game.swift.

## Scoring

- Correct answer: +1 point, streak +1
- Wrong answer: streak = 0
- Speed Round: correct answer within 10 seconds = +1 point + add 1 second to the countdown (max 10), speeds up over a streak. Timeout = miss (streak broken, no points).

Implemented identically in game.js and Game.swift to ensure parity.

## Sound effects

Web app generates SFX via Web Audio API (no audio asset files). Correct/wrong/timeout have different tones. Synthesized on first use and cached. Toggle and volume controlled via Settings panel, persisted in localStorage.

## Gotchas

- localStorage keys and window globals must stay `quotable_*` and `window.quotable*` respectively, even though the product is "Quotestreak". Renaming silently wipes existing high scores and breaks agent tools.
- Button feedback uses `.allowsHitTesting(false)` (iOS) instead of `.disabled()`, because disabled buttons render with washed-out tint, hiding the green/red correct/wrong reveal.
- The backdrop is static (not drifting like the landing page hero wall) because the speed round is a timed attention task; motion would fight the clock.
- macOS sources are shared with iOS via XcodeGen symlinks. Four files (Game, Quote, Theme, ContentView) must stay in sync. Do not fork them for macOS.
- The bundle id `com.heyitsmejosh.quotable` is bound to ASC record 6804394619 and must never change; changing it means a new app record.

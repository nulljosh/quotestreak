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

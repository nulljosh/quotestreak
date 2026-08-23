# Quotable

Movie-quote guessing game. Static site, no build step, no backend.

## Stack
Plain HTML/CSS/JS. Quote bank in `quotes.json` (100 hand-seeded quotes — see root roadmap.md for plan to pull from a real quotes API). High score persisted via localStorage. Genre-colored badges/icons and correct/wrong feedback animations added in v1.1.0. v1.2.0: full-viewport layout, larger type/spacing, per-genre badge text color (fixes low-contrast text on drama/sci-fi badges), flat backgrounds (no gradients), quote bank doubled to 100. v1.3.0: quote bank to 143 (verified, no fabricated attributions), stronger accent color (panel left border, deeper bg tint), auto light/dark only (toggle removed), 100dvh mobile fix. v1.4.0: settings panel (gear icon) — sound effects toggle + volume slider, synthesized via Web Audio API (no audio assets), persisted in localStorage. Profiles/accounts (Supabase) deferred — not yet implemented. v1.4.1: removed decorative purple left-border accent stripe on panel, replaced purple accent2 (Speed Round button) with blue to match the rest of the palette. v1.4.2: removed all emojis from UI copy (genre badges, feedback text, settings button) per standing no-generic-AI-UI rule (no border stripes, no purple, no gradients, no emojis). v1.5.0: added 50 music trivia entries (lyric → artist, genres pop/rock/hiphop/rnb/country), renamed `movie` field to `answer` across quotes.json to support both categories, genre dropdown now populated dynamically from quotes.json instead of hardcoded. Rebuilt header as a full-width sticky top nav; widened content to 720px max-width. v1.5.1: the "icon only, no wordmark" call was wrong — icon.svg sets its "QUOTE" lettering at font-size 24 in a 200px viewBox, so at a 32-36px render it is ~4px tall and unreadable. The header now pairs the mark with a real HTML wordmark ("Quotable"); do not remove it again. Also tightened stacked bottom padding (panel 40->28, wrap 40->20/24) that left ~80px dead below the answers; `#feedback`'s min-height is deliberate and stays, it reserves the answer-feedback line so the layout doesn't jump.

## iOS/macOS sync
**iOS is a native SwiftUI app now, not a web wrapper.** The only file shared with the web game is `quotes.json` — copy it to `ios/Quotable/Resources/quotes.json` whenever the root one changes, and nothing else. The genre palette in `ios/Quotable/Theme.swift` mirrors the `--g-*` vars in `style.css`; keep the two in step by hand.

`macos/Quotable/Resources/` is still the old WKWebView wrapper and still takes plain copies of `index.html`/`style.css`/`game.js`/`quotes.json`. It is unbuilt and unshipped — see the App Store section.

## Deploy
GitHub Pages via `.github/workflows/deploy.yml` (Settings → Pages → Source: GitHub Actions).

## iOS
`ios/` — native SwiftUI, rewritten 2026-08-23 from the old WKWebView shell (a wrapper is a guaranteed Guideline 4.2 rejection; see the 5.6 suspension history). Four files:

- `Game.swift` — the whole game loop ported from `game.js`: scoring, streaks, the speed-round clock. `@Observable`, no SwiftUI imports, so it is testable headless.
- `ContentView.swift` — menu / round / game-over, plus the timer ring and the answer reveal.
- `Quote.swift` — decodes the shared `quotes.json`.
- `Theme.swift` — genre palette mirroring `style.css`.

Answer buttons deliberately use `.allowsHitTesting(false)` rather than `.disabled(true)` after a pick — a disabled button renders its tint washed out, which hides the green/red reveal.

Self-check (no XCTest, no framework):

```
swiftc -o /tmp/quotablecheck ios/Quotable/Quote.swift ios/Quotable/Game.swift ios/Checks/main.swift && /tmp/quotablecheck quotes.json
```

It validates the whole quote bank (4 unique options, answer present, no duplicate quotes, movies have years) and the scoring paths (streaks, the speed multiplier, timeout-as-miss).

## App Store
Listed as **Quotestreak** (app id `6804394619`, bundle `com.heyitsmejosh.quotable`) — "Quotable", "Quotely", "Quipster", "Recite" and "Cueline" are all taken by other accounts. The repo, the web game and `quotable.heyitsmejosh.com` keep the Quotable name; only the store listing and the on-device display name are Quotestreak.

Ship with `asc workflow run ship-ios VERSION:x.y.z` (see `.asc/workflow.json`).

## macOS
`macos/` — still the old AppKit/WKWebView wrapper. **Do not submit it as-is**; it would be rejected under 4.2 for the same reason the iOS wrapper would have been. Mirror the native iOS rewrite first.

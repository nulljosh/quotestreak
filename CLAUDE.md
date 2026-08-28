# Quotestreak

Movie-quote guessing game. Static site, no build step, no backend.

## Stack
Plain HTML/CSS/JS. Quote bank in `quotes.json` (100 hand-seeded quotes — see root roadmap.md for plan to pull from a real quotes API). High score persisted via localStorage. Genre-colored badges/icons and correct/wrong feedback animations added in v1.1.0. v1.2.0: full-viewport layout, larger type/spacing, per-genre badge text color (fixes low-contrast text on drama/sci-fi badges), flat backgrounds (no gradients), quote bank doubled to 100. v1.3.0: quote bank to 143 (verified, no fabricated attributions), stronger accent color (panel left border, deeper bg tint), auto light/dark only (toggle removed), 100dvh mobile fix. v1.4.0: settings panel (gear icon) — sound effects toggle + volume slider, synthesized via Web Audio API (no audio assets), persisted in localStorage. Profiles/accounts (Supabase) deferred — not yet implemented. v1.4.1: removed decorative purple left-border accent stripe on panel, replaced purple accent2 (Speed Round button) with blue to match the rest of the palette. v1.4.2: removed all emojis from UI copy (genre badges, feedback text, settings button) per standing no-generic-AI-UI rule (no border stripes, no purple, no gradients, no emojis). v1.5.0: added 50 music trivia entries (lyric → artist, genres pop/rock/hiphop/rnb/country), renamed `movie` field to `answer` across quotes.json to support both categories, genre dropdown now populated dynamically from quotes.json instead of hardcoded. Rebuilt header as a full-width sticky top nav; widened content to 720px max-width. v1.5.1: the "icon only, no wordmark" call was wrong — icon.svg sets its "QUOTE" lettering at font-size 24 in a 200px viewBox, so at a 32-36px render it is ~4px tall and unreadable. The header now pairs the mark with a real HTML wordmark ("Quotable"); do not remove it again. Also tightened stacked bottom padding (panel 40->28, wrap 40->20/24) that left ~80px dead below the answers; `#feedback`'s min-height is deliberate and stays, it reserves the answer-feedback line so the layout doesn't jump.

## iOS/macOS sync
**iOS is a native SwiftUI app now, not a web wrapper.** The only file shared with the web game is `quotes.json` — copy it to `ios/Quotable/Resources/quotes.json` whenever the root one changes, and nothing else. The genre palette in `ios/Quotable/Theme.swift` mirrors the `--g-*` vars in `style.css`; keep the two in step by hand.

macOS shares the iOS sources outright: `macos/project.yml` points at `../ios/Quotable/{Game,Quote,Theme,ContentView}.swift`. Do not fork those four files — `ContentView` branches on `#if os(macOS)` and `Theme.canvas` picks the right window ground per platform. Only `QuotableApp.swift`, `Info.plist` and `Resources/quotes.json` are macOS-local.

## Pages
`index.html` is the **landing page**, `play.html` is the game. (Before v1.7.0 the game was at `index.html`.) The landing page is self-contained — its own inline `<style>`, no `style.css`, no `game.js`. Keep it that way: `game.js` wires its handlers at parse time and throws if any game element id is missing, so it must never be loaded on a page without the full game markup.

The landing page mirrors the Bookrank landing page (`nulljosh/bookrank` `index.html`) on purpose — same hero/features/closing structure, same drifting image wall. Two deliberate differences from that reference: album art is tagged `.square` (`aspect-ratio: 1/1`) so 1:1 iTunes art is not center-cropped into a 2:3 poster shape, and the reduced-motion rule is written as `.wall-col.up, .wall-col.down` — at the bare `.wall-col` specificity Bookrank uses, the `animation` shorthand on `.wall-col.up` wins and the wall keeps moving for users who asked it not to.

The hero wall is the one sanctioned exception to the standing "no gradients" rule: `.hero::after` is a legibility scrim over the art, not decoration. The game UI keeps flat backgrounds.

## Icon
`icon.svg` is **pure geometry — no `<text>`, no font dependency** (2026-08-28). It is two opening quote marks drawn as paths on a dark rounded square, matching the orientation of the icon already live on the App Store.

It used to set a `"` glyph and the word `QUOTE` in Menlo as two `<text>` elements. That is why the v1.5.1 note below says the lettering renders ~4px tall at icon size — that specific reasoning is now moot, but **its conclusion still stands: keep the HTML wordmark in the topbar.** A bare quote mark does not name the product, so the mark and the wordmark ship together. Do not drop the wordmark and do not put text back in the icon.

App icons are generated from `icon.svg`, not hand-exported (hand-exporting is what left the old shipped iOS icon floating in the top third of its canvas):

- iOS `ios/Assets.xcassets/AppIcon.appiconset/AppIcon.png` — 1024, **square, corners NOT rounded**; iOS applies its own mask, so baked corners would be double-rounded.
- macOS `macos/Assets.xcassets/AppIcon.appiconset/icon_{16,32,64,128,256,512,1024}.png` — rounded corners baked in, which macOS expects.

All of them must be **opaque, no alpha channel** — Apple rejects an app icon carrying one (ITMS-90717). Regenerating them here changes only the repo; the store listings keep the old icon until a new build is submitted.

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
Listed as **Quotestreak** (app id `6804394619`, bundle `com.heyitsmejosh.quotable`) — "Quotable", "Quotely", "Quipster", "Recite" and "Cueline" are all taken by other accounts.

**The product is Quotestreak everywhere** (2026-08-28). The web game used to keep the Quotable name while only the store listing was Quotestreak; that split is gone — every user-facing string on the site now reads Quotestreak. Three things deliberately still say "quotable" and must NOT be renamed:

- `CNAME` / `quotable.heyitsmejosh.com` — the live domain. Changing it is a DNS move, not a rename.
- `quotable_high_score`, `quotable_sfx_on`, `quotable_sfx_vol` — localStorage keys on players' machines. Renaming them silently wipes every existing high score and sound setting.
- `window.quotable*` — the globals `webmcp.js` binds to. Renaming breaks the agent tools for nothing.

The bundle id `com.heyitsmejosh.quotable` is likewise fixed; it is bound to ASC record 6804394619, and changing it means a new app record, not a rename.

Ship with `asc workflow run ship-ios VERSION:x.y.z` (see `.asc/workflow.json`).

## macOS
`macos/` — native SwiftUI, rewritten 2026-08-23 off the same shared sources as iOS. Sandboxed, bundle `com.heyitsmejosh.quotable.mac`. Builds clean.

**Shipped.** The "not submitted yet, deliberately / no ASC record exists" note here was stale — `roadmap.md` records iOS 1.0 and macOS 1.0 both APPROVED and live as of 2026-08-23 on the shared Universal Purchase record 6804394619. The landing page links both store pages (`?mt=12` for Mac); if either listing is ever pulled, drop the matching hero button.

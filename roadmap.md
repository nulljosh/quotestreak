# Quotable Roadmap

## macOS — native SwiftUI rewrite complete, blocked on icon + screenshots
`macos/` was rewritten to native SwiftUI 2026-08-23, sharing iOS sources via xcodegen
(`macos/project.yml` compiles `../ios/Quotable/{Game,Quote,Theme,ContentView}.swift`). Only
`QuotableApp.swift`, `Info.plist`, and `Resources/quotes.json` are macOS-local. Sandboxed,
bundle `com.heyitsmejosh.quotable` (Universal Purchase, same record as iOS 6804394619).
Metadata pushed to ASC.

**Version status:** MAC_OS 1.0 PREPARE_FOR_SUBMISSION (on shared iOS record 6804394619,
not a separate record — avoids the 5.6 "bulk new thin apps" trigger). Blocked by `asc validate --platform MAC_OS`:
`build.required.missing` (ICNS icon export must include 512pt@2x; single iOS 1024 is not sufficient
for Mac App Store), and `screenshots.required.any` (need window-ID-based screencapture to capture
in-round states; deferred, session usage ran out).

## Localization
The web game has en/fr/zh/pa in `locales/`. The iOS app is English-only — porting four locales to
a String Catalog was skipped for 1.0. Add `Localizable.xcstrings` if there is real demand.

## Quote bank
272 entries (178 movie, 94 music). Movie art backfills via
`TMDB_API_KEY=... node scripts/fetch-tmdb-art.mjs`; music `art` uses iTunes Search URLs. `art` is
optional — `game.js` no-ops when absent and the iOS app never uses it.

Remaining gaps from the original dad-pass note: spaghetti westerns beyond The Good, the Bad and
the Ugly; more Merle Haggard / Waylon Jennings on the country side.

Run the self-check after any bank edit — it catches duplicate quotes, which the bank had 32 of
before 2026-08-23:

```
swiftc -o /tmp/quotablecheck ios/Quotable/Quote.swift ios/Quotable/Game.swift ios/Checks/main.swift && /tmp/quotablecheck quotes.json
```

## Ideas, unscheduled
- Game Center leaderboard for the speed round. Deliberately skipped for 1.0 — content depth was
  the cheaper answer to 4.2 than a new subsystem.
- Grow the bank from a free quotes dataset rather than hand-seeding.

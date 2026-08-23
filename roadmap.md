# Quotable Roadmap

## macOS — native SwiftUI rewrite complete, awaiting iOS review
`macos/` was rewritten to native SwiftUI 2026-08-23, sharing iOS sources via xcodegen
(`macos/project.yml` compiles `../ios/Quotable/{Game,Quote,Theme,ContentView}.swift`). Only
`QuotableApp.swift`, `Info.plist`, and `Resources/quotes.json` are macOS-local. Sandboxed,
bundle `com.heyitsmejosh.quotable.mac`. Builds clean.

**Not submitted yet.** No ASC record exists. A second brand-new thin-looking app in the same
review window is the 5.6 trigger pattern, so submission waits until the iOS listing clears review.

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

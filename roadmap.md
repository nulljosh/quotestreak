# Quotable Roadmap

## App Store status
Both iOS and macOS v1.0 are **WAITING_FOR_REVIEW** on the shared Universal Purchase record 6804394619.
Blockers solved: generated full ICNS appiconset with 512pt@2x (Mac App Store requirement exceeds iOS),
captured macOS screenshots via CGWindowListCopyWindowInfo window ID lookup (no AppleScript
System Events). Both submitted 2026-08-23 (iOS build 202608230326, macOS build 202608230338).

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

## WebMCP + REST API rollout -- shipped 2026-08-27

Done. 5 tools: `get_high_score`, `get_game_state`, `start_game`,
`answer_question`, `next_question`. Nothing gated -- worst case is a
restarted game.

See `docs/API.md` for the full tool table, linked from the README.

## From Apple Notes (imported 2026-08-27)
- [ ] Quotestreak iOS 1.0 and macOS 1.0 both APPROVED and live (id6804394619) as of Aug 23 2026.
- [x] Landing page shipped 2026-08-28 at `index.html`; the game moved to `play.html`. iOS and Mac apps are live.
- [ ] Add dad's idea and expand/extrapolate on it (ask Joshua to restate the idea).

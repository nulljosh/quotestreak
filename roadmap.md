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

## WebMCP + REST API rollout (pending, 2026-08-27)

Add `document.modelContext` tool registration so in-browser agents can drive
this app, and document any HTTP surface it already has.

Pattern is already shipped in epiphany, healstack, roost, curvely, wiretext,
litigate, cadence, sparkjar and lexly — copy the closest one:

- React app with hooks → `src/lib/webmcp.js` exporting `useWebMCP(ctx)`, called
  from `App.jsx` with the hook callbacks it already holds (see epiphany, curvely).
- React app whose state lives in contexts → a `<WebMCP />` component that reads
  those contexts (see healstack, roost).
- Vanilla JS app → a `webmcp.js` IIFE plus `window.*` accessors exported from the
  existing app script (see litigate, lexly, sparkjar).

Rules the shipped ones follow:
- Tools call existing functions or existing `/api` routes. Never reimplement logic.
- Read-only tools first, then reversible writes.
- `requiresConfirmation: true` only on the genuinely consequential ones —
  payments, public publishing, deletions. Not on ordinary writes.
- Bail out quietly when `document.modelContext` is missing.
- Ship a `docs/API.md` listing REST routes (or stating there are none) plus the
  tool table split into read-only / reversible / confirmation-gated.

## From Apple Notes (imported 2026-08-27)
- [ ] Quotestreak iOS 1.0 and macOS 1.0 both APPROVED and live (id6804394619) as of Aug 23 2026.
- [ ] Quotable still needs a landing page plus iOS and Mac apps.
- [ ] Add dad's idea and expand/extrapolate on it (ask Joshua to restate the idea).

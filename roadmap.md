# Quotable Roadmap

- [ ] Verify iPad layout visually on simulator -- 2026-09-02. `TARGETED_DEVICE_FAMILY = "1,2"`
  already set; iOS `ContentView` uses `NavigationStack` with flexible frames throughout
  (only card/button-level fixed widths, not page-level), so it should scale reasonably, but
  nobody has actually seen it on an iPad screen. This machine's Xcode only has the iOS 26.5
  SDK with the iOS 26.2 runtime downloaded, so `xcodebuild` won't recognize any simulator
  destination even by explicit UDID -- needs the matching platform component installed,
  then a screenshot check (menu, round, game-over, speed-round clock).

## TODO, next time you are at a real Mac

Left over from the 2026-09-01 art-flash fix. None of it can run in a Claude Code web
session (no Swift toolchain; TMDB/iTunes/mzstatic are refused by the egress policy).

- [ ] `TMDB_API_KEY=... node scripts/fetch-tmdb-art.mjs`, the 3 remaining movie-side
      gaps are TV series; the script now falls through to /search/tv.
- [ ] `node scripts/check-art.mjs`, confirm nothing 404s.
- [ ] Copy `quotes.json` to `ios/Quotable/Resources/quotes.json`. It does not sync itself.
- [ ] Build iOS + macOS. `ArtLoader` in `ContentView.swift` has never been compiled.
- [ ] Ship as 1.2: `asc workflow run ship-ios VERSION:1.2.0`.

## App Store status
1.1 (2026-08-31) brings the native apps to parity with the web game: sound effects with a volume
slider, the album/poster art flash on a correct answer, the points earned in the feedback line,
the four locales, and the correct share URL (it pointed at the dead github.io page).

v1.0 is **READY_FOR_SALE** on both platforms. v1.1 (the web-parity release) was submitted
2026-08-31 on the shared Universal Purchase record 6804394619; **macOS is APPROVED** (review
completed 2026-09-01, submission 47cc07eb-4fec-46e6-aac0-658d45e49ffc), iOS still in review.

The art-flash reliability fixes are **not in the 1.1 builds**, they land in 1.2. In 1.1 the
flash often does not appear: the native `ArtFlash` only started its fetch once the answer was
picked, giving it under a second to pull a full-size poster, and back-to-back correct answers
let the previous dismiss timer cancel the new flash. Both are fixed on the branch, unbuilt.
Blockers solved: generated full ICNS appiconset with 512pt@2x (Mac App Store requirement exceeds iOS),
captured macOS screenshots via CGWindowListCopyWindowInfo window ID lookup (no AppleScript
System Events). Both submitted 2026-08-23 (iOS build 202608230326, macOS build 202608230338).

## Localization
One source, `i18n/strings.json`, generates both `locales/*.json` (web) and
`ios/Quotable/Localizable.xcstrings` (iOS + macOS) via `node scripts/i18n-gen.mjs`. en/fr are
complete; zh/pa cover 8 of 22 keys and fall back to English for the rest.

## Quote bank
272 entries (178 movie, 94 music). Movie art backfills via
`TMDB_API_KEY=... node scripts/fetch-tmdb-art.mjs`; music `art` uses iTunes Search URLs. `art` is
optional, both `game.js` and the native `ArtFlash` no-op when absent, which is exactly the
problem: 48 entries (45 music, 3 movie) have no `art`, so ~18% of correct answers flash nothing.
Close that with `node scripts/fetch-itunes-art.mjs` (music, no API key) and a re-run of
`fetch-tmdb-art.mjs` (the 3 stragglers are TV series, and the script now falls through to
TMDB's /search/tv, which is why /search/movie never matched them). Both need network, so
neither runs in a Claude Code web session.

Remaining gaps from the original dad-pass note: spaghetti westerns beyond The Good, the Bad and
the Ugly; more Merle Haggard / Waylon Jennings on the country side.

Run the self-check after any bank edit, it catches duplicate quotes, which the bank had 32 of
before 2026-08-23:

```
swiftc -o /tmp/quotablecheck ios/Quotable/Quote.swift ios/Quotable/Game.swift ios/Checks/main.swift && /tmp/quotablecheck quotes.json
```

## Ideas, unscheduled
- Game Center leaderboard for the speed round. Deliberately skipped for 1.0, content depth was
  the cheaper answer to 4.2 than a new subsystem.
- Grow the bank from a free quotes dataset rather than hand-seeding.

## WebMCP + REST API rollout -- shipped 2026-08-27

Done. 5 tools: `get_high_score`, `get_game_state`, `start_game`,
`answer_question`, `next_question`. Nothing gated -- worst case is a
restarted game.

See `docs/API.md` for the full tool table, linked from the README.

## /api + /mcp blocked on hosting

Cannot ship Cloudflare Pages Functions here: quotable.heyitsmejosh.com serves from GitHub
Pages (`server: GitHub.com`), and there is no `quotestreak` Cloudflare Pages project. The
`random_quote` / `list_tags` pair is ready to write against quotes.json the moment the site
moves to Pages, see conway (2026-08-31) for the template. Migrating hosting is the
prerequisite, not the endpoint work.
# Roadmap

> Everything above about the API being blocked on hosting is SUPERSEDED by the section
> below: the move to Cloudflare Pages happened on 2026-08-31 and the endpoints are live.

## /api + /mcp surface, SHIPPED 2026-08-31

Live at `quotable.heyitsmejosh.com/api` and `/mcp`. Tools: `list_genres`, `random_quote`,
`search_quotes`, all reading `quotes.json` out of the bundle. Both surfaces call `callTool()`
in `src/lib/tools.js`. Check: `node src/lib/tools.test.mjs`.

The blocker was the host, not the code: the site was on GitHub Pages, which runs no
Functions. It now lives on the Cloudflare Pages project `quotestreak`,
quotable.heyitsmejosh.com repointed, and GitHub Pages plus its deploy workflow are gone so
there is exactly one live site. Deploy with `sh scripts/build-site.sh && npx wrangler pages
deploy` from the repo root, wrangler needs the root for `functions/`, and `dist/` is the
web subset (the repo root also holds ios/, macos/, metadata/).

Pages serves extensionless URLs, so `/play.html` now 308s to `/play`. Old links still work.

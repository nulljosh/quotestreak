#!/bin/sh
# ponytail: the site is the repo root, but the repo also holds ios/, macos/, metadata/ and
# screenshots/. Copy the web subset into dist/ so a Pages deploy ships the site and nothing
# else. functions/ stays at the root — wrangler picks it up from there, not from dist/.
set -e
cd "$(dirname "$0")/.."
rm -rf dist && mkdir -p dist
cp index.html play.html privacy.html style.css game.js i18n.js webmcp.js sw.js \
   manifest.webmanifest quotes.json vibe.json icon.svg icon-192.png icon-512.png \
   icon-512-maskable.png architecture.svg dist/
cp -R locales dist/
mkdir -p dist/screenshots
cp -R screenshots/web dist/screenshots/
echo "built dist/"

# ScoringSpades

A clean, mobile-first scorekeeper for the card game Spades. Live at **[scoringspades.com](https://scoringspades.com)**.

## What it does

- 2 teams of 2, bid-by-team, standard Spades scoring
- Nil and blind nil support per-player
- Automatic bag tracking with the −100 penalty at every 10 bags
- Round-by-round history with per-round deltas
- Persists your game in `localStorage` — close the tab, come back, pick up where you left off
- Configurable target score (250 / 300 / 500 / custom)
- Installable to iOS home screen (PWA-style meta tags, safe-area handled), plus a native iPhone & iPad app in `ios/`

## Tech

A single `index.html` file (~50 KB). No build step, no dependencies, no framework. Vanilla JS with a tiny custom render helper. A companion `how-to-play.html` page covers the rules. Hosted as a Cloudflare Worker with the Static Assets binding; `_headers` sets the security headers (CSP, HSTS, etc.).

## iPhone & iPad app

`ios/` has a fully native SwiftUI version of the scorekeeper, with the same rules, settings, tips, and How to Play guide. See [ios/README.md](ios/README.md) to build, test, and release it.

## Run locally

Just open `public/index.html` in any modern browser. There's no server required for development. If you want a real local URL, the easiest option is:

```sh
npx serve public
```

…which serves the directory at `http://localhost:3000`.

## Self-host / fork it

The MIT license lets you fork and deploy your own copy. Because everything is static, **any static file host works** — Cloudflare Pages, Cloudflare Workers, Netlify, Vercel, GitHub Pages, S3+CloudFront, your own Apache/nginx, etc.

### 1. Things you'll want to change before deploying

The app is set up so most fork-time customization happens in one file:

**`public/config.js`** — set your own Google Analytics ID, or leave it as `''` to disable analytics entirely. That's it; no other edits required for a basic fork.

A few things you *might* want to change but don't need to (all under `public/`):

| What | Where |
|---|---|
| Title "Scoring Spades" | `public/index.html` `<title>` + the header literal in the JS (`'Scoring Spades'`); `public/how-to-play.html` `<title>` + header `<div>` |
| App name "ScoringSpades" / "Spades" (PWA install) | `public/manifest.json` (`name`, `short_name`) |
| Favicon | `public/icon.svg` and the inline data-URL favicons in both HTML files |
| GitHub link in the footer ("Launch your own ScoringSpades app") | `public/index.html` — `GITHUB_URL` constant and the link label |

The CSP in `public/_headers` allowlists Google's tag manager domains for gtag. If you set `gaId: ''`, you can tighten the CSP by removing `https://www.googletagmanager.com` and `https://www.google-analytics.com` from `script-src` and `connect-src`. If you swap to a different analytics vendor, allowlist their domains instead.

### 2. Deploy

Pick whichever host you like. Here's the Cloudflare Workers path I use, but anything serving these files works.

**Cloudflare Workers (with Static Assets):**
```sh
# One-time: install wrangler and log in
npm install -g wrangler
wrangler login

# Edit the worker name in wrangler.jsonc (it's `scoringspades` here — change it)
# Then deploy from the repo root:
wrangler deploy
```

**Anything else:** point the host at the `public/` directory. The files that ship are `index.html`, `how-to-play.html`, `config.js`, `manifest.json`, `icon.svg`, and `_headers` (Cloudflare-specific; other hosts have their own equivalent). The `_headers` file is what wires up the CSP and HSTS — without it (or its equivalent on your host), you lose the security-header defenses but the app still works.

### 3. Custom domain

Whatever host you pick, point your domain at it per their docs. The app uses only relative URLs internally, so it'll work from any origin without code changes.

## License

MIT — see [LICENSE](LICENSE).

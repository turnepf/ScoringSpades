# ScoringSpades

A scoring app for the card game Spades. Single-page web app at scoringspades.com.

## Tech

- `index.html` (app) + `how-to-play.html` (rules page) + `privacy.html` + `config.js` (fork-time settings) + `manifest.json` + `icon.svg`. No build step, no dependencies, no framework.
- Vanilla JS with a tiny custom `el(tag, attrs, ...children)` render helper (not React).
- Inline CSS, inline SVG favicon, inline JS — main app ships in one file (~50 KB).
- State persisted to `localStorage` under key `spades-state-v1`.
- Mobile-first (iOS PWA meta tags, safe-area insets) — viewport is locked, no user-scalable.
- **`config.js`** sets `window.SCORING_CONFIG.gaId` (Google Analytics ID — currently `G-0J06PZ892T`; set to `''` to disable). Both HTML files load this and conditionally inject the gtag script. This is the only fork-time variable; titles and branding are hardcoded as "Scoring Spades".
- Footer link on the setup screen points to the GitHub repo ("Launch your own ScoringSpades app") — drives forks.

## App structure (inside `index.html`)

- **State/phases:** `setup` → `playing` → `gameover`. `modal` is a separate global: `bid`, `tricks`, or `preview`.
- **Render entry:** `render()` routes on `state.phase`. Each screen has a `renderX()` function that calls `app.replaceChildren(...)`.
- **Scoring model** (`scoreTeamRound`): `bid × 10` if they hit, `−bid × 10` if they miss, `+1` per bag. Bag overflow: every 10 bags = `−100` penalty. Nil = ±`state.nilPoints` (default 100), Blind nil = ±`state.blindNilPoints` (default 200) — both configurable on setup. Optional house rule `state.nilPartnerMinBid` (default 0) forces the nil bidder's partner to bid at least N — enforced in the bid modal.
- **Legacy name migration:** old default placeholder names (`Player 1`–`Player 4`) are wiped on load so the user isn't stuck with them.

## Deploy (Cloudflare Worker + Static Assets)

**This is a Worker, not a Pages project** — the original Pages project (`spades` / `spades-7wr.pages.dev`) was migrated. Don't try `wrangler pages deploy`; it will fail with "Project not found."

- **Worker name:** `scoringspades` (not `spades`)
- **Account:** `851a39c5483b9aef842112771b5f8542` (patrick@patrickturner.net)
- **Domains:** `scoringspades.com`, `www.scoringspades.com`, `scoringspades.patrick-851.workers.dev`
- **Mechanism:** Workers Static Assets (`assets.directory` binding). No custom Worker logic — static files served directly. `_headers` and `_redirects` are supported (Pages-compatible behavior).

### Deploy

**Automatic:** Cloudflare's own Git integration (Workers Builds) is connected to this repo and deploys `main` to production on every push — confirmed working September 2026, no GitHub Actions or repo secrets involved. Non-`main` branches/PRs get their own preview URLs (`cloudflare-workers-and-pages[bot]` comments them on the PR) without touching production. A GitHub Actions `wrangler-action` workflow was tried first but turned out redundant to this and was removed.

**Manual fallback:** `wrangler.jsonc` lives at the repo root (added by Cloudflare's GitHub auto-config bot in PR #1, April 2026), so deploy is one command from the project root:

```
cd ~/ScoringSpades
wrangler deploy

# Verify
curl -sI https://scoringspades.com/ | grep -iE "^(content-security|strict-transport|x-content|referrer-policy|permissions-policy)"
```

Auth: already logged in as patrick@patrickturner.net via `wrangler` OAuth. Verify with `wrangler whoami`.

### Repo layout: deployable files live in `public/`

`wrangler.jsonc` is configured with `assets.directory: "./public"`. **Only files inside `public/` are deployed.** This is structural protection — repo-root files like `LICENSE`, `README.md`, `CLAUDE.md`, `wrangler.jsonc`, `.git/` etc. are never uploaded.

Why this exists: an earlier deploy used `assets.directory: "."` (the value Cloudflare's auto-config bot wrote in PR #1) and ended up shipping `.git/objects/...`, `.wrangler/cache/...`, and the markdown files as 200-OK assets. Restructured into `public/` to make that impossible.

**The deployable files:** `index.html`, `how-to-play.html`, `privacy.html`, `config.js`, `manifest.json`, `icon.svg`, `_headers`, `_redirects`, `.well-known/apple-app-site-association`. If you add a new asset (e.g., a sound effect, an image), drop it inside `public/` or the deploy won't include it.

### Notes & gotchas

- `_headers` is a **config file**, not a static asset. `wrangler deploy` will report it in the file count but it's interpreted by Cloudflare to set response headers, not served at `/_headers` (that path returns 404).
- The local `.wrangler/cache/wrangler-account.json` only contains the public `account.id` and `account.name` — no token. (The OAuth token lives at `~/.wrangler/config/default.toml`.) The old "deploy from clean staging dir to avoid leaking the wrangler cache" rule was based on a misunderstanding.
- If `wrangler.jsonc` ever disappears, recover it with: `cd /tmp && wrangler init --from-dash scoringspades --yes` (creates a subdir with the dashboard's current config). **Never run that command inside the `ScoringSpades/` repo dir** — macOS case-insensitivity creates a confusing nested `scoringspades/` directory.

### CSP / security headers

Production headers come from `_headers`. CSP allowlists `googletagmanager.com` + `google-analytics.com` for gtag. If you add any new third-party script (Stripe, Cloudflare Turnstile, Sentry, etc.), update `script-src` and likely `connect-src` in `_headers` or the page will silently break with CSP violations in the browser console.

### "Get the App" header button + iOS Universal Link

On Apple devices (iPhone, or iPad — detected via `isApplePlatform()`, since iPadOS 13+ reports a desktop Mac user agent), the header shows a **Get the App** button next to the title, on every screen (setup/playing/gameover). It links to `/app`, which `_redirects` 302s to the App Store listing.

`/app` doubles as a Universal Link path: `public/.well-known/apple-app-site-association` declares it under the app's `NQ6AJVVBBJ.com.scoringspades.app` App ID, and `ios/project.yml` requests the matching `com.apple.developer.associated-domains: applinks:scoringspades.com` entitlement. Once that's live, tapping the header button on a device with the app installed opens the app directly (System intercepts before any network request); without the app, it falls through to the redirect. **This entitlement only takes effect once Patrick regenerates the Xcode project (`cd ios && xcodegen`), rebuilds, and ships a new App Store version** — until then the button always behaves like today (opens the App Store page, which itself shows "OPEN" instead of "GET" if already installed).

## iOS app (`ios/`)

**Fully native SwiftUI app — never a web wrapper.** Patrick only wants native apps (no WKWebView/Capacitor/PWA shells), so the web app's logic is reimplemented in Swift, not bundled. See `ios/README.md`.

- **Keep the two in sync.** Scoring, bag penalties, nil/blind nil, the nil-partner minimum, tips, and How to Play text exist in both `public/index.html` and `ios/ScoringSpades/`. A rules or copy change in one needs the same change in the other. `ios/ScoringSpadesTests/ScoringTests.swift` pins scoring to the web behavior.
- Model: `Model/Game.swift` (state + scoring), `RoundDraft.swift` (bid → tricks → preview), `Tips.swift`, `GameStore.swift` (persists to UserDefaults). Views in `Views/`, palette and shared controls in `Theme/Theme.swift`.
- Project is generated by XcodeGen: edit `ios/project.yml`, then `cd ios && xcodegen`. Don't hand-edit the `.xcodeproj`.
- Bundle ID `com.scoringspades.app`, team `NQ6AJVVBBJ`, iOS 17+. No analytics, no network access.
- `ScoringSpadesUITests` finds controls by accessibility label ("Patrick bids 4", "Patrick & Dee took 7", "Score Round N"). Renaming labels in the views breaks it.

## GitHub

Repo: `turnepf/ScoringSpades` on GitHub. `gh` CLI is authenticated as `turnepf`. Push with `git push` — merges to `main` auto-deploy via Cloudflare's Git integration (see Deploy section above).

## Monetization

None. Previously had a Venmo tip jar (`@turnepf`) on setup + winner screens — removed in favor of a "Launch your own ScoringSpades app" link to the GitHub repo on the setup screen. App is no-fee, no-account, MIT-licensed, fork-friendly.

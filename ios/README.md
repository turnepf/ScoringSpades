# ScoringSpades for iPhone & iPad

A thin native shell around the web app. The files in `../public/` are copied
into the app bundle at build time, so the app is the same scorekeeper as
scoringspades.com. It runs fully offline and picks up web changes on the next
build.

## How it works

| File | Role |
|---|---|
| `ScoringSpades/ScoringSpadesApp.swift` | SwiftUI entry point; full-screen web view |
| `ScoringSpades/WebViewController.swift` | `WKWebView` host: native `alert`/`confirm`/`prompt`, outside links open in Safari, swipe-back |
| `ScoringSpades/BundledAssetSchemeHandler.swift` | Serves `public/` from `scoringspades://app/` so root-relative links (`/how-to-play`, `/privacy`) and `localStorage` behave like the website. Turns analytics off (`gaId = ''`) |
| `ScoringSpades/PrivacyInfo.xcprivacy` | Privacy manifest: no tracking, no data collected |
| `ScoringSpadesUITests/` | Plays a full game (dialogs, navigation, relaunch persistence) and saves App Store screenshots |
| `scripts/make-icon.swift` | Regenerates the 1024 px app icon |
| `project.yml` | XcodeGen spec. **Edit this, not the `.xcodeproj`**, then run `xcodegen` |

Bundle ID `com.scoringspades.app` · Team `NQ6AJVVBBJ` · iOS 17+ · iPhone is
portrait-only; iPad supports every orientation.

## Run it

```sh
cd ~/ScoringSpades/ios
open ScoringSpades.xcodeproj      # then pick a simulator or your phone and hit Run
```

If you change `project.yml`, run `xcodegen` to regenerate the project first.

## Test + App Store screenshots

Run the test on a fresh install. Use dark mode and a clean status bar for the
store images: iPhone 17 Pro Max is the 6.9" size, and iPad Pro 13" is the 13" size.

```sh
D="iPhone 17 Pro Max"   # or "iPad Pro 13-inch (M5)"
xcrun simctl boot "$D"; xcrun simctl ui "$D" appearance dark
xcrun simctl status_bar "$D" override --time 9:41 --batteryState charged --batteryLevel 100
xcrun simctl uninstall "$D" com.scoringspades.app
TEST_RUNNER_SCREENSHOT_DIR=~/Desktop/spades-shots \
  xcodebuild test -project ScoringSpades.xcodeproj -scheme ScoringSpades \
  -destination "platform=iOS Simulator,name=$D" -derivedDataPath build
```

## Releasing a new version

1. Bump `MARKETING_VERSION` (e.g. `1.1`) and/or `CURRENT_PROJECT_VERSION` in `project.yml`, then run `xcodegen`.
2. In Xcode, choose **Product → Archive**. In the Organizer, choose **Distribute App → App Store Connect → Upload**.
3. In App Store Connect, add the build to a new version and submit it for review.

Every build of the app bundles `public/` as it is at build time. To ship a web
change to iOS, you need a new build and review.

## App Store listing (first submission)

Create the app at [App Store Connect](https://appstoreconnect.apple.com) →
Apps → **+ New App**: platform iOS, name **Scoring Spades**, bundle ID
`com.scoringspades.app`, SKU `scoringspades`.

- **Subtitle:** Spades scorekeeper for 4 players
- **Category:** Games → Card (secondary: Utilities)
- **Price:** Free
- **Age rating:** answer "None" to everything (4+)
- **Privacy policy URL:** https://scoringspades.com/privacy
- **Support URL:** https://scoringspades.com/how-to-play
- **App Privacy:** "Data Not Collected"
- **Keywords:** spades,score,scorekeeper,card game,bid,nil,blind nil,bags,tally,points
- **Description:**

  > Keep score for Spades without the pencil and paper.
  >
  > Scoring Spades tracks bids, tricks, and bags for two teams of two, so you can keep your eyes on the cards.
  >
  > • Enter each player's bid, then tricks taken. The math is done for you
  > • Nil and blind nil, with values you choose
  > • Bags tracked automatically, with the 100-point penalty at every 10
  > • Play to 250, 300, 500, or any score you like
  > • Optional house rule: set a minimum bid for the nil bidder's partner
  > • Round-by-round history, with undo
  > • Strategy tips based on the state of the game
  > • Built-in How to Play guide
  > • Light and dark mode
  >
  > No accounts, no ads, no tracking. Your game saves on your device and works offline.

- **Screenshots:** from the test run above (6.9" iPhone plus 13" iPad).

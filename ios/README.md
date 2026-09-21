# ScoringSpades for iPhone & iPad

A fully native SwiftUI app. It has the same rules, settings, and features as
scoringspades.com, reimplemented in Swift. No web views. It works offline,
collects nothing, and makes no network requests of its own. (Tapping a link
opens it in Safari, and iOS itself fetches the Universal Link association
file at install — neither sends anything about you.)

## Layout

| Path | What's there |
|---|---|
| `ScoringSpades/Model/Game.swift` | Game state and scoring: bids, bags, 10-bag penalty, nil and blind nil, win check, undo, rematch |
| `ScoringSpades/Model/RoundDraft.swift` | A round in progress: bids (with the nil-partner minimum), tricks (team 2 defaults to 13 − team 1), nil made/failed |
| `ScoringSpades/Model/Tips.swift` | Strategy tips picked from the game state |
| `ScoringSpades/Model/GameStore.swift` | Observable store; saves the game, last player names, and tips setting to UserDefaults |
| `ScoringSpades/Views/` | Setup, Scoreboard, Round entry (Bidding → Tricks → Round Score), Game Over, How to Play, Privacy |
| `ScoringSpades/Theme/Theme.swift` | Light/dark palette and shared controls |
| `ScoringSpadesTests/` | Unit tests that pin scoring to the web app's behavior |
| `ScoringSpadesUITests/` | Plays a full game and saves App Store screenshots |
| `scripts/make-icon.swift` | Regenerates the 1024 px app icon |
| `project.yml` | XcodeGen spec. **Edit this, not the `.xcodeproj`**, then run `xcodegen` |

Bundle ID `com.scoringspades.app` · Team `NQ6AJVVBBJ` · iOS 17+ · iPhone is
portrait-only; iPad supports every orientation.

**Keeping web and app in sync:** the rules live in two places, `public/index.html`
and `Model/`. When scoring, tips, or How to Play copy changes on one side,
change the other side too. `ScoringTests` will catch scoring drift if you
update the test alongside the web change.

## Run it

```sh
cd ~/ScoringSpades/ios
open ScoringSpades.xcodeproj      # pick a simulator or your phone, then Run
```

## Test + App Store screenshots

```sh
D="iPhone 17 Pro Max"   # 6.9" screenshots; use "iPad Pro 13-inch (M5)" for 13"
xcrun simctl boot "$D"; xcrun simctl ui "$D" appearance dark
xcrun simctl status_bar "$D" override --time 9:41 --batteryState charged --batteryLevel 100
TEST_RUNNER_SCREENSHOT_DIR=~/Desktop/spades-shots \
  xcodebuild test -project ScoringSpades.xcodeproj -scheme ScoringSpades \
  -destination "platform=iOS Simulator,name=$D" -derivedDataPath build
```

The UI test launches with `-uiTestFreshState`, which uses a separate, wiped
UserDefaults suite, so your real saved game is never touched.

## Releasing a new version

1. Bump `MARKETING_VERSION` (e.g. `1.1`) and/or `CURRENT_PROJECT_VERSION` in `project.yml`, then run `xcodegen`.
2. In Xcode, choose **Product → Archive**. In the Organizer, choose **Distribute App → App Store Connect → Upload**.
3. In App Store Connect, add the build to a new version and submit it for review.

## App Store listing

Live at <https://apps.apple.com/app/scoring-spades/id6812531693>.

### First submission notes

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

import SwiftUI

// MARK: - Building blocks for long-form pages

private struct PageHeading: View {
  let text: String
  var body: some View {
    Text(text)
      .font(.title3.weight(.bold))
      .foregroundStyle(Theme.gold)
      .padding(.top, 18)
      .accessibilityAddTraits(.isHeader)
  }
}

private struct Paragraph: View {
  let text: LocalizedStringKey
  init(_ text: LocalizedStringKey) { self.text = text }
  var body: some View {
    Text(text).font(.body).foregroundStyle(Theme.text).lineSpacing(3)
      .fixedSize(horizontal: false, vertical: true)
  }
}

private struct Bullets: View {
  let items: [LocalizedStringKey]
  var numbered = false

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      ForEach(items.indices, id: \.self) { i in
        HStack(alignment: .firstTextBaseline, spacing: 10) {
          Text(numbered ? "\(i + 1)." : "•").foregroundStyle(Theme.muted).monospacedDigit()
          Paragraph(items[i])
        }
      }
    }
  }
}

private struct InfoCard: View {
  let title: String
  var formula: String?
  let paragraphs: [LocalizedStringKey]

  var body: some View {
    Card(padding: 16) {
      VStack(alignment: .leading, spacing: 8) {
        Text(title).font(.headline).foregroundStyle(Theme.text)
        if let formula {
          Text(formula)
            .font(.system(.subheadline, design: .monospaced).weight(.semibold))
            .foregroundStyle(Theme.team1)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Theme.background2, in: .rect(cornerRadius: 8))
        }
        ForEach(paragraphs.indices, id: \.self) { Paragraph(paragraphs[$0]) }
      }
    }
  }
}

private struct InfoPage<Content: View>: View {
  let title: String
  @ViewBuilder var content: Content

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) { content }
        .screenLayout(maxWidth: 680)
        .padding(.vertical, 12)
    }
    .background(Theme.background)
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.large)
    .toolbarBackground(Theme.background, for: .navigationBar)
  }
}

// MARK: - How to Play

struct HowToPlayView: View {
  var body: some View {
    InfoPage(title: "How to Play") {
      Text("The short, practical version — written for people using this app to score their game.")
        .font(.callout).foregroundStyle(Theme.muted)

      PageHeading(text: "A bit of history")
      Paragraph("Spades is an American partnership trick-taking game that emerged in the late 1930s, descended from older Whist-family games like Bid Whist and Auction Bridge. It spread quickly through college campuses and the U.S. military during World War II, and by the 1950s had become one of the most-played social card games in the country. The modern partnership-with-bidding format is essentially unchanged from that era — what's evolved is the scoring (bags and nil came later) and the conventions around how partners signal through their bids.")

      PageHeading(text: "The basics")
      Bullets(items: [
        "**4 players, 2 teams of 2.** Partners sit across from each other. Team 1 (orange) vs. Team 2 (blue) — the colors you see in the app.",
        "**Standard 52-card deck.** Each player gets 13 cards.",
        "**Spades are always trump.** A spade beats any card of another suit.",
        "**Goal:** first team to the target score wins. In this app the target defaults to 500, but you can pick 250, 300, or any custom number on the setup screen.",
      ])

      PageHeading(text: "A round at a glance")
      Bullets(items: [
        "**Deal.** Deal passes to the left each round.",
        "**Bid.** Each player says how many tricks they think they'll take. Add the two partners together — that's your *team bid*.",
        "**Play 13 tricks.** Leader plays any non-spade card (spades can't be led until \"broken\"). Highest card of the led suit wins, unless someone plays a spade — highest spade wins.",
        "**Count tricks.** Enter each team's trick count in the app. Totals always add to 13.",
        "**Score.** The app does the math. Repeat until someone hits the target.",
      ], numbered: true)

      PageHeading(text: "How this app scores")
      InfoCard(title: "You made your bid", formula: "points = bid × 10 + 1 per overtrick (bag)", paragraphs: [
        "If your team bid 4 and took 5 tricks, you get 40 + 1 = 41 points, and you pick up 1 bag.",
      ])
      InfoCard(title: "You missed your bid (\"set\")", formula: "points = −(bid × 10)", paragraphs: [
        "Bid 4, take 3, you lose 40. You don't get bags when you're set — you just take the hit.",
      ])
      InfoCard(title: "Bags — the overtrick tax", paragraphs: [
        "Every extra trick beyond your bid is a **bag**. Bags count +1 each, but they build up. The moment your running bag total hits 10, the app deducts 100 points and resets the bag counter.",
        "This is why over-bidding a little is safer than under-bidding a lot — sandbagging stings eventually.",
      ])
      InfoCard(title: "Nil", formula: "success = +100 | failure = −100", paragraphs: [
        "A player can declare **nil** — a promise to take *zero* tricks. Tap Nil under their name on the bidding screen. Their partner still bids and plays normally. Nil is scored on top of the team's regular bid result.",
        "100 points is the standard, but you can set your own nil and blind nil values under House Rules on the setup screen. House Rules also has an optional rule requiring the nil bidder's partner to bid a minimum number of tricks (off by default).",
      ])
      InfoCard(title: "Blind nil", formula: "success = +200 | failure = −200", paragraphs: [
        "Declare nil *before looking at your hand*. Double reward, double risk. Mostly used when a team is way behind and needs a swing. 200 points is the standard, but the blind nil value is configurable under House Rules too.",
      ])

      PageHeading(text: "Winning the game")
      Paragraph("First team to reach or exceed the target score wins. If both teams cross the line in the same round, the higher score wins. The app shows the winner on the final screen along with a rematch button.")

      PageHeading(text: "Bidding strategy")
      Paragraph("Bidding well is most of the game. Played badly, every other skill stops mattering. Here's how experienced players actually evaluate a hand:")
      InfoCard(title: "Count your sure tricks first", paragraphs: [
        "Aces almost always win. Kings usually win *if* you also have one or two more cards in that suit to protect them (a singleton King gets crushed under an opponent's Ace). Start your count there.",
      ])
      InfoCard(title: "Then add trump tricks", paragraphs: [
        "Every spade above the Ten is likely a winner. Low spades are winners *after* the high spades and aces are gone — count them when your hand is spade-heavy.",
      ])
      InfoCard(title: "Short side suits are gold", paragraphs: [
        "If you have zero or one card in a non-spade suit, you'll be trumping that suit early. A void (zero cards) is worth roughly one extra trick; a singleton is worth a half-trick on average. Bid accordingly.",
      ])
      InfoCard(title: "Long off-suits are traps", paragraphs: [
        "Five hearts headed by the Queen is not five tricks. After the Ace and King fall (usually held by opponents), your Queen probably gets trumped. Long weak suits aren't bid material — they're survival material.",
      ])
      InfoCard(title: "Read your partner's bid", paragraphs: [
        "You can't signal specific cards, but bidding is a language. A bid of **4 or more** says \"I'm strong, you can bid normally.\" A bid of **1** says \"I have very little — carry me.\" A bid of **0 or nil** says \"I have no real tricks.\" Calibrate your own bid to what your partner just told you.",
      ])
      InfoCard(title: "When to bid nil", paragraphs: [
        "Nil is a promise to take zero tricks. It works when you have *no* Aces, no protected Kings, no spades above the Eight, and no short side suit (because being void means you'll trump in). The classic nil hand is a bunch of low cards spread across the four suits with a few middle spades — boring but safe.",
      ])
      InfoCard(title: "When NOT to bid nil", paragraphs: [
        "Don't go nil with the Ace of Spades, a singleton in any suit, or a long spade suit. And don't nil when your team is already winning by 200+ — the +100 reward isn't worth the −100 risk when you're already cruising.",
      ])

      PageHeading(text: "Common rule variants")
      Paragraph("Spades has dozens of house-rule variations. The app's scoring handles the standard rules, but if your group plays differently, here's a glossary of what you might hear at the table:")
      Bullets(items: [
        "**Suicide nil** — at least one player on each team must bid nil every round. Brutal but fast.",
        "**Mirror (or \"Mirrors\")** — players must bid the exact number of spades they hold. No choice, no judgment. Counts as a fun-but-luck-driven variant.",
        "**Whiz** — players must bid either nil or the exact number of spades they hold. A middle ground between Mirror and free bidding.",
        "**Jack of Diamonds rule** — the Jack of Diamonds becomes the second-highest trump (just below the Ace of Spades). Rare but you'll occasionally see it.",
        "**Cutthroat (3-player)** — no partnerships, every player scores individually. Not what this app is built for.",
        "**Diamond breaks spades** — instead of waiting for someone to play a spade off-suit, leading a diamond also \"breaks\" trump. Uncommon but you'll meet it.",
        "**Bag penalty variations** — some groups use 5-bag instead of 10-bag penalties, or skip bag penalties entirely. This app uses the standard 10-bags-for-100 rule.",
        "**Target score** — 500 is the classic target. Tournament play often uses 250 or 300 for shorter games. Casual play sometimes goes to 650 or even 1000. The app supports any target via \"Custom.\"",
      ])

      PageHeading(text: "In-app strategy tips")
      Paragraph("Once you've scored your first round, the app shows a rotating strategy tip below the scoreboard. The tips are picked *based on what's happening in your game*: if your team is at 8 bags, you'll see the bag-warning tip; if someone bid nil, you'll see nil-related advice; if it's a tight endgame, you'll see endgame tips. It's not random — it's reading the state of your match.")
      Paragraph("If you'd rather play without tips, there's an **On / Off** setting on the setup screen. Your choice persists between games.")

      PageHeading(text: "FAQ")
      InfoCard(title: "Why are we \"set\" if we took 13 tricks?", paragraphs: [
        "You're set if your team's combined trick count is *less* than your bid. Taking 13 tricks always meets any bid up to 13, so that's never a set. But if you bid 10 and took 8, that's a set — overshooting on tricks isn't possible, undershooting is.",
      ])
      InfoCard(title: "Is bidding zero the same as nil?", paragraphs: [
        "No. Bidding 0 as your *team* bid means neither partner declared nil — you're just saying \"we don't expect to take any tricks.\" If you take some anyway, they're all bags (no points, but bag penalty exposure). Nil is declared separately by an individual player and is worth ±100 on top of the team's regular score.",
      ])
      InfoCard(title: "What if both teams hit the target in the same round?", paragraphs: [
        "The team with the higher score wins. The app handles this automatically and shows the winner on the game over screen. If somehow the scores are tied at or above the target, the game continues — but that's vanishingly rare.",
      ])
      InfoCard(title: "What happens at exactly 10 bags?", paragraphs: [
        "The moment the running bag counter reaches 10, your team loses 100 points and the counter resets to 0 (so 11 bags = −100 plus 1 carry-over, 12 = −100 plus 2, etc.). The bag display below each team's score shows the current count.",
      ])
      InfoCard(title: "Can I undo a round?", paragraphs: [
        "Yes — there's an \"Undo last\" button on the scoreboard. It rolls back the most recent round's score, bags, and bag penalties. Use it if you entered the wrong tricks.",
      ])
      InfoCard(title: "Does it work offline?", paragraphs: [
        "Yes. The app runs entirely on your device. No internet connection, no account, and no server calls — ever.",
      ])
    }
  }
}

// MARK: - Privacy

struct PrivacyView: View {
  var body: some View {
    InfoPage(title: "Privacy") {
      Text("The short version: the Scoring Spades app doesn't collect anything. No accounts, no analytics, no ads, no tracking.")
        .font(.callout).foregroundStyle(Theme.muted)

      PageHeading(text: "What we collect from you")
      Paragraph("**Nothing.** There are no accounts, signups, or logins. The app never asks for your name, email, phone number, age, or location, and it doesn't connect to the internet.")

      PageHeading(text: "Where your game data lives")
      Paragraph("Player names, scores, bid history, and game settings are saved on this device only. We can't see them. They stay until you start a brand new game or delete the app.")

      PageHeading(text: "Links to other sites")
      Paragraph("The \"Launch your own ScoringSpades app\" link opens GitHub in Safari. What happens there is covered by GitHub's own privacy policy.")

      PageHeading(text: "Children")
      Paragraph("Scoring Spades is suitable for all ages. Because it collects no data at all, nothing is collected from children either.")

      PageHeading(text: "The website")
      Paragraph("The web version at scoringspades.com has its own policy, which covers analytics used on the site. Read it at [scoringspades.com/privacy](https://scoringspades.com/privacy).")

      PageHeading(text: "Contact")
      Paragraph("Questions? Email [patrick@patrickturner.net](mailto:patrick@patrickturner.net).")
    }
  }
}

import Foundation

/// Strategy tips shown under the scoreboard. Conditional tips fire when their
/// condition matches the game and take priority over the always-eligible ones.
struct Tip: Sendable {
  let text: @Sendable (Game) -> String
  let when: (@Sendable (Game) -> Bool)?

  init(_ text: String, when: (@Sendable (Game) -> Bool)? = nil) {
    self.text = { _ in text }
    self.when = when
  }

  init(_ text: @escaping @Sendable (Game) -> String, when: (@Sendable (Game) -> Bool)? = nil) {
    self.text = text
    self.when = when
  }
}

enum Tips {
  static let all: [Tip] = [
    Tip("Count spades as they're played — knowing who holds the last one often decides the hand."),
    Tip("Don't break spades early unless you have the Ace or King to back it up."),
    Tip("A short side suit (void or singleton) turns into trump tricks — bid aggressively when you have one."),
    Tip("Save high spades for late in the hand — you can often trump an opponent's winner."),
    Tip("Count your sure tricks (Aces, protected Kings) before adding bids from short suits."),
    Tip("A singleton Ace is a one-trick wonder; a doubleton Ace-King is worth two, maybe more."),
    Tip("If you're set either way, dump your bags on your opponents instead of your partner."),
    Tip("When leading against a nil, play your highest card in the suit — force them to take it."),
    Tip("Near 9 bags — consider taking a set on purpose to reset the bag count.",
        when: { $0.team1.bags >= 8 || $0.team2.bags >= 8 }),
    Tip("Overbidding by one beats sandbagging by three: every 10 bags costs you 100 points.",
        when: lastRoundOverbid),
    Tip("Bid to your hand, not to 13 — a forced tight bid often ends in a set.",
        when: lastRoundSet),
    Tip({ "Way behind? A blind nil is a \($0.blindNilPoints)-point swing — risky but real." },
        when: { abs($0.team1.score - $0.team2.score) >= 100 }),
    Tip("Tight endgame — bags matter less than hitting your bid exactly.",
        when: { $0.target - $0.team1.score <= 50 && $0.target - $0.team2.score <= 50 }),
    Tip({ "Cover your partner's nil before chasing your own bid — a failed nil costs \($0.nilPoints)." },
        when: lastRoundHadNil),
    Tip("If your partner bids nil, lead your highest side-suit cards so they can safely dump low.",
        when: lastRoundHadNil),
    Tip("Almost there — don't get fancy, just hit your bid.",
        when: { ($0.target - $0.team1.score <= 50 && $0.team1.bags <= 3) || ($0.target - $0.team2.score <= 50 && $0.team2.bags <= 3) }),
  ]

  /// Picks a tip index for the current game, avoiding an immediate repeat.
  static func pick(for game: Game, current: Int?) -> Int {
    let indices = all.indices
    let conditional = indices.filter { all[$0].when?(game) == true }
    let pool = conditional.isEmpty ? indices.filter { all[$0].when == nil } : conditional
    let fresh = pool.filter { $0 != current }
    return (fresh.isEmpty ? pool : fresh).randomElement() ?? 0
  }

  private static func lastRoundSet(_ g: Game) -> Bool {
    guard let r = g.rounds.last else { return false }
    return r.team1.delta < 0 || r.team2.delta < 0
  }

  private static func lastRoundOverbid(_ g: Game) -> Bool {
    guard let r = g.rounds.last else { return false }
    return (r.team1.delta > 0 && r.team1.bagsAdded >= 2) || (r.team2.delta > 0 && r.team2.bagsAdded >= 2)
  }

  private static func lastRoundHadNil(_ g: Game) -> Bool {
    guard let r = g.rounds.last else { return false }
    return !r.team1.nils.isEmpty || !r.team2.nils.isEmpty
  }
}

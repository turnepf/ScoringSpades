import Foundation

// Mirrors the web app's saved state so scoring behaves identically on
// scoringspades.com and in the app.

enum TeamID: String, Codable, CaseIterable, Identifiable {
  case team1, team2
  var id: Self { self }
  var other: TeamID { self == .team1 ? .team2 : .team1 }
}

enum Phase: String, Codable {
  case setup, playing, gameover
}

enum NilKind: String, Codable {
  case nilBid = "nil"
  case blind

  var label: String { self == .blind ? "blind nil" : "nil" }
  var shortLabel: String { self == .blind ? "BN" : "N" }
}

struct Team: Codable, Equatable {
  var score = 0
  var bags = 0
  var players = ["", ""]

  /// Name at `index`, or "" — total, so a short array can never trap a view.
  func name(at index: Int) -> String {
    players.indices.contains(index) ? players[index] : ""
  }

  /// "Patrick & Dee", falling back to whichever name exists, then "Team".
  var label: String {
    let a = name(at: 0), b = name(at: 1)
    if !a.isEmpty && !b.isEmpty { return "\(a) & \(b)" }
    return a.isEmpty ? (b.isEmpty ? "Team" : b) : a
  }

  var isFullyNamed: Bool {
    players.allSatisfy { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
  }
}

struct NilResult: Codable, Equatable {
  var playerIndex: Int
  var kind: NilKind
  var made: Bool
}

/// One team's result for a round. `delta`, `bagsAdded` and `bagPenalty` are
/// filled in when the round is committed.
struct TeamRound: Codable, Equatable {
  var bid: Int
  var tricks: Int
  var nils: [NilResult]
  var delta = 0
  var bagsAdded = 0
  var bagPenalty = 0

  /// "bid 7, took 8 · N:✓"
  var historySummary: String {
    (["bid \(bid), took \(tricks)"] + nils.map { "\($0.kind.shortLabel):\($0.made ? "✓" : "✗")" })
      .joined(separator: " · ")
  }
}

struct Round: Codable, Equatable {
  var team1: TeamRound
  var team2: TeamRound

  subscript(team: TeamID) -> TeamRound {
    get { team == .team1 ? team1 : team2 }
    set { if team == .team1 { team1 = newValue } else { team2 = newValue } }
  }
}

struct Game: Codable, Equatable {
  static let bagsPerPenalty = 10
  static let bagPenaltyPoints = 100
  static let tricksPerHand = 13

  var phase: Phase = .setup
  var team1 = Team()
  var team2 = Team()
  var target = 500
  var nilPoints = 100
  var blindNilPoints = 200
  /// House rule: when a player bids nil, their partner must bid at least this. 0 = off.
  var nilPartnerMinBid = 0
  var rounds: [Round] = []

  subscript(team: TeamID) -> Team {
    get { team == .team1 ? team1 : team2 }
    set { if team == .team1 { team1 = newValue } else { team2 = newValue } }
  }

  var allPlayersNamed: Bool { team1.isFullyNamed && team2.isFullyNamed }

  var leader: TeamID? {
    team1.score == team2.score ? nil : (team1.score > team2.score ? .team1 : .team2)
  }

  func points(for kind: NilKind) -> Int { kind == .blind ? blindNilPoints : nilPoints }
}

// MARK: - Post-decode normalization

extension Game {
  // Bounds mirror loadState() in public/index.html. Keep the two in step.
  static let maxPoints = 10_000      // nil / blind-nil values
  static let maxTarget = 100_000
  static let maxScore = 1_000_000
  static let maxNameLength = 15
  static let maxRounds = 1_000

  /// JSONDecoder checks types but not ranges, lengths or invariants. Every
  /// consumer (Team.label, Tips predicates, the scoring arithmetic, the round
  /// history views) assumes bounds that nothing else establishes, and Swift
  /// traps rather than coercing, so a hand-edited blob would crash the app.
  /// Apply this once at the decode site.
  func normalized() -> Game {
    var g = self
    g.target = Self.clamp(target, 1, Self.maxTarget, fallback: 500)
    g.nilPoints = Self.clamp(nilPoints, 1, Self.maxPoints, fallback: 100)
    g.blindNilPoints = Self.clamp(blindNilPoints, 1, Self.maxPoints, fallback: g.nilPoints * 2)
    g.nilPartnerMinBid = Self.clamp(nilPartnerMinBid, 0, Self.tricksPerHand, fallback: 0)

    for id in TeamID.allCases {
      var t = g[id]
      // Pad-then-trim so short, empty and over-long arrays all land on exactly two.
      t.players = (0..<2).map { String(t.name(at: $0).prefix(Self.maxNameLength)) }
      t.score = Self.clamp(t.score, -Self.maxScore, Self.maxScore, fallback: 0)
      t.bags = Self.clamp(t.bags, 0, Self.bagsPerPenalty - 1, fallback: 0)
      g[id] = t
    }

    g.rounds = g.rounds.prefix(Self.maxRounds).map { round in
      var r = round
      for id in TeamID.allCases {
        var tr = r[id]
        tr.bid = Self.clamp(tr.bid, 0, 2 * Self.tricksPerHand, fallback: 0)
        tr.tricks = Self.clamp(tr.tricks, 0, Self.tricksPerHand, fallback: 0)
        tr.delta = Self.clamp(tr.delta, -Self.maxScore, Self.maxScore, fallback: 0)
        tr.bagsAdded = Self.clamp(tr.bagsAdded, 0, Self.tricksPerHand, fallback: 0)
        tr.bagPenalty = Self.clamp(tr.bagPenalty, 0, Self.maxScore, fallback: 0)
        tr.nils = tr.nils.prefix(2).filter { (0...1).contains($0.playerIndex) }
        r[id] = tr
      }
      return r
    }
    return g
  }

  private static func clamp(_ value: Int, _ lo: Int, _ hi: Int, fallback: Int) -> Int {
    guard value >= lo, value <= hi else { return min(max(fallback, lo), hi) }
    return value
  }
}

// MARK: - Scoring

struct RoundPreview: Equatable {
  struct Side: Equatable {
    var delta: Int
    var bags: Int
    var penalty: Int
  }
  var team1: Side
  var team2: Side

  subscript(team: TeamID) -> Side { team == .team1 ? team1 : team2 }
}

extension Game {
  /// Points and bags for one team before any bag penalty.
  /// Made bid: bid × 10 + 1 per overtrick. Set: −bid × 10. Nil: ± nil value.
  /// A team bid of 0 (no nil) scores nothing and every trick is a bag.
  func baseScore(_ round: TeamRound) -> (delta: Int, bags: Int) {
    var delta = round.nils.reduce(0) { $0 + ($1.made ? 1 : -1) * points(for: $1.kind) }
    var bags = 0
    if round.bid == 0 {
      bags = round.tricks
    } else if round.tricks >= round.bid {
      bags = round.tricks - round.bid
      delta += round.bid * 10 + bags
    } else {
      delta -= round.bid * 10
    }
    return (delta, bags)
  }

  func preview(_ round: Round) -> RoundPreview {
    func side(_ id: TeamID) -> RoundPreview.Side {
      let base = baseScore(round[id])
      let penalty = (self[id].bags + base.bags) / Self.bagsPerPenalty * Self.bagPenaltyPoints
      return .init(delta: base.delta - penalty, bags: base.bags, penalty: penalty)
    }
    return RoundPreview(team1: side(.team1), team2: side(.team2))
  }

  /// Applies a round. Ends the game when a team reaches the target and the
  /// scores aren't tied.
  mutating func commit(_ round: Round) {
    let p = preview(round)
    var round = round
    for id in TeamID.allCases {
      self[id].score += p[id].delta
      self[id].bags = (self[id].bags + p[id].bags) % Self.bagsPerPenalty
      round[id].delta = p[id].delta
      round[id].bagsAdded = p[id].bags
      round[id].bagPenalty = p[id].penalty
    }
    rounds.append(round)

    let someoneWon = team1.score >= target || team2.score >= target
    if someoneWon && team1.score != team2.score { phase = .gameover }
  }

  mutating func undoLastRound() {
    guard let last = rounds.popLast() else { return }
    for id in TeamID.allCases {
      self[id].score -= last[id].delta
      self[id].bags = rounds.reduce(0) { ($0 + $1[id].bagsAdded) % Self.bagsPerPenalty }
    }
    if phase == .gameover { phase = .playing }
  }

  /// Fresh game with remembered player names and default house rules.
  static func new(players: (team1: [String], team2: [String])?) -> Game {
    var game = Game()
    if let players {
      game.team1.players = players.team1
      game.team2.players = players.team2
    }
    return game
  }

  /// Same teams and house rules, scores cleared, straight into play.
  func rematch() -> Game {
    var game = Game()
    game.team1.players = team1.players
    game.team2.players = team2.players
    game.target = target
    game.nilPoints = nilPoints
    game.blindNilPoints = blindNilPoints
    game.nilPartnerMinBid = nilPartnerMinBid
    game.phase = .playing
    return game
  }
}

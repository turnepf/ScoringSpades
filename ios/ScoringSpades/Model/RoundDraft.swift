import Foundation
import Observation

enum Bid: Equatable {
  case tricks(Int)
  case nilBid(NilKind)

  var nilKind: NilKind? {
    if case .nilBid(let kind) = self { return kind }
    return nil
  }
  var number: Int? {
    if case .tricks(let n) = self { return n }
    return nil
  }
}

/// A round being entered: bids → tricks → preview. Discarded on cancel.
@Observable
final class RoundDraft {
  struct TeamDraft {
    var bids: [Bid?] = [nil, nil]
    var tricks: Int?
    var nilMade: [Bool?] = [nil, nil]
  }

  var team1 = TeamDraft()
  var team2 = TeamDraft()
  let nilPartnerMinBid: Int

  init(nilPartnerMinBid: Int) {
    self.nilPartnerMinBid = nilPartnerMinBid
  }

  subscript(team: TeamID) -> TeamDraft {
    get { team == .team1 ? team1 : team2 }
    set { if team == .team1 { team1 = newValue } else { team2 = newValue } }
  }

  // MARK: Bidding

  func minBid(team: TeamID, player: Int) -> Int {
    self[team].bids[1 - player]?.nilKind != nil ? nilPartnerMinBid : 0
  }

  func setBid(_ bid: Bid, team: TeamID, player: Int) {
    self[team].bids[player] = bid
    // Going nil can invalidate a partner bid already below the house minimum.
    if bid.nilKind != nil, let partner = self[team].bids[1 - player]?.number, partner < nilPartnerMinBid {
      self[team].bids[1 - player] = nil
    }
    // Keep nil answers in step with who is actually on nil.
    if bid.nilKind == nil { self[team].nilMade[player] = nil }
  }

  func teamBid(_ team: TeamID) -> Int { self[team].bids.compactMap { $0?.number }.reduce(0, +) }
  func nilCount(_ team: TeamID) -> Int { self[team].bids.filter { $0?.nilKind != nil }.count }

  /// "4", or "4 +1N" when a partner is on nil.
  func teamBidLabel(_ team: TeamID) -> String {
    let n = nilCount(team)
    return n > 0 ? "\(teamBid(team)) +\(n)N" : "\(teamBid(team))"
  }

  func isBidReady(_ team: TeamID) -> Bool {
    (0..<2).allSatisfy { player in
      guard let bid = self[team].bids[player] else { return false }
      if let n = bid.number { return n >= minBid(team: team, player: player) }
      return true
    }
  }

  var biddingComplete: Bool { isBidReady(.team1) && isBidReady(.team2) }

  // MARK: Tricks

  /// Team 2 defaults to 13 − team 1 until it's picked explicitly.
  func effectiveTricks(_ team: TeamID) -> Int? {
    if let t = self[team].tricks { return t }
    if team == .team2, let t1 = team1.tricks { return Game.tricksPerHand - t1 }
    return nil
  }

  func nilPlayers(_ team: TeamID) -> [(player: Int, kind: NilKind)] {
    (0..<2).compactMap { i in self[team].bids[i]?.nilKind.map { (i, $0) } }
  }

  var tricksComplete: Bool {
    TeamID.allCases.allSatisfy { team in
      effectiveTricks(team) != nil && nilPlayers(team).allSatisfy { self[team].nilMade[$0.player] != nil }
    }
  }

  func round() -> Round {
    func build(_ team: TeamID) -> TeamRound {
      TeamRound(
        bid: teamBid(team),
        tricks: effectiveTricks(team) ?? 0,
        nils: nilPlayers(team).map { NilResult(playerIndex: $0.player, kind: $0.kind, made: self[team].nilMade[$0.player] == true) }
      )
    }
    return Round(team1: build(.team1), team2: build(.team2))
  }
}

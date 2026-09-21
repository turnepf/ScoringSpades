import XCTest
@testable import ScoringSpades

/// Scoring must match the web app (public/index.html) exactly.
final class ScoringTests: XCTestCase {
  private func teamRound(bid: Int, tricks: Int, nils: [NilResult] = []) -> TeamRound {
    TeamRound(bid: bid, tricks: tricks, nils: nils)
  }

  private func round(_ t1: TeamRound, _ t2: TeamRound) -> Round { Round(team1: t1, team2: t2) }

  func testMadeBidScoresTenPerTrickPlusBags() {
    let game = Game()
    XCTAssertEqual(game.baseScore(teamRound(bid: 4, tricks: 5)).delta, 41)
    XCTAssertEqual(game.baseScore(teamRound(bid: 4, tricks: 5)).bags, 1)
    XCTAssertEqual(game.baseScore(teamRound(bid: 6, tricks: 6)).delta, 60)
  }

  func testSetLosesTenPerBidTrickWithNoBags() {
    let result = Game().baseScore(teamRound(bid: 4, tricks: 3))
    XCTAssertEqual(result.delta, -40)
    XCTAssertEqual(result.bags, 0)
  }

  func testZeroTeamBidMakesEveryTrickABag() {
    let result = Game().baseScore(teamRound(bid: 0, tricks: 3))
    XCTAssertEqual(result.delta, 0)
    XCTAssertEqual(result.bags, 3)
  }

  func testNilAndBlindNilUseConfiguredValues() {
    var game = Game()
    game.nilPoints = 50
    game.blindNilPoints = 400
    let nilMade = teamRound(bid: 5, tricks: 6, nils: [NilResult(playerIndex: 1, kind: .nilBid, made: true)])
    XCTAssertEqual(game.baseScore(nilMade).delta, 50 + 51)
    let blindFailed = teamRound(bid: 5, tricks: 4, nils: [NilResult(playerIndex: 0, kind: .blind, made: false)])
    XCTAssertEqual(game.baseScore(blindFailed).delta, -400 - 50)
  }

  func testTenBagsCostsHundredAndWraps() {
    var game = Game()
    game.phase = .playing
    game.team1.bags = 8
    game.commit(round(teamRound(bid: 3, tricks: 6), teamRound(bid: 7, tricks: 7)))
    // 30 + 3 bags = 33, 11 bags → −100, 1 bag carried.
    XCTAssertEqual(game.team1.score, -67)
    XCTAssertEqual(game.team1.bags, 1)
    XCTAssertEqual(game.rounds.last?.team1.bagPenalty, 100)
    XCTAssertEqual(game.team2.score, 70)
  }

  func testUndoRestoresScoresAndRecomputesBags() {
    var game = Game()
    game.phase = .playing
    game.commit(round(teamRound(bid: 4, tricks: 7), teamRound(bid: 6, tricks: 6)))
    game.commit(round(teamRound(bid: 2, tricks: 9), teamRound(bid: 4, tricks: 4)))
    XCTAssertEqual(game.team1.bags, 0)  // 3 + 7 = 10 → penalty, wrap
    game.undoLastRound()
    XCTAssertEqual(game.team1.score, 43)
    XCTAssertEqual(game.team1.bags, 3)
    XCTAssertEqual(game.team2.score, 60)
    XCTAssertEqual(game.rounds.count, 1)
  }

  func testGameEndsOnTargetUnlessTied() {
    var game = Game()
    game.phase = .playing
    game.target = 100
    game.team1.score = 90
    game.team2.score = 90
    game.commit(round(teamRound(bid: 1, tricks: 1), teamRound(bid: 1, tricks: 1)))
    XCTAssertEqual(game.phase, .playing, "tied at the target keeps playing")
    game.commit(round(teamRound(bid: 2, tricks: 2), teamRound(bid: 1, tricks: 1)))
    XCTAssertEqual(game.phase, .gameover)
    XCTAssertEqual(game.leader, .team1)
    game.undoLastRound()
    XCTAssertEqual(game.phase, .playing)
  }

  func testRematchKeepsTeamsAndHouseRules() {
    var game = Game()
    game.team1.players = ["A", "B"]
    game.team2.players = ["C", "D"]
    game.target = 300
    game.nilPoints = 50
    game.blindNilPoints = 400
    game.nilPartnerMinBid = 4
    game.team1.score = 310
    game.phase = .gameover
    let next = game.rematch()
    XCTAssertEqual(next.team1.players, ["A", "B"])
    XCTAssertEqual(next.target, 300)
    XCTAssertEqual(next.nilPartnerMinBid, 4)
    XCTAssertEqual(next.team1.score, 0)
    XCTAssertEqual(next.phase, .playing)
  }

  func testTeamLabel() {
    XCTAssertEqual(Team(players: ["Pat", "Dee"]).label, "Pat & Dee")
    XCTAssertEqual(Team(players: ["", "Dee"]).label, "Dee")
    XCTAssertEqual(Team(players: ["", ""]).label, "Team")
  }
}

final class RoundDraftTests: XCTestCase {
  func testTeamTwoTricksDefaultToRemainder() {
    let draft = RoundDraft(nilPartnerMinBid: 0)
    XCTAssertNil(draft.effectiveTricks(.team2))
    draft.team1.tricks = 8
    XCTAssertEqual(draft.effectiveTricks(.team2), 5)
    draft.team2.tricks = 4
    XCTAssertEqual(draft.effectiveTricks(.team2), 4)
  }

  func testNilPartnerMinimumBid() {
    let draft = RoundDraft(nilPartnerMinBid: 4)
    draft.setBid(.tricks(2), team: .team1, player: 0)
    draft.setBid(.nilBid(.nilBid), team: .team1, player: 1)
    XCTAssertNil(draft.team1.bids[0], "partner's too-low bid is cleared when they go nil")
    XCTAssertEqual(draft.minBid(team: .team1, player: 0), 4)
    draft.setBid(.tricks(3), team: .team1, player: 0)
    XCTAssertFalse(draft.isBidReady(.team1))
    draft.setBid(.tricks(5), team: .team1, player: 0)
    XCTAssertTrue(draft.isBidReady(.team1))
    XCTAssertEqual(draft.teamBidLabel(.team1), "5 +1N")
  }

  func testRoundRequiresNilAnswers() {
    let draft = RoundDraft(nilPartnerMinBid: 0)
    draft.setBid(.tricks(5), team: .team1, player: 0)
    draft.setBid(.nilBid(.blind), team: .team1, player: 1)
    draft.setBid(.tricks(3), team: .team2, player: 0)
    draft.setBid(.tricks(4), team: .team2, player: 1)
    XCTAssertTrue(draft.biddingComplete)
    draft.team1.tricks = 6
    XCTAssertFalse(draft.tricksComplete)
    draft.team1.nilMade[1] = true
    XCTAssertTrue(draft.tricksComplete)
    let round = draft.round()
    XCTAssertEqual(round.team1.bid, 5)
    XCTAssertEqual(round.team1.nils, [NilResult(playerIndex: 1, kind: .blind, made: true)])
    XCTAssertEqual(round.team2.tricks, 7)
  }
}

final class TipsTests: XCTestCase {
  func testConditionalTipsTakePriority() {
    var game = Game()
    game.team1.bags = 9
    let index = Tips.pick(for: game, current: nil)
    XCTAssertEqual(Tips.all[index].text(game), "Near 9 bags — consider taking a set on purpose to reset the bag count.")
  }

  func testUnconditionalTipsWhenNothingMatches() {
    let game = Game()
    for _ in 0..<20 {
      XCTAssertNil(Tips.all[Tips.pick(for: game, current: nil)].when)
    }
  }
}

/// `JSONDecoder` enforces types but not ranges, array lengths or invariants, and
/// Swift traps where JS coerces. These pin the repairs in `Game.normalized()` and
/// keep them matched to `loadState()` in public/index.html.
final class NormalizationTests: XCTestCase {

  // MARK: Player array length

  func testLabelIsTotalForShortPlayerArrays() {
    // Team.label used to subscript players[0] and players[1] unconditionally.
    XCTAssertEqual(Team(players: []).label, "Team")
    XCTAssertEqual(Team(players: ["Solo"]).label, "Solo")
  }

  func testNormalizePinsPlayersToExactlyTwo() {
    var game = Game()
    game.team1.players = []
    game.team2.players = ["A", "B", "C"]
    let g = game.normalized()
    XCTAssertEqual(g.team1.players, ["", ""])
    XCTAssertEqual(g.team2.players, ["A", "B"])
  }

  func testNormalizeCapsNameLength() {
    var game = Game()
    game.team1.players = [String(repeating: "x", count: 50), "Dee"]
    XCTAssertEqual(game.normalized().team1.players[0].count, Game.maxNameLength)
  }

  // MARK: House-rule values — fallbacks must match the web

  func testNormalizeRepairsHouseRuleValuesLikeTheWeb() {
    var game = Game()
    game.nilPoints = 0           // web: non-number or <= 0 -> 100
    game.blindNilPoints = -1     // web: non-number or <= 0 -> nilPoints * 2
    game.nilPartnerMinBid = -5   // web: < 0 -> 0
    let g = game.normalized()
    XCTAssertEqual(g.nilPoints, 100)
    XCTAssertEqual(g.blindNilPoints, 200)
    XCTAssertEqual(g.nilPartnerMinBid, 0)
  }

  func testNormalizeRejectsOutOfRangeTargetAndPoints() {
    var game = Game()
    game.target = Int.max
    game.nilPoints = Int.max
    let g = game.normalized()
    XCTAssertEqual(g.target, 500)
    XCTAssertEqual(g.nilPoints, 100)
  }

  func testNormalizeClampsNilPartnerMinBidToHandSize() {
    var game = Game()
    game.nilPartnerMinBid = 99   // above 13 makes the bid step unsatisfiable
    XCTAssertEqual(game.normalized().nilPartnerMinBid, 0)
  }

  // MARK: Arithmetic totality

  func testExtremeScoresDoNotTrapScoringOrTips() {
    var game = Game()
    game.team1.score = Int.max
    game.team2.score = Int.min
    game.team1.bags = Int.max
    let g = game.normalized()
    XCTAssertEqual(g.team1.score, 0)
    XCTAssertEqual(g.team2.score, 0)
    XCTAssertEqual(g.team1.bags, 0)
    // Tips predicates subtract scores; these used to overflow and trap.
    XCTAssertNoThrow(Tips.pick(for: g, current: nil))
  }

  func testUndoWithExtremeDeltaDoesNotTrap() {
    var game = Game()
    game.phase = .playing
    var tr = TeamRound(bid: 4, tricks: 4, nils: [])
    tr.delta = Int.min
    game.rounds = [Round(team1: tr, team2: tr)]
    var g = game.normalized()
    XCTAssertEqual(g.rounds[0].team1.delta, 0)
    g.undoLastRound()
    XCTAssertEqual(g.rounds.count, 0)
  }

  func testNormalizeDropsOutOfRangeNilPlayerIndex() {
    var game = Game()
    var tr = TeamRound(bid: 4, tricks: 4, nils: [
      NilResult(playerIndex: 0, kind: .nilBid, made: true),
      NilResult(playerIndex: 99, kind: .nilBid, made: false),
    ])
    tr.delta = 0
    game.rounds = [Round(team1: tr, team2: tr)]
    let g = game.normalized()
    XCTAssertEqual(g.rounds[0].team1.nils.map(\.playerIndex), [0])
  }

  // MARK: Display

  func testSignedStringIsTotalOverIntMin() {
    // `-Int.min` is not representable and used to trap.
    XCTAssertEqual(Int.min.signedString, "−9223372036854775808")
    XCTAssertEqual((-40).signedString, "−40")
    XCTAssertEqual(70.signedString, "+70")
    XCTAssertEqual(0.signedString, "+0")
  }

  // MARK: A valid game is left alone

  func testNormalizeIsIdentityOnAValidGame() {
    var game = Game.new(players: nil)
    game.team1.players = ["Patrick", "Dee"]
    game.team2.players = ["Marcus", "Linda"]
    game.phase = .playing
    XCTAssertEqual(game.normalized(), game)
  }
}

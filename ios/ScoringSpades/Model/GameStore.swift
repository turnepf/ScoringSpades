import Foundation
import Observation

/// Owns the current game and saves every change to UserDefaults, so a game
/// survives the app being closed.
@MainActor
@Observable
final class GameStore {
  private enum Key {
    static let game = "game.v1"
    static let lastPlayers = "lastPlayers.v1"
    static let tipsEnabled = "tipsEnabled"
  }

  private struct SavedPlayers: Codable {
    var team1: [String]
    var team2: [String]
  }

  private let defaults: UserDefaults

  var game: Game {
    didSet { save() }
  }

  var tipsEnabled: Bool {
    didSet { defaults.set(tipsEnabled, forKey: Key.tipsEnabled) }
  }

  private(set) var tipIndex: Int

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    let saved = defaults.data(forKey: Key.game)
      .flatMap { try? JSONDecoder().decode(Game.self, from: $0) }?
      .normalized()
    let game = saved ?? Game.new(players: Self.lastPlayers(in: defaults))
    self.game = game
    self.tipsEnabled = defaults.object(forKey: Key.tipsEnabled) as? Bool ?? true
    self.tipIndex = Tips.pick(for: game, current: nil)
  }

  var tipText: String { Tips.all[tipIndex].text(game) }

  // MARK: Actions

  func startGame() {
    guard game.allPlayersNamed else { return }
    game.phase = .playing
  }

  func returnToSetup() { game.phase = .setup }
  func endGame() { game.phase = .gameover }

  func commit(_ round: Round) {
    game.commit(round)
    tipIndex = Tips.pick(for: game, current: tipIndex)
  }

  func undoLastRound() {
    game.undoLastRound()
    tipIndex = Tips.pick(for: game, current: tipIndex)
  }

  func rematch() { game = game.rematch() }

  func newGame() {
    game = Game.new(players: Self.lastPlayers(in: defaults))
  }

  // MARK: Persistence

  private func save() {
    if let data = try? JSONEncoder().encode(game) { defaults.set(data, forKey: Key.game) }
    if game.allPlayersNamed,
       let data = try? JSONEncoder().encode(SavedPlayers(team1: game.team1.players, team2: game.team2.players)) {
      defaults.set(data, forKey: Key.lastPlayers)
    }
  }

  private static func lastPlayers(in defaults: UserDefaults) -> (team1: [String], team2: [String])? {
    guard let data = defaults.data(forKey: Key.lastPlayers),
          let saved = try? JSONDecoder().decode(SavedPlayers.self, from: data),
          saved.team1.count == 2, saved.team2.count == 2 else { return nil }
    return (saved.team1, saved.team2)
  }
}

import SwiftUI

struct GameOverView: View {
  @Environment(GameStore.self) private var store
  @State private var confirmingNewGame = false

  var body: some View {
    let game = store.game
    let winner = game.leader

    ScrollView {
      VStack(spacing: 16) {
        AppTitle()
          .frame(maxWidth: .infinity, alignment: .leading)

        VStack(spacing: 8) {
          Text("🏆").font(.system(size: 50))
          SectionLabel(winner == nil ? "Tied!" : "Winner")
          Text(winner.map { game[$0].label } ?? "Tie game")
            .font(.system(size: 32, weight: .heavy))
            .tracking(-0.5)
            .multilineTextAlignment(.center)
            .foregroundStyle(winner.map(Theme.color) ?? Theme.text)
          Text("\(game.team1.label) \(game.team1.score) · \(game.team2.label) \(game.team2.score)")
            .font(.callout)
            .foregroundStyle(Theme.muted)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 24)
        .background(Theme.surface, in: .rect(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.gold, lineWidth: 2) }
        .accessibilityElement(children: .combine)

        HStack(spacing: 12) {
          ScoreCard(team: .team1, isHighlighted: winner == .team1)
          ScoreCard(team: .team2, isHighlighted: winner == .team2)
        }

        HistoryCard()

        PrimaryButton("Rematch (same teams)") { store.rematch() }

        Card(padding: 16) {
          SectionLabel("Or").padding(.bottom, 10)
          GhostButton("New game (reset everything)", tint: Theme.danger) { confirmingNewGame = true }
        }
        .padding(.top, 8)

        FooterLinks()
      }
      .screenLayout()
      .padding(.vertical, 16)
    }
    .background(Theme.background)
    .toolbar(.hidden, for: .navigationBar)
    .sensoryFeedback(.success, trigger: game.phase)
    .confirmationDialog("Start a brand new game?", isPresented: $confirmingNewGame, titleVisibility: .visible) {
      Button("New Game", role: .destructive) { store.newGame() }
      Button("Cancel", role: .cancel) {}
    }
  }
}

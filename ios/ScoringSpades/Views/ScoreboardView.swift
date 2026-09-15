import SwiftUI

struct ScoreboardView: View {
  @Environment(GameStore.self) private var store
  @State private var draft: RoundDraft?
  @State private var confirming: Confirmation?

  private enum Confirmation: Identifiable {
    case setup, undo, end
    var id: Self { self }

    var title: String {
      switch self {
      case .setup: "Return to setup?"
      case .undo: "Undo last round?"
      case .end: "End game?"
      }
    }
    var message: String? {
      switch self {
      case .setup: "Current game will be saved."
      case .undo: nil
      case .end: "Current scores will stand."
      }
    }
    var action: String {
      switch self {
      case .setup: "Return to Setup"
      case .undo: "Undo Last Round"
      case .end: "End Game"
      }
    }
  }

  var body: some View {
    let game = store.game

    ScrollView {
      VStack(spacing: 16) {
        HStack {
          AppTitle(subtitle: "to \(game.target)")
          Spacer()
          Button {
            confirming = .setup
          } label: {
            Image(systemName: "gearshape.fill")
              .font(.title3)
              .foregroundStyle(Theme.text)
              .frame(width: 44, height: 44)
              .background(Theme.surface, in: .rect(cornerRadius: 12))
              .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.border) }
          }
          .accessibilityLabel("Settings")
        }

        HStack(spacing: 12) {
          ScoreCard(team: .team1, isHighlighted: game.leader == .team1)
          ScoreCard(team: .team2, isHighlighted: game.leader == .team2)
        }

        PrimaryButton("Score Round \(game.rounds.count + 1)") {
          draft = RoundDraft(nilPartnerMinBid: game.nilPartnerMinBid)
        }

        HistoryCard()

        HStack(spacing: 8) {
          GhostButton("Undo last") { confirming = .undo }
            .disabled(game.rounds.isEmpty)
          GhostButton("End game") { confirming = .end }
        }

        if !game.rounds.isEmpty && store.tipsEnabled {
          TipCard(text: store.tipText)
        }
      }
      .screenLayout()
      .padding(.vertical, 16)
    }
    .background(Theme.background)
    .toolbar(.hidden, for: .navigationBar)
    .fullScreenCover(item: $draft) { draft in
      RoundEntryView(draft: draft)
    }
    .confirmationDialog(confirming?.title ?? "", isPresented: Binding(
      get: { confirming != nil },
      set: { if !$0 { confirming = nil } }
    ), titleVisibility: .visible, presenting: confirming) { confirmation in
      Button(confirmation.action, role: confirmation == .setup ? nil : .destructive) {
        switch confirmation {
        case .setup: store.returnToSetup()
        case .undo: store.undoLastRound()
        case .end: store.endGame()
        }
      }
      Button("Cancel", role: .cancel) {}
    } message: { confirmation in
      if let message = confirmation.message { Text(message) }
    }
  }
}

extension RoundDraft: Identifiable {
  var id: ObjectIdentifier { ObjectIdentifier(self) }
}

struct ScoreCard: View {
  @Environment(GameStore.self) private var store
  let team: TeamID
  let isHighlighted: Bool

  var body: some View {
    let data = store.game[team]
    let color = Theme.color(team)

    VStack(spacing: 10) {
      Text(data.label.uppercased())
        .font(.subheadline.weight(.bold))
        .tracking(1)
        .foregroundStyle(color)
        .lineLimit(1)
        .minimumScaleFactor(0.7)

      Text("\(data.score)")
        .font(.system(size: 56, weight: .heavy, design: .default))
        .tracking(-2)
        .monospacedDigit()
        .foregroundStyle(Theme.text)
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .contentTransition(.numericText(value: Double(data.score)))

      VStack(spacing: 6) {
        HStack(spacing: 4) {
          ForEach(0..<Game.bagsPerPenalty, id: \.self) { i in
            Circle()
              .fill(i < data.bags ? Theme.gold : Theme.border)
              .frame(width: 9, height: 9)
          }
        }
        Text("\(data.bags) bag\(data.bags == 1 ? "" : "s")".uppercased())
          .font(.caption2)
          .tracking(0.5)
          .foregroundStyle(Theme.muted)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 20)
    .padding(.horizontal, 12)
    .background(Theme.surface, in: .rect(cornerRadius: 18))
    .overlay { RoundedRectangle(cornerRadius: 18).strokeBorder(color, lineWidth: 2) }
    .overlay {
      if isHighlighted {
        RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.gold, lineWidth: 2).padding(-2)
      }
    }
    .animation(.snappy, value: data.score)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(data.label): \(data.score) points, \(data.bags) bags")
  }
}

struct HistoryCard: View {
  @Environment(GameStore.self) private var store

  var body: some View {
    let game = store.game

    VStack(spacing: 0) {
      if game.rounds.isEmpty {
        Text("No rounds yet. Tap \u{201C}Score Round 1\u{201D} to begin.")
          .font(.subheadline)
          .foregroundStyle(Theme.muted)
          .multilineTextAlignment(.center)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 32)
          .padding(.horizontal, 16)
      } else {
        row(round: Text("ROUND"), team1: Text(game.team1.label.uppercased()), team2: Text(game.team2.label.uppercased()))
          .font(.caption2.weight(.bold))
          .tracking(1)
          .foregroundStyle(Theme.muted)
          .lineLimit(1)
          .background(Theme.background2)

        ForEach(Array(game.rounds.enumerated()), id: \.offset) { index, round in
          Divider().overlay(Theme.border)
          row(round: Text("\(index + 1)").font(.footnote.weight(.semibold)).foregroundStyle(Theme.muted),
              team1: cell(round.team1),
              team2: cell(round.team2))
            .accessibilityElement(children: .combine)
        }
      }
    }
    .background(Theme.surface, in: .rect(cornerRadius: 16))
    .clipShape(.rect(cornerRadius: 16))
    .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.border) }
  }

  private func row<A: View, B: View, C: View>(round: A, team1: B, team2: C) -> some View {
    HStack(spacing: 8) {
      round.frame(width: 50, alignment: .leading)
      team1.frame(maxWidth: .infinity)
      team2.frame(maxWidth: .infinity)
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
  }

  private func cell(_ result: TeamRound) -> some View {
    VStack(spacing: 2) {
      Text(result.delta.signedString)
        .font(.body.weight(.bold))
        .monospacedDigit()
        .foregroundStyle(result.delta >= 0 ? Theme.success : Theme.danger)
      Text(result.historySummary)
        .font(.caption2)
        .foregroundStyle(Theme.muted)
        .multilineTextAlignment(.center)
    }
  }
}

struct TipCard: View {
  let text: String

  var body: some View {
    VStack(alignment: .leading, spacing: 3) {
      Label("TIP", systemImage: "suit.spade.fill")
        .font(.caption2.weight(.bold))
        .tracking(0.5)
        .foregroundStyle(Theme.gold)
      Text(text)
        .font(.footnote)
        .foregroundStyle(Theme.muted)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, 12)
    .padding(.horizontal, 14)
    .background(Theme.background2, in: .rect(cornerRadius: 10))
    .overlay { RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.border) }
    .overlay(alignment: .leading) {
      UnevenRoundedRectangle(topLeadingRadius: 10, bottomLeadingRadius: 10).fill(Theme.gold).frame(width: 3)
    }
    .accessibilityElement(children: .combine)
  }
}

extension Int {
  /// "+70" / "−40"
  var signedString: String { self >= 0 ? "+\(self)" : "−\(-self)" }
}

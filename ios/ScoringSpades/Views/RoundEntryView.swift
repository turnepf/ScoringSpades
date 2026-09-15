import SwiftUI

/// Full-screen flow for scoring a round: Bidding → Tricks Taken → Round Score.
struct RoundEntryView: View {
  @Environment(GameStore.self) private var store
  @Environment(\.dismiss) private var dismiss
  let draft: RoundDraft
  @State private var path: [Step] = []

  enum Step: Hashable { case tricks, preview }

  var body: some View {
    NavigationStack(path: $path) {
      BiddingStep(draft: draft) { path.append(.tricks) }
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
          }
        }
        .navigationDestination(for: Step.self) { step in
          switch step {
          case .tricks:
            TricksStep(draft: draft) { path.append(.preview) }
          case .preview:
            PreviewStep(draft: draft) {
              store.commit(draft.round())
              dismiss()
            }
          }
        }
    }
    .tint(Theme.team1)
  }
}

// MARK: - Step chrome

private struct StepScaffold<Content: View>: View {
  @Environment(GameStore.self) private var store
  let headline: String
  let actionTitle: String
  let actionEnabled: Bool
  let action: () -> Void
  @ViewBuilder var content: Content

  var body: some View {
    ScrollView {
      VStack(spacing: 10) { content }
        .screenLayout(maxWidth: 600)
        .padding(.bottom, 16)
    }
    .background(Theme.background)
    .safeAreaInset(edge: .bottom) {
      PrimaryButton(actionTitle, action: action)
        .disabled(!actionEnabled)
        .screenLayout(maxWidth: 600)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(Theme.background)
    }
    .navigationTitle(headline)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .principal) {
        VStack(spacing: 0) {
          Text("ROUND \(store.game.rounds.count + 1)")
            .font(.caption2.weight(.bold))
            .tracking(1)
            .foregroundStyle(Theme.muted)
          Text(headline)
            .font(.headline.weight(.heavy))
            .foregroundStyle(Theme.text)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
      }
    }
    .toolbarBackground(Theme.background, for: .navigationBar)
  }
}

/// 0–13 in a 7-column grid.
private struct NumberGrid: View {
  let selected: Int?
  let tint: Color
  var minimum = 0
  var accessibilityPrefix: String
  let onSelect: (Int) -> Void

  var body: some View {
    Grid(horizontalSpacing: 4, verticalSpacing: 4) {
      ForEach([0, 7], id: \.self) { rowStart in
        GridRow {
          ForEach(rowStart..<rowStart + 7, id: \.self) { n in
            ChoiceButton(title: "\(n)", isSelected: selected == n, tint: tint, style: .filled,
                         font: .body.weight(.bold), height: 42) {
              onSelect(n)
            }
            .disabled(n < minimum)
            .accessibilityLabel("\(accessibilityPrefix) \(n)")
          }
        }
      }
    }
  }
}

// MARK: - Bidding

private struct BiddingStep: View {
  @Environment(GameStore.self) private var store
  let draft: RoundDraft
  let next: () -> Void

  var body: some View {
    StepScaffold(headline: "Bidding", actionTitle: "Next: Tricks", actionEnabled: draft.biddingComplete, action: next) {
      TallyBar(draft: draft)
      ForEach(TeamID.allCases) { team in
        Card(padding: 14, accent: Theme.color(team)) {
          SectionLabel(store.game[team].label, color: Theme.color(team))
            .padding(.bottom, 4)
          ForEach(0..<2, id: \.self) { player in
            if player == 1 { Divider().overlay(Theme.border).padding(.vertical, 10) }
            playerBid(team: team, player: player)
          }
        }
      }
    }
    .sensoryFeedback(.selection, trigger: draft.team1.bids)
    .sensoryFeedback(.selection, trigger: draft.team2.bids)
  }

  private func playerBid(team: TeamID, player: Int) -> some View {
    let name = store.game[team].players[player]
    let bid = draft[team].bids[player]
    let minimum = draft.minBid(team: team, player: player)
    let tint = Theme.color(team)

    return VStack(alignment: .leading, spacing: 6) {
      HStack(spacing: 0) {
        Text(name).font(.subheadline.weight(.bold)).foregroundStyle(Theme.text)
        if minimum > 0 {
          Text(" — min bid \(minimum) (partner nil)")
            .font(.caption.weight(.semibold))
            .foregroundStyle(Theme.muted)
        }
      }
      NumberGrid(selected: bid?.number, tint: tint, minimum: minimum, accessibilityPrefix: "\(name) bids") {
        draft.setBid(.tricks($0), team: team, player: player)
      }
      HStack(spacing: 4) {
        ForEach([NilKind.nilBid, .blind], id: \.self) { kind in
          ChoiceButton(title: kind == .blind ? "Blind Nil" : "Nil", isSelected: bid?.nilKind == kind,
                       tint: tint, style: .filled, font: .footnote.weight(.bold), height: 36) {
            draft.setBid(.nilBid(kind), team: team, player: player)
          }
          .accessibilityLabel("\(name) bids \(kind == .blind ? "blind nil" : "nil")")
        }
      }
    }
  }
}

private struct TallyBar: View {
  @Environment(GameStore.self) private var store
  let draft: RoundDraft

  var body: some View {
    let total = draft.teamBid(.team1) + draft.teamBid(.team2)
    let remaining = Game.tricksPerHand - total
    let remainText = remaining > 0 ? "\(remaining) unbid" : remaining < 0 ? "\(-remaining) over" : "tight (13)"
    let remainColor = remaining < 0 ? Theme.danger : remaining == 0 ? Theme.gold : Theme.muted

    HStack(spacing: 10) {
      side(.team1, alignment: .leading)
      VStack(spacing: 3) {
        Text("\(total)").font(.title2.weight(.heavy)).monospacedDigit()
        Text(remainText.uppercased()).font(.caption2.weight(.bold)).tracking(0.5).foregroundStyle(remainColor)
      }
      .padding(.horizontal, 8)
      side(.team2, alignment: .trailing)
    }
    .foregroundStyle(Theme.text)
    .padding(.vertical, 8)
    .padding(.horizontal, 12)
    .background(Theme.surface, in: .rect(cornerRadius: 12))
    .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.border) }
    .accessibilityElement(children: .combine)
  }

  private func side(_ team: TeamID, alignment: HorizontalAlignment) -> some View {
    VStack(alignment: alignment, spacing: 1) {
      Text(store.game[team].label.uppercased())
        .font(.caption2.weight(.bold))
        .tracking(0.5)
        .foregroundStyle(Theme.color(team))
        .lineLimit(1)
      Text(draft.teamBidLabel(team)).font(.title3.weight(.heavy)).monospacedDigit()
    }
    .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
  }
}

// MARK: - Tricks

private struct TricksStep: View {
  @Environment(GameStore.self) private var store
  let draft: RoundDraft
  let next: () -> Void

  var body: some View {
    StepScaffold(headline: "Tricks Taken", actionTitle: "Preview Score", actionEnabled: draft.tricksComplete, action: next) {
      ForEach(TeamID.allCases) { team in
        teamCard(team)
      }
    }
    .sensoryFeedback(.selection, trigger: draft.team1.tricks)
    .sensoryFeedback(.selection, trigger: draft.team2.tricks)
  }

  private func teamCard(_ team: TeamID) -> some View {
    let data = store.game[team]
    let tint = Theme.color(team)
    let detail = (0..<2).map { i -> String in
      switch draft[team].bids[i] {
      case .nilBid(.nilBid): "\(data.players[i]): nil"
      case .nilBid(.blind): "\(data.players[i]): blind"
      case .tricks(let n): "\(data.players[i]): \(n)"
      case nil: data.players[i]
      }
    }.joined(separator: " · ")

    return Card(padding: 14, accent: tint) {
      HStack(alignment: .center, spacing: 12) {
        VStack(alignment: .leading, spacing: 2) {
          Text(data.label.uppercased())
            .font(.subheadline.weight(.bold))
            .tracking(0.5)
            .foregroundStyle(tint)
          Text(detail).font(.caption).foregroundStyle(Theme.muted)
        }
        Spacer()
        VStack(alignment: .trailing, spacing: 0) {
          Text("BID").font(.system(size: 9, weight: .bold)).tracking(1).foregroundStyle(Theme.muted)
          Text(draft.teamBidLabel(team)).font(.title2.weight(.heavy)).monospacedDigit().foregroundStyle(tint)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(Theme.background2, in: .rect(cornerRadius: 10))
      }
      .padding(.bottom, 8)

      Text("Tricks won by team")
        .font(.callout)
        .foregroundStyle(Theme.muted)
        .padding(.bottom, 10)

      NumberGrid(selected: draft.effectiveTricks(team), tint: tint, accessibilityPrefix: "\(data.label) took") {
        draft[team].tricks = $0
      }

      ForEach(draft.nilPlayers(team), id: \.player) { entry in
        Divider().overlay(Theme.border).padding(.vertical, 10)
        Text("Did \(data.players[entry.player]) make \(entry.kind.label)?")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(Theme.text)
          .padding(.bottom, 6)
        HStack(spacing: 6) {
          ChoiceButton(title: "Yes ✓", isSelected: draft[team].nilMade[entry.player] == true,
                       tint: Theme.success, style: .filled, height: 46) {
            draft[team].nilMade[entry.player] = true
          }
          ChoiceButton(title: "No ✗", isSelected: draft[team].nilMade[entry.player] == false,
                       tint: Theme.danger, style: .filled, height: 46) {
            draft[team].nilMade[entry.player] = false
          }
        }
      }
    }
  }
}

// MARK: - Preview

private struct PreviewStep: View {
  @Environment(GameStore.self) private var store
  let draft: RoundDraft
  let confirm: () -> Void

  var body: some View {
    let game = store.game
    let round = draft.round()
    let preview = game.preview(round)

    StepScaffold(headline: "Round Score", actionTitle: "Confirm", actionEnabled: true, action: confirm) {
      Card {
        ForEach(TeamID.allCases) { team in
          if team == .team2 { Divider().overlay(Theme.border).padding(.vertical, 10) }
          HStack {
            VStack(alignment: .leading, spacing: 2) {
              Text(game[team].label).font(.body.weight(.semibold)).foregroundStyle(Theme.color(team))
              Text(detail(team: team, round: round[team], side: preview[team]))
                .font(.caption)
                .foregroundStyle(Theme.muted)
            }
            Spacer()
            Text(preview[team].delta.signedString)
              .font(.title2.weight(.heavy))
              .monospacedDigit()
              .foregroundStyle(preview[team].delta >= 0 ? Theme.success : Theme.danger)
          }
          .accessibilityElement(children: .combine)
        }
      }

      Card {
        HStack {
          Text("New totals").font(.body.weight(.semibold)).foregroundStyle(Theme.text)
          Spacer()
          Text("\(game.team1.score + preview.team1.delta)").foregroundStyle(Theme.team1)
          Text("·").foregroundStyle(Theme.muted).padding(.horizontal, 4)
          Text("\(game.team2.score + preview.team2.delta)").foregroundStyle(Theme.team2)
        }
        .font(.title3.weight(.heavy))
        .monospacedDigit()
        .accessibilityElement(children: .combine)
      }
    }
  }

  private func detail(team: TeamID, round: TeamRound, side: RoundPreview.Side) -> String {
    var parts = ["bid \(round.bid), took \(round.tricks)"]
    for n in round.nils {
      parts.append("\(store.game[team].players[n.playerIndex]) \(n.kind.label): \(n.made ? "made ✓" : "failed ✗")")
    }
    if side.bags > 0 { parts.append("+\(side.bags) bag\(side.bags == 1 ? "" : "s")") }
    if side.penalty > 0 { parts.append("−\(side.penalty) bag penalty") }
    return parts.joined(separator: " · ")
  }
}

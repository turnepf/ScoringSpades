import SwiftUI

struct SetupView: View {
  @Environment(GameStore.self) private var store
  @FocusState private var focusedField: Field?

  private enum Field: Hashable { case player(TeamID, Int) }

  var body: some View {
    @Bindable var store = store

    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        AppTitle()
          .padding(.bottom, 6)

        Card(padding: 22) {
          VStack(alignment: .leading, spacing: 20) {
            teamFields(.team1, labels: ["Player 1", "Partner"])
            teamFields(.team2, labels: ["Player 3", "Partner"])

            PresetPicker(title: "Play to", presets: [250, 300, 500], prompt: "Target score?",
                         allowed: 1...Game.maxTarget, value: $store.game.target)

            SettingField(title: "House rules") {
              NavigationLink(value: Route.houseRules) {
                HStack(spacing: 12) {
                  VStack(alignment: .leading, spacing: 2) {
                    Text("Nil values & partner minimum")
                      .font(.body.weight(.semibold))
                      .foregroundStyle(Theme.text)
                    Text(store.game.houseRulesSummary)
                      .font(.footnote)
                      .foregroundStyle(Theme.muted)
                  }
                  Spacer()
                  Image(systemName: "chevron.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Theme.muted)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(Theme.surface2, in: .rect(cornerRadius: 12))
                .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.border, lineWidth: 2) }
                .contentShape(.rect)
              }
              .buttonStyle(PressableStyle())
              .accessibilityLabel("House Rules")
              .accessibilityValue(store.game.houseRulesSummary)
            }

            SettingField(title: "Tips",
                         hint: "Strategy tips appear under the scoreboard while you play — picked based on the game state (bags, sets, nils, score gap).") {
              HStack(spacing: 8) {
                ChoiceButton(title: "On", isSelected: store.tipsEnabled) { store.tipsEnabled = true }
                ChoiceButton(title: "Off", isSelected: !store.tipsEnabled) { store.tipsEnabled = false }
              }
            }
            .sensoryFeedback(.selection, trigger: store.tipsEnabled)
          }
        }

        PrimaryButton("Start Game") {
          focusedField = nil
          store.startGame()
        }
        .disabled(!store.game.allPlayersNamed)
        .padding(.top, 4)

        if !store.game.allPlayersNamed {
          Text("Enter all 4 player names to start.")
            .font(.footnote)
            .foregroundStyle(Theme.muted)
            .frame(maxWidth: .infinity)
        }

        FooterLinks()
      }
      .screenLayout()
      .padding(.vertical, 16)
    }
    .scrollDismissesKeyboard(.interactively)
    .background(Theme.background)
    .toolbar(.hidden, for: .navigationBar)
  }

  // MARK: Pieces

  private func teamFields(_ team: TeamID, labels: [String]) -> some View {
    @Bindable var store = store
    return VStack(alignment: .leading, spacing: 8) {
      SectionLabel(team == .team1 ? "Team 1" : "Team 2", color: Theme.color(team))
      HStack(spacing: 10) {
        ForEach(0..<2, id: \.self) { i in
          VStack(alignment: .leading, spacing: 6) {
            Text(labels[i].uppercased())
              .font(.caption2.weight(.semibold))
              .tracking(1)
              .foregroundStyle(Theme.muted)
            TextField("", text: nameBinding(team, i))
              .font(.title3.weight(.medium))
              .textInputAutocapitalization(.words)
              .autocorrectionDisabled()
              .submitLabel(isLastField(team, i) ? .done : .next)
              .focused($focusedField, equals: .player(team, i))
              .onSubmit { advanceFocus(from: team, i) }
              .padding(16)
              .background(Theme.surface2, in: .rect(cornerRadius: 12))
              .overlay {
                RoundedRectangle(cornerRadius: 12)
                  .strokeBorder(focusedField == .player(team, i) ? Theme.team1 : Theme.border)
              }
              .accessibilityLabel("\(team == .team1 ? "Team 1" : "Team 2") \(labels[i])")
          }
        }
      }
    }
  }

  private func nameBinding(_ team: TeamID, _ i: Int) -> Binding<String> {
    Binding(
      get: { store.game[team].players[i] },
      set: { store.game[team].players[i] = String($0.prefix(15)) }
    )
  }

  private func isLastField(_ team: TeamID, _ i: Int) -> Bool { team == .team2 && i == 1 }

  private func advanceFocus(from team: TeamID, _ i: Int) {
    let order: [Field] = [.player(.team1, 0), .player(.team1, 1), .player(.team2, 0), .player(.team2, 1)]
    guard let index = order.firstIndex(of: .player(team, i)) else { return }
    focusedField = index + 1 < order.count ? order[index + 1] : nil
  }
}

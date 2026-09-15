import SwiftUI

struct SetupView: View {
  @Environment(GameStore.self) private var store
  @FocusState private var focusedField: Field?
  @State private var customPrompt: CustomValue?
  @State private var customText = ""

  private enum Field: Hashable { case player(TeamID, Int) }

  /// A setting that offers presets plus a typed-in custom value.
  private enum CustomValue: Identifiable {
    case target, nilPoints, blindNilPoints
    var id: Self { self }

    var prompt: String {
      switch self {
      case .target: "Target score?"
      case .nilPoints: "Points for making nil?"
      case .blindNilPoints: "Points for making blind nil?"
      }
    }

    var keyPath: WritableKeyPath<Game, Int> {
      switch self {
      case .target: \.target
      case .nilPoints: \.nilPoints
      case .blindNilPoints: \.blindNilPoints
      }
    }
  }

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

            presetField("Play to", value: .target, presets: [250, 300, 500])
            presetField("Nil is worth", value: .nilPoints, presets: [50, 100, 200],
                        hint: "Points won or lost on a nil bid (standard is 100).")
            presetField("Blind nil is worth", value: .blindNilPoints, presets: [100, 200, 400],
                        hint: "Points won or lost on a blind nil bid (standard is 200).")

            field("Nil partner's minimum bid",
                  hint: "House rule: when a player bids nil, their partner must bid at least this much. \"None\" allows any bid.") {
              HStack(spacing: 8) {
                ForEach([0, 3, 4, 5], id: \.self) { value in
                  ChoiceButton(title: value == 0 ? "None" : "\(value)",
                               isSelected: store.game.nilPartnerMinBid == value) {
                    store.game.nilPartnerMinBid = value
                  }
                }
              }
            }

            field("Tips",
                  hint: "Strategy tips appear under the scoreboard while you play — picked based on the game state (bags, sets, nils, score gap).") {
              HStack(spacing: 8) {
                ChoiceButton(title: "On", isSelected: store.tipsEnabled) { store.tipsEnabled = true }
                ChoiceButton(title: "Off", isSelected: !store.tipsEnabled) { store.tipsEnabled = false }
              }
            }
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
    .sensoryFeedback(.selection, trigger: store.game.target)
    .sensoryFeedback(.selection, trigger: store.game.nilPoints)
    .sensoryFeedback(.selection, trigger: store.game.blindNilPoints)
    .sensoryFeedback(.selection, trigger: store.game.nilPartnerMinBid)
    .sensoryFeedback(.selection, trigger: store.tipsEnabled)
    .alert(customPrompt?.prompt ?? "", isPresented: Binding(
      get: { customPrompt != nil },
      set: { if !$0 { customPrompt = nil } }
    )) {
      TextField("Points", text: $customText)
        .keyboardType(.numberPad)
      Button("Cancel", role: .cancel) {}
      Button("OK") {
        if let custom = customPrompt, let n = Int(customText.trimmingCharacters(in: .whitespaces)), n > 0 {
          store.game[keyPath: custom.keyPath] = n
        }
      }
    }
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

  private func presetField(_ title: String, value: CustomValue, presets: [Int], hint: String? = nil) -> some View {
    let current = store.game[keyPath: value.keyPath]
    let isCustom = !presets.contains(current)
    return field(title, hint: hint) {
      HStack(spacing: 8) {
        ForEach(presets, id: \.self) { preset in
          ChoiceButton(title: "\(preset)", isSelected: current == preset) {
            store.game[keyPath: value.keyPath] = preset
          }
        }
        ChoiceButton(title: isCustom ? "\(current)" : "Custom", isSelected: isCustom) {
          customText = "\(current)"
          customPrompt = value
        }
        .accessibilityLabel(isCustom ? "Custom, \(current)" : "Custom")
      }
    }
  }

  private func field<Content: View>(_ title: String, hint: String? = nil, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      SectionLabel(title)
      content()
      if let hint {
        Text(hint)
          .font(.footnote)
          .foregroundStyle(Theme.muted)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }
}

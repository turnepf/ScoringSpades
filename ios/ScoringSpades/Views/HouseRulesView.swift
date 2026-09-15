import SwiftUI

/// Nil values and the nil-partner minimum bid, reached from the setup screen.
struct HouseRulesView: View {
  @Environment(GameStore.self) private var store

  var body: some View {
    @Bindable var store = store

    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        Card(padding: 22) {
          VStack(alignment: .leading, spacing: 20) {
            PresetPicker(title: "Nil is worth", presets: [50, 100, 200],
                         prompt: "Points for making nil?",
                         hint: "Points won or lost on a nil bid (standard is 100).",
                         value: $store.game.nilPoints)
            PresetPicker(title: "Blind nil is worth", presets: [100, 200, 400],
                         prompt: "Points for making blind nil?",
                         hint: "Points won or lost on a blind nil bid (standard is 200).",
                         value: $store.game.blindNilPoints)
            SettingField(title: "Nil partner's minimum bid",
                         hint: "When a player bids nil, their partner must bid at least this much. \"None\" allows any bid.") {
              HStack(spacing: 8) {
                ForEach([0, 3, 4, 5], id: \.self) { minimum in
                  ChoiceButton(title: minimum == 0 ? "None" : "\(minimum)",
                               isSelected: store.game.nilPartnerMinBid == minimum) {
                    store.game.nilPartnerMinBid = minimum
                  }
                }
              }
            }
            .sensoryFeedback(.selection, trigger: store.game.nilPartnerMinBid)
          }
        }

        Text("House rules are saved with the game and carry over to rematches. Changes apply to rounds scored from now on.")
          .font(.footnote)
          .foregroundStyle(Theme.muted)
          .padding(.horizontal, 4)
      }
      .screenLayout()
      .padding(.vertical, 12)
    }
    .background(Theme.background)
    .navigationTitle("House Rules")
    .navigationBarTitleDisplayMode(.large)
    .toolbarBackground(Theme.background, for: .navigationBar)
  }
}

extension Game {
  /// "Nil 100 · Blind nil 200 · Partner min none"
  var houseRulesSummary: String {
    let minimum = nilPartnerMinBid == 0 ? "none" : "\(nilPartnerMinBid)"
    return "Nil \(nilPoints) · Blind nil \(blindNilPoints) · Partner min \(minimum)"
  }
}

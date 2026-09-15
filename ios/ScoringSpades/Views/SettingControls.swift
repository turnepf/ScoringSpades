import SwiftUI

/// Labeled setting with an optional explanatory hint underneath.
struct SettingField<Content: View>: View {
  let title: String
  var hint: String?
  @ViewBuilder var content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      SectionLabel(title)
      content
      if let hint {
        Text(hint)
          .font(.footnote)
          .foregroundStyle(Theme.muted)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }
}

/// Preset values plus a "Custom" button that asks for any positive number.
struct PresetPicker: View {
  let title: String
  let presets: [Int]
  let prompt: String
  var hint: String?
  @Binding var value: Int

  @State private var isPrompting = false
  @State private var customText = ""

  var body: some View {
    let isCustom = !presets.contains(value)

    SettingField(title: title, hint: hint) {
      HStack(spacing: 8) {
        ForEach(presets, id: \.self) { preset in
          ChoiceButton(title: "\(preset)", isSelected: value == preset) { value = preset }
        }
        ChoiceButton(title: isCustom ? "\(value)" : "Custom", isSelected: isCustom) {
          customText = "\(value)"
          isPrompting = true
        }
        .accessibilityLabel(isCustom ? "Custom, \(value)" : "Custom")
      }
    }
    .sensoryFeedback(.selection, trigger: value)
    .alert(prompt, isPresented: $isPrompting) {
      TextField("Points", text: $customText)
        .keyboardType(.numberPad)
      Button("Cancel", role: .cancel) {}
      Button("OK") {
        if let n = Int(customText.trimmingCharacters(in: .whitespaces)), n > 0 { value = n }
      }
    }
  }
}

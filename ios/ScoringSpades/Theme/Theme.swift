import SwiftUI

/// The Scoring Spades palette: card-table green in dark mode, soft sage in
/// light mode, orange for team 1 and blue for team 2.
enum Theme {
  static let background = Color(light: 0xEEF3EE, dark: 0x0F1F1A)
  static let background2 = Color(light: 0xE3EBE4, dark: 0x14271F)
  static let surface = Color(light: 0xFFFFFF, dark: 0x1C3329)
  static let surface2 = Color(light: 0xF0F4F0, dark: 0x244035)
  static let border = Color(light: 0xD3DDD5, dark: 0x2E4A3E)
  static let text = Color(light: 0x15241C, dark: 0xF5F0E6)
  static let muted = Color(light: 0x5D7066, dark: 0x8AA599)
  static let team1 = Color(light: 0xC75A12, dark: 0xE67E22)
  static let team2 = Color(light: 0x1F72B8, dark: 0x3498DB)
  static let success = Color(light: 0x1E8A4C, dark: 0x27AE60)
  static let danger = Color(light: 0xC0392B, dark: 0xE74C3C)
  static let gold = Color(light: 0xB07D00, dark: 0xF1C40F)

  static func color(_ team: TeamID) -> Color { team == .team1 ? team1 : team2 }

  static let githubURL = URL(string: "https://github.com/turnepf/ScoringSpades")!
}

extension Color {
  init(light: UInt32, dark: UInt32) {
    self.init(uiColor: UIColor { traits in
      let hex = traits.userInterfaceStyle == .dark ? dark : light
      return UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255,
                     green: CGFloat((hex >> 8) & 0xFF) / 255,
                     blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    })
  }
}

// MARK: - Shared components

/// Rounded panel used for every section.
struct Card<Content: View>: View {
  var padding: CGFloat = 20
  var accent: Color?
  @ViewBuilder var content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 0) { content }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(padding)
      .background(Theme.surface, in: .rect(cornerRadius: 16))
      .overlay(alignment: .leading) {
        if let accent {
          UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16)
            .fill(accent).frame(width: 4)
        }
      }
      .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.border) }
  }
}

/// Small uppercase section label.
struct SectionLabel: View {
  let text: String
  var color: Color = Theme.muted

  init(_ text: String, color: Color = Theme.muted) {
    self.text = text
    self.color = color
  }

  var body: some View {
    Text(text.uppercased())
      .font(.caption.weight(.bold))
      .tracking(1)
      .foregroundStyle(color)
  }
}

/// Selectable pill, used for presets like "500" or "Nil".
struct ChoiceButton: View {
  let title: String
  let isSelected: Bool
  var tint: Color = Theme.team1
  var style: Style = .outline
  var font: Font = .body.weight(.bold)
  var height: CGFloat = 50
  let action: () -> Void

  enum Style { case outline, filled }

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(font)
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(maxWidth: .infinity, minHeight: height)
        .foregroundStyle(foreground)
        .background(background, in: .rect(cornerRadius: 12))
        .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(isSelected ? tint : Theme.border, lineWidth: 2) }
        .contentShape(.rect)
    }
    .buttonStyle(PressableStyle())
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }

  private var foreground: Color {
    guard isSelected else { return Theme.text }
    return style == .filled ? .white : tint
  }

  private var background: Color {
    guard isSelected else { return Theme.surface2 }
    return style == .filled ? tint : tint.opacity(0.15)
  }
}

/// Full-width call-to-action button.
struct PrimaryButton: View {
  let title: String
  var tint: Color = Theme.team1
  let action: () -> Void

  init(_ title: String, tint: Color = Theme.team1, action: @escaping () -> Void) {
    self.title = title
    self.tint = tint
    self.action = action
  }

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.title3.weight(.bold))
        .frame(maxWidth: .infinity, minHeight: 60)
        .foregroundStyle(.white)
        .background(tint, in: .rect(cornerRadius: 16))
        .contentShape(.rect)
    }
    .buttonStyle(PressableStyle())
  }
}

/// Outlined secondary button ("Undo last", "End game").
struct GhostButton: View {
  let title: String
  var tint: Color = Theme.muted
  let action: () -> Void

  init(_ title: String, tint: Color = Theme.muted, action: @escaping () -> Void) {
    self.title = title
    self.tint = tint
    self.action = action
  }

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.body.weight(.semibold))
        .frame(maxWidth: .infinity, minHeight: 50)
        .foregroundStyle(tint)
        .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(tint == Theme.muted ? Theme.border : tint) }
        .contentShape(.rect)
    }
    .buttonStyle(PressableStyle())
  }
}

struct PressableStyle: ButtonStyle {
  @Environment(\.isEnabled) private var isEnabled

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.97 : 1)
      .opacity(isEnabled ? 1 : 0.35)
      .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
  }
}

/// App title with the spade, used at the top of the main screens.
struct AppTitle: View {
  var subtitle: String?

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 8) {
      Image(systemName: "suit.spade.fill")
        .font(.title2)
      Text("Scoring Spades")
        .font(.system(size: 26, weight: .bold))
        .tracking(-0.5)
      if let subtitle {
        Text(subtitle)
          .font(.footnote.weight(.medium))
          .foregroundStyle(Theme.muted)
      }
    }
    .foregroundStyle(Theme.text)
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(.isHeader)
  }
}

extension View {
  /// Centers content in a readable column on iPad and gives it the app background.
  func screenLayout(maxWidth: CGFloat = 640) -> some View {
    frame(maxWidth: maxWidth)
      .frame(maxWidth: .infinity)
      .padding(.horizontal, 16)
  }
}

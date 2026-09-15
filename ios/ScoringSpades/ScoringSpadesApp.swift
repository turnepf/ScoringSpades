import SwiftUI

@main
struct ScoringSpadesApp: App {
  @State private var store = GameStore(defaults: .appDefaults)

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(store)
    }
  }
}

extension UserDefaults {
  /// UI tests launch with `-uiTestFreshState` to start from an empty store.
  static var appDefaults: UserDefaults {
    guard ProcessInfo.processInfo.arguments.contains("-uiTestFreshState") else { return .standard }
    let suite = "ScoringSpadesUITests"
    let defaults = UserDefaults(suiteName: suite)!
    if !ProcessInfo.processInfo.arguments.contains("-uiTestKeepState") {
      defaults.removePersistentDomain(forName: suite)
    }
    return defaults
  }
}

enum Route: Hashable {
  case howToPlay, privacy
}

struct RootView: View {
  @Environment(GameStore.self) private var store

  var body: some View {
    NavigationStack {
      Group {
        switch store.game.phase {
        case .setup: SetupView()
        case .playing: ScoreboardView()
        case .gameover: GameOverView()
        }
      }
      .navigationDestination(for: Route.self) { route in
        switch route {
        case .howToPlay: HowToPlayView()
        case .privacy: PrivacyView()
        }
      }
    }
    .tint(Theme.team1)
  }
}

/// How to Play · Privacy · GitHub, at the bottom of setup and game over.
struct FooterLinks: View {
  var body: some View {
    ViewThatFits {
      HStack(spacing: 10) { pageLinks; githubLink }
      VStack(spacing: 10) {
        HStack(spacing: 10) { pageLinks }
        githubLink
      }
    }
    .font(.subheadline)
    .frame(maxWidth: .infinity)
    .padding(.top, 8)
  }

  @ViewBuilder private var pageLinks: some View {
    NavigationLink("How to Play", value: Route.howToPlay).buttonStyle(FooterLinkStyle())
    NavigationLink("Privacy", value: Route.privacy).buttonStyle(FooterLinkStyle())
  }

  private var githubLink: some View {
    Link(destination: Theme.githubURL) {
      Label("Launch your own ScoringSpades app", systemImage: "arrow.up.right")
        .labelStyle(TrailingIconLabelStyle())
    }
    .buttonStyle(FooterLinkStyle())
  }
}

struct FooterLinkStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundStyle(configuration.isPressed ? Theme.text : Theme.muted)
      .padding(.vertical, 8)
      .padding(.horizontal, 14)
      .overlay { Capsule().strokeBorder(Theme.border) }
      .contentShape(Capsule())
  }
}

struct TrailingIconLabelStyle: LabelStyle {
  func makeBody(configuration: Configuration) -> some View {
    HStack(spacing: 4) {
      configuration.title
      configuration.icon.imageScale(.small)
    }
  }
}

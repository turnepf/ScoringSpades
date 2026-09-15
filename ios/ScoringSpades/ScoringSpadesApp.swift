import SwiftUI

@main
struct ScoringSpadesApp: App {
  var body: some Scene {
    WindowGroup {
      ScorekeeperView()
        .background(Color("LaunchBackground"))
        .ignoresSafeArea()
    }
  }
}

/// The web app handles safe-area insets itself (viewport-fit=cover + env()),
/// so the web view runs edge to edge.
struct ScorekeeperView: UIViewControllerRepresentable {
  func makeUIViewController(context: Context) -> WebViewController { WebViewController() }
  func updateUIViewController(_ controller: WebViewController, context: Context) {}
}

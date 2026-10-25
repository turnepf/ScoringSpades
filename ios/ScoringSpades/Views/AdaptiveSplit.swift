import SwiftUI

/// A screen's main content plus a supporting panel (the round history).
/// Side by side when the container is wider than it is tall, stacked when it
/// is taller; on iOS 27.1+ an `ArrangementView` also keeps both sides clear of
/// iPhone Duo's fold.
///
/// A tight pose (iPhone Duo closed and held in landscape) can show only
/// `primary`, so every control belongs there, never only in `secondary`.
/// Each side scrolls on its own, so don't nest this in a ScrollView or List.
struct AdaptiveSplit<Primary: View, Secondary: View>: View {
  /// Stacked, let `primary` take the height it needs and `secondary` the rest.
  var primaryHugsHeight = true
  @ViewBuilder var primary: Primary
  @ViewBuilder var secondary: Secondary

  var body: some View {
    if #available(iOS 27.1, *) {
      ArrangementView {
        column { primary }
          .splitArrangementFixedLayoutSize(horizontal: false, vertical: primaryHugsHeight)
      } secondary: {
        column { secondary }
      }
      .arrangementViewStyle(.split)
    } else {
      GeometryReader { proxy in
        if proxy.size.width > proxy.size.height {
          HStack(spacing: 0) {
            column { primary }
            column { secondary }
          }
        } else {
          column {
            primary
            secondary
          }
        }
      }
    }
  }

  private func column(@ViewBuilder _ content: () -> some View) -> some View {
    ScrollView {
      VStack(spacing: 16) { content() }
        .screenLayout()
        .padding(.vertical, 16)
    }
  }
}

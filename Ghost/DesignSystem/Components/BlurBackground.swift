import SwiftUI

/// A translucent, slightly blurred surface used for cards and sheets over
/// the dark background — keeps depth without introducing hard edges.
struct BlurBackground: View {
    var cornerRadius: CGFloat = Theme.Radius.lg

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.ghostTextPrimary.opacity(0.06))
            )
    }
}

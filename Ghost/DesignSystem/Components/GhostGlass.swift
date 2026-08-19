import SwiftUI

/// A Liquid Glass surface, tuned for Ghost.
///
/// Now that the deployment target is iOS 26 this is the real thing — no
/// `#available` branches, no `.ultraThinMaterial` impersonation. What's
/// added on top of the system effect is the hairline: a bone-white edge
/// that runs bright at the top-leading corner and fades to nothing at the
/// bottom-trailing one, as though a single low light sat above the frame.
/// System glass alone reads as translucent; the directional hairline is
/// what makes it read as a cut edge.
struct GhostGlass<Content: View>: View {
    enum Style {
        /// Neutral glass. The default for anything the interface owns.
        case regular
        /// Reacts to touch — use for anything tappable.
        case interactive
        /// Maple-tinted. Reserved for surfaces that are Ghost speaking,
        /// so the tint always means "this is the presence, not the app".
        case ember
    }

    var style: Style = .regular
    var cornerRadius: CGFloat = Theme.Radius.lg
    @ViewBuilder var content: Content

    init(
        style: Style = .regular,
        cornerRadius: CGFloat = Theme.Radius.lg,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        content
            .glassEffect(glass, in: shape)
            .overlay {
                shape.strokeBorder(Self.hairline, lineWidth: 0.8)
            }
    }

    private var glass: Glass {
        switch style {
        case .regular: .regular
        case .interactive: .regular.interactive()
        case .ember: .regular.tint(Color.ghostMaple.opacity(0.26))
        }
    }

    /// Lit from the top-leading corner, extinguished at the far one.
    private static let hairline = LinearGradient(
        colors: [
            Theme.hairline(Theme.Hairline.bright),
            Theme.hairline(Theme.Hairline.regular),
            Theme.hairline(Theme.Hairline.faint),
            .clear
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

/// Groups sibling glass surfaces so they share one lighting model and can
/// morph into each other rather than cross-fading.
struct GhostGlassContainer<Content: View>: View {
    var spacing: CGFloat = 0
    @ViewBuilder var content: Content

    init(spacing: CGFloat = 0, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        GlassEffectContainer(spacing: spacing) {
            content
        }
    }
}

#Preview {
    ZStack {
        GhostAtmosphereBackground()
        GhostGlassContainer(spacing: Theme.Spacing.lg) {
            VStack(spacing: Theme.Spacing.lg) {
                GhostGlass {
                    Text("Regular")
                        .font(.ghostBody)
                        .foregroundStyle(Color.ghostTextPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(Theme.Spacing.lg)
                }
                GhostGlass(style: .ember) {
                    Text("Ember")
                        .font(.ghostVoice)
                        .foregroundStyle(Color.ghostTextPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(Theme.Spacing.lg)
                }
            }
            .padding(Theme.Spacing.lg)
        }
    }
}

import SwiftUI

/// Liquid Glass card on iOS 26; falls back to `BlurBackground` on earlier
/// versions so Ghost can keep an iOS 17 deployment target.
struct GhostGlass<Content: View>: View {
    enum Style {
        case regular
        case interactive
        case accent
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
        if #available(iOS 26, *) {
            content
                .glassEffect(glass, in: shape)
                .overlay {
                    shape.strokeBorder(Color.ghostTextPrimary.opacity(0.07), lineWidth: 1)
                }
        } else {
            content
                .background(BlurBackground(cornerRadius: cornerRadius))
        }
    }

    @available(iOS 26, *)
    private var glass: Glass {
        switch style {
        case .regular: .regular
        case .interactive: .regular.interactive()
        case .accent: .regular.tint(Color.ghostAccent)
        }
    }
}

/// Groups sibling glass pieces so they share lighting. Identity on
/// systems that don't have Liquid Glass.
struct GhostGlassContainer<Content: View>: View {
    var spacing: CGFloat = 0
    @ViewBuilder var content: Content

    init(spacing: CGFloat = 0, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: spacing) {
                content
            }
        } else {
            content
        }
    }
}

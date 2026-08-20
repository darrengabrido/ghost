import SwiftUI

/// Shared visual constants — spacing, radius, motion, and the two
/// atmospheric primitives (glow and hairline) that every Ghost surface
/// is built from.
enum Theme {
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 40
        /// Reserved for the large silences — around the orb, above a
        /// display title. Emptiness is most of what makes this feel
        /// expensive, so spend it deliberately.
        static let xxl: CGFloat = 64
    }

    enum Radius {
        static let sm: CGFloat = 10
        static let md: CGFloat = 18
        static let lg: CGFloat = 30
        static let xl: CGFloat = 44
    }

    enum Motion {
        /// The base pulse for anything alive. Slow — a calm resting
        /// breath, not an animation.
        static let breathe = Animation.easeInOut(duration: 3.6).repeatForever(autoreverses: true)
        static let quick = Animation.easeOut(duration: 0.22)
        /// State changes that should feel like weather turning rather
        /// than a control toggling.
        static let settle = Animation.easeInOut(duration: 0.9)
        /// Liquid Glass reshaping between forms.
        static let morph = Animation.spring(response: 0.55, dampingFraction: 0.78)
    }

    /// Opacities for the warm bone hairlines that catch the light along a
    /// glass edge. This is the single detail that most separates glass
    /// that looks expensive from glass that looks like a blur.
    enum Hairline {
        static let bright: Double = 0.16
        static let regular: Double = 0.09
        static let faint: Double = 0.05
    }

    /// The soft radial glow behind the orb and other presence surfaces.
    static func glow(
        color: Color = .ghostAccent,
        radius: CGFloat = 120,
        intensity: Double = 0.35
    ) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color.opacity(intensity), color.opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: radius
                )
            )
            .frame(width: radius * 2, height: radius * 2)
            .blendMode(.screen)
    }

    /// A warm bone hairline for glass edges and dividers.
    static func hairline(_ opacity: Double = Hairline.regular) -> Color {
        Color.ghostBone.opacity(opacity)
    }

    /// The directional edge light on a glass surface: bright at the
    /// top-leading corner, extinguished at the far one, as though a single
    /// low light sat above the frame.
    ///
    /// Lives here rather than on `GhostGlass` because that type is generic
    /// over its content, and Swift does not allow static stored properties
    /// in generic types.
    static let hairlineGradient = LinearGradient(
        colors: [
            hairline(Hairline.bright),
            hairline(Hairline.regular),
            hairline(Hairline.faint),
            .clear
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

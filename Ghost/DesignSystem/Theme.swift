import SwiftUI

/// Shared visual constants (spacing, radius, motion) that aren't colors or
/// type, but still need to be consistent across every atmospheric surface.
enum Theme {
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 40
    }

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 28
    }

    enum Motion {
        static let breathe = Animation.easeInOut(duration: 2.4).repeatForever(autoreverses: true)
        static let quick = Animation.easeOut(duration: 0.2)
    }

    /// The soft radial glow used behind the orb and other "presence" surfaces.
    static func glow(color: Color = .ghostAccent, radius: CGFloat = 120) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color.opacity(0.35), color.opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: radius
                )
            )
            .frame(width: radius * 2, height: radius * 2)
            .blendMode(.screen)
    }
}

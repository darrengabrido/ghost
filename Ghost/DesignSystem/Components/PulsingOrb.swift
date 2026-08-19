import SwiftUI

/// The single presence Ghost shows the user — a breathing sphere that
/// changes color and motion with conversation state. This is the emotional
/// center of the app; every other surface orbits it, literally or not.
///
/// Lit off-center from the top-leading corner, matching the hairline on
/// `GhostGlass`, so the orb and the glass around it agree about where the
/// light in this room is coming from.
struct PulsingOrb: View {
    enum State {
        case idle
        case listening
        case thinking
        case speaking

        /// The body of the sphere.
        var color: Color {
            switch self {
            case .idle: .ghostMapleDeep
            case .listening: .ghostFlare
            case .thinking: .ghostMaple
            case .speaking: .ghostFlare
            }
        }

        /// The hot center, brightest where the light falls.
        var core: Color {
            switch self {
            case .idle: .ghostMaple
            case .listening, .speaking: .ghostBone
            case .thinking: .ghostFlare
            }
        }

        /// Red is the identity, so the orb keeps a low ember even at
        /// rest — Ghost is never fully absent, only quiet.
        var glow: Double {
            switch self {
            case .idle: 0.22
            case .listening: 0.6
            case .thinking: 0.45
            case .speaking: 0.55
            }
        }

        var isActive: Bool {
            self != .idle
        }
    }

    var state: State = .idle
    var diameter: CGFloat = 140

    var body: some View {
        ZStack {
            Theme.glow(color: state.color, radius: diameter * 1.15, intensity: state.glow)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            state.core.opacity(0.95),
                            state.color,
                            state.color.opacity(0.35)
                        ],
                        center: UnitPoint(x: 0.34, y: 0.3),
                        startRadius: 0,
                        endRadius: diameter * 0.78
                    )
                )
                .overlay {
                    Circle().strokeBorder(
                        LinearGradient(
                            colors: [Theme.hairline(0.34), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                }
                .frame(width: diameter, height: diameter)
                .breathing(isActive: state.isActive)
        }
        .animation(Theme.Motion.settle, value: state.color)
        .accessibilityHidden(true)
    }
}

#Preview {
    ZStack {
        GhostAtmosphereBackground()
        HStack(spacing: Theme.Spacing.lg) {
            PulsingOrb(state: .idle, diameter: 90)
            PulsingOrb(state: .listening, diameter: 90)
            PulsingOrb(state: .thinking, diameter: 90)
        }
    }
}

import SwiftUI

/// The single "presence" Ghost shows the user — a breathing orb that
/// changes color and motion with conversation state. This is the emotional
/// center of the app's UI; most screens should orbit around it literally
/// or figuratively.
struct PulsingOrb: View {
    enum State {
        case idle
        case listening
        case thinking
        case speaking

        var color: Color {
            switch self {
            case .idle: .ghostTextTertiary
            case .listening: .ghostAccentSecondary
            case .thinking: .ghostAccent
            case .speaking: .ghostAccent
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
            Theme.glow(color: state.color, radius: diameter)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [state.color, state.color.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: diameter, height: diameter)
                .breathing(isActive: state.isActive)
        }
        .animation(Theme.Motion.quick, value: state.color)
        .accessibilityHidden(true)
    }
}

#Preview {
    ZStack {
        Color.ghostBackground.ignoresSafeArea()
        PulsingOrb(state: .listening)
    }
}

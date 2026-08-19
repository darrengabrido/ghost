import SwiftUI

/// The single presence Ghost shows the user — a breathing sphere that
/// changes color and motion with conversation state. This is the emotional
/// center of the app; every other surface orbits it, literally or not.
///
/// Built as a lit object rather than a glow. The distinction matters: a
/// radial gradient that fades to transparent at its edge reads as a smudge
/// of light, because nothing in the world ends that way. What makes a
/// sphere read as a sphere is the *terminator* — the rim going darker than
/// the body as it curves away from the light. So the body gradient runs
/// hot core -> body -> near-black rim, and the aura is a separate layer
/// behind it. The result is a paper lantern in fog, which is the right
/// reference for both of this app's touchstones.
///
/// Lit from the top-leading corner, matching the hairline on `GhostGlass`,
/// so the orb and the glass around it agree about where the light in this
/// room comes from.
struct PulsingOrb: View {
    enum State: Equatable {
        case idle
        case listening
        case thinking
        case speaking

        /// The body of the sphere, between core and terminator.
        var color: Color {
            switch self {
            case .idle: .ghostMapleDeep
            case .listening: .ghostFlare
            case .thinking: .ghostMaple
            case .speaking: .ghostFlare
            }
        }

        /// The hot centre, where the light falls.
        var core: Color {
            switch self {
            case .idle: .ghostMaple
            case .listening, .speaking: .ghostBone
            case .thinking: .ghostFlare
            }
        }

        /// The terminator — the far side of the sphere, curving out of the
        /// light. Always darker than `color`; this is the edge that makes
        /// the thing read as a volume.
        var rim: Color {
            switch self {
            case .idle: .ghostSumi
            case .listening, .speaking, .thinking: .ghostMapleDeep
            }
        }

        /// Red is the identity, so the orb keeps a low ember even at
        /// rest — Ghost is never fully absent, only quiet.
        var glow: Double {
            switch self {
            case .idle: 0.20
            case .listening: 0.62
            case .thinking: 0.44
            case .speaking: 0.56
            }
        }

        /// How much the inner turbulence shows through. Ghost visibly
        /// churns while it's thinking and settles when it isn't.
        var turbulence: Double {
            switch self {
            case .idle: 0.18
            case .listening: 0.45
            case .thinking: 0.7
            case .speaking: 0.55
            }
        }

        var isActive: Bool {
            self != .idle
        }
    }

    var state: State = .idle
    var diameter: CGFloat = 140

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var driftAngle: Double = 0

    var body: some View {
        ZStack {
            Theme.glow(color: state.color, radius: diameter * 1.15, intensity: state.glow)

            sphere
        }
        .animation(Theme.Motion.settle, value: state)
        .accessibilityHidden(true)
        .onAppear(perform: startDrift)
    }

    private var sphere: some View {
        Circle()
            .fill(bodyGradient)
            .frame(width: diameter, height: diameter)
            .overlay { innerTurbulence }
            .overlay { specular }
            .clipShape(Circle())
            .overlay { rimLight }
            .breathing(isActive: state.isActive)
    }

    private var bodyGradient: RadialGradient {
        RadialGradient(
            colors: [state.core, state.color, state.rim],
            center: UnitPoint(x: 0.33, y: 0.28),
            startRadius: 0,
            endRadius: diameter * 0.74
        )
    }

    /// Two soft masses turning against each other at different rates, so
    /// the interior never repeats on a period the eye can catch.
    private var innerTurbulence: some View {
        ZStack {
            drift(scale: 0.86, unitOffset: CGSize(width: -0.11, height: 0.09), angle: driftAngle)
            drift(scale: 0.62, unitOffset: CGSize(width: 0.13, height: -0.07), angle: -driftAngle * 0.63)
        }
        .blur(radius: diameter * 0.07)
        .opacity(state.turbulence)
        .blendMode(.screen)
    }

    private func drift(scale: CGFloat, unitOffset: CGSize, angle: Double) -> some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [state.core.opacity(0.6), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: diameter * scale * 0.4
                )
            )
            .frame(width: diameter * scale, height: diameter * scale * 0.66)
            .offset(x: diameter * unitOffset.width, y: diameter * unitOffset.height)
            .rotationEffect(.degrees(angle))
    }

    /// The highlight where the light source sits. Small, soft, and well
    /// inside the edge — a specular on the rim would read as a rendering
    /// mistake rather than a curved surface.
    private var specular: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [.ghostBone.opacity(state.isActive ? 0.45 : 0.22), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: diameter * 0.17
                )
            )
            .frame(width: diameter * 0.36, height: diameter * 0.25)
            .offset(x: -diameter * 0.16, y: -diameter * 0.21)
            .blur(radius: diameter * 0.03)
            .blendMode(.screen)
    }

    /// A hairline catching the light along the top-leading arc and dying
    /// out before it reaches the terminator.
    private var rimLight: some View {
        Circle().strokeBorder(
            LinearGradient(
                colors: [Theme.hairline(0.4), Theme.hairline(Theme.Hairline.faint), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            lineWidth: max(0.7, diameter * 0.006)
        )
    }

    private func startDrift() {
        guard !reduceMotion else { return }
        withAnimation(.linear(duration: 34).repeatForever(autoreverses: false)) {
            driftAngle = 360
        }
    }
}

#Preview {
    ZStack {
        GhostAtmosphereBackground()
        VStack(spacing: Theme.Spacing.xl) {
            HStack(spacing: Theme.Spacing.lg) {
                PulsingOrb(state: .idle, diameter: 110)
                PulsingOrb(state: .listening, diameter: 110)
            }
            HStack(spacing: Theme.Spacing.lg) {
                PulsingOrb(state: .thinking, diameter: 110)
                PulsingOrb(state: .speaking, diameter: 110)
            }
        }
    }
}

import SwiftUI

/// The single presence Ghost shows the user — a spirit: a soul-light
/// wrapped in slow veils of aurora, with a few loose motes in orbit.
/// This is the emotional center of the app; every other surface orbits
/// it, literally or not.
///
/// Deliberately formless. Anything with anatomy — an eye, a face, a
/// figure — collapses the presence into a creature, and a creature can
/// be sized up. A light behind veils can't. What makes it read as a
/// *being* rather than a lamp is temperament: the light swells open to
/// listen, draws inward to think, flares in rhythm while it speaks, and
/// every few seconds it stirs on its own, unprompted, the way anything
/// alive shifts its weight.
///
/// Lit from within rather than from the room, but its motes and rim
/// still agree with `GhostGlass` about where the room's light comes
/// from.
struct SpiritWisp: View {
    /// Named `Phase`, not `State`. A type named `State` nested inside a
    /// SwiftUI `View` shadows the `@State` property wrapper for the whole
    /// scope, so `@State private var driftAngle` stops resolving and the
    /// compiler reports "enum 'State' cannot be used as an attribute" —
    /// with a cascade of unrelated-looking errors behind it.
    enum Phase: Equatable {
        case idle
        case listening
        case thinking
        case speaking

        /// The soul-light at the centre.
        var core: Color {
            switch self {
            case .idle, .thinking: .ghostStarlight
            case .listening, .speaking: .ghostStarWhite
            }
        }

        /// Veil colours, innermost first. The middle veil doubles as the
        /// aura colour, so the halo always agrees with the body.
        var veils: [Color] {
            switch self {
            case .idle: [.ghostAstralDeep, .ghostAstral, .ghostNebula]
            case .listening, .speaking: [.ghostAstral, .ghostStarlight, .ghostNebula]
            case .thinking: [.ghostAstral, .ghostStarlight, .ghostAstralDeep]
            }
        }

        /// The soul-light's reach, as a fraction of the diameter.
        var coreScale: CGFloat {
            switch self {
            case .idle: 0.34
            case .listening: 0.50
            case .thinking: 0.27
            case .speaking: 0.43
            }
        }

        /// How present the veils are. Thinking is the loudest — the
        /// spirit gathers its light inward and churns.
        var veil: Double {
            switch self {
            case .idle: 0.34
            case .listening: 0.60
            case .thinking: 0.85
            case .speaking: 0.68
            }
        }

        /// The whole being opens to listen and draws in to think.
        var spread: CGFloat {
            switch self {
            case .idle: 1.0
            case .listening: 1.12
            case .thinking: 0.87
            case .speaking: 1.05
            }
        }

        /// Starlight is the identity, so the spirit keeps a low shimmer
        /// even at rest — Ghost is never fully absent, only quiet.
        var glow: Double {
            switch self {
            case .idle: 0.30
            case .listening: 0.60
            case .thinking: 0.42
            case .speaking: 0.54
            }
        }

        var isActive: Bool {
            self != .idle
        }
    }

    var state: Phase = .idle
    var diameter: CGFloat = 140

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var driftAngle: Double = 0
    /// 0 at rest; briefly rises when the spirit stirs.
    @State private var stir: Double = 0

    var body: some View {
        // The aura is a `background`, not a ZStack sibling, and that is a
        // layout decision rather than a cosmetic one: `Theme.glow` carries an
        // explicit frame of `radius * 2`, so as a sibling it would make a
        // 190pt spirit claim 437pt of vertical space and push the onboarding
        // button off short screens. As a background it draws outside the
        // bounds without contributing to them, and the spirit measures what
        // it looks like.
        being
            .scaleEffect(state.spread)
            .background {
                Theme.glow(
                    color: state.veils[1],
                    radius: diameter * 1.2,
                    intensity: state.glow + stir * 0.18
                )
            }
            .animation(Theme.Motion.settle, value: state)
            .accessibilityHidden(true)
            .onAppear(perform: syncDrift)
            .onChange(of: reduceMotion) { _, _ in syncDrift() }
            .task(id: reduceMotion) { await stirLoop() }
    }

    private var being: some View {
        ZStack {
            // Three veils turning at incommensurate rates, so the spirit
            // never shows the same silhouette twice.
            veil(0, rate: 1.0, size: 0.92, squash: 0.66, unitOffset: CGSize(width: -0.10, height: 0.07))
            veil(1, rate: -0.63, size: 0.78, squash: 0.58, unitOffset: CGSize(width: 0.12, height: -0.05))
            veil(2, rate: 0.41, size: 1.02, squash: 0.72, unitOffset: CGSize(width: 0.02, height: 0.11))

            core

            motes
        }
        .frame(width: diameter, height: diameter)
        .breathing(isActive: state.isActive)
    }

    /// One sheet of aurora: an off-centre ellipse of colour, blurred past
    /// the point of reading as a shape, swept around the soul-light.
    private func veil(
        _ index: Int,
        rate: Double,
        size: CGFloat,
        squash: CGFloat,
        unitOffset: CGSize
    ) -> some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [state.veils[index].opacity(0.9), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: diameter * size * 0.5
                )
            )
            .frame(width: diameter * size, height: diameter * size * squash)
            .offset(x: diameter * unitOffset.width, y: diameter * unitOffset.height)
            .rotationEffect(.degrees(driftAngle * rate))
            .blur(radius: diameter * 0.07)
            .opacity(state.veil + stir * 0.3)
            .blendMode(.screen)
    }

    /// The soul-light. White-hot at the centre, falling through the
    /// state's own colour, gone before it reaches the veils' edge — the
    /// falloff is what makes it a light source rather than a disc.
    private var core: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        .ghostStarWhite,
                        state.core.opacity(0.85),
                        Color.ghostAstral.opacity(0.25),
                        .clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: diameter * state.coreScale * 0.8
                )
            )
            .frame(
                width: diameter * state.coreScale * 1.6,
                height: diameter * state.coreScale * 1.6
            )
            .opacity(0.75 + stir * 0.25)
            .blendMode(.screen)
    }

    /// Loose motes in orbit — the spirit sheds a little light as it
    /// turns. Three is deliberate: two reads as a diagram, four as a
    /// particle system.
    private var motes: some View {
        ZStack {
            mote(angle: .degrees(20), orbit: 0.56, size: 0.020)
            mote(angle: .degrees(150), orbit: 0.62, size: 0.014)
            mote(angle: .degrees(265), orbit: 0.50, size: 0.017)
        }
        .rotationEffect(.degrees(driftAngle * 1.6))
        .opacity(state.isActive ? 0.8 : 0.35)
    }

    private func mote(angle: Angle, orbit: CGFloat, size: CGFloat) -> some View {
        Circle()
            .fill(Color.ghostStarlight)
            .frame(width: diameter * size, height: diameter * size)
            .shadow(color: .ghostStarlight.opacity(0.8), radius: diameter * 0.015)
            .offset(
                x: CGFloat(cos(angle.radians)) * diameter * orbit * 0.5,
                y: CGFloat(sin(angle.radians)) * diameter * orbit * 0.5
            )
    }

    /// Reduce Motion can be switched on by Accessibility Shortcut while
    /// the spirit is on screen, and an environment change does not remount
    /// a view — so starting this only on appear would leave the rotation
    /// repeating forever for a user who just asked for it to stop.
    private func syncDrift() {
        guard !reduceMotion, !LaunchFlags.isUITesting else {
            withAnimation(nil) { driftAngle = 0 }
            return
        }
        withAnimation(.linear(duration: 34).repeatForever(autoreverses: false)) {
            driftAngle = 360
        }
    }

    /// The occasional unprompted stir — the spirit gathers a little
    /// brighter, then settles. Irregular on purpose: anything on a fixed
    /// period reads as a metronome, not a mood. Held still under Reduce
    /// Motion and in UI tests, where every frame must be the same frame.
    private func stirLoop() async {
        guard !reduceMotion, !LaunchFlags.isUITesting else {
            withAnimation(nil) { stir = 0 }
            return
        }
        while !Task.isCancelled {
            let pause = Double.random(in: 5...10)
            try? await Task.sleep(for: .seconds(pause))
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.28)) { stir = 1 }
            try? await Task.sleep(for: .milliseconds(380))
            withAnimation(.easeOut(duration: 0.5)) { stir = 0 }
        }
    }
}

#Preview {
    ZStack {
        GhostAtmosphereBackground()
        VStack(spacing: Theme.Spacing.xl) {
            HStack(spacing: Theme.Spacing.lg) {
                SpiritWisp(state: .idle, diameter: 110)
                SpiritWisp(state: .listening, diameter: 110)
            }
            HStack(spacing: Theme.Spacing.lg) {
                SpiritWisp(state: .thinking, diameter: 110)
                SpiritWisp(state: .speaking, diameter: 110)
            }
        }
    }
}

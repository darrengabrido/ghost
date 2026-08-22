import SwiftUI

/// The single presence Ghost shows the user — an eye of the universe: a
/// slow iris of nebula light around a dark pupil of true void. This is the
/// emotional center of the app; every other surface orbits it, literally
/// or not.
///
/// Built as an eye rather than a glow, and the anatomy is what sells it.
/// A disc of light reads as a lamp; what makes an eye read as *watching*
/// is the pupil — a darkness at the centre that is deeper than the ground
/// behind it — and an iris whose interest you can see: it dilates when
/// Ghost listens, narrows when it thinks, and holds a calm mid when at
/// rest. The iris is drawn as churning nebula filaments rather than a flat
/// ring, so at any size it reads as depth, not decoration.
///
/// Lit from the top-leading corner, matching the hairline on `GhostGlass`,
/// so the eye and the glass around it agree about where the light in this
/// room comes from.
struct CosmicEye: View {
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

        /// The body of the iris, between the pupil rim and the limbus.
        var iris: Color {
            switch self {
            case .idle: .ghostAstralDeep
            case .listening: .ghostStarlight
            case .thinking: .ghostAstral
            case .speaking: .ghostStarlight
            }
        }

        /// The hot ring right at the pupil — where an iris is brightest.
        var core: Color {
            switch self {
            case .idle: .ghostAstral
            case .listening, .speaking: .ghostStarWhite
            case .thinking: .ghostStarlight
            }
        }

        /// The limbus — the outer edge of the iris, darkening as it turns
        /// away. Always darker than `iris`; this is the edge that makes
        /// the thing read as a volume instead of a ring.
        var limbus: Color {
            switch self {
            case .idle: .ghostVoid
            case .listening, .speaking, .thinking: .ghostAstralDeep
            }
        }

        /// The pupil, as a fraction of the eye's diameter. An attentive
        /// eye dilates: widest while listening, narrowed while thinking,
        /// calm in between.
        var pupil: CGFloat {
            switch self {
            case .idle: 0.32
            case .listening: 0.44
            case .thinking: 0.22
            case .speaking: 0.36
            }
        }

        /// Starlight is the identity, so the eye keeps a low shimmer even
        /// at rest — Ghost is never fully absent, only quiet.
        var glow: Double {
            switch self {
            case .idle: 0.30
            case .listening: 0.60
            case .thinking: 0.42
            case .speaking: 0.54
            }
        }

        /// How much the nebula filaments show through. The iris visibly
        /// churns while Ghost is thinking and settles when it isn't.
        var churn: Double {
            switch self {
            case .idle: 0.20
            case .listening: 0.45
            case .thinking: 0.72
            case .speaking: 0.55
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
    @State private var blink: CGFloat = 1

    var body: some View {
        // The aura is a `background`, not a ZStack sibling, and that is a
        // layout decision rather than a cosmetic one: `Theme.glow` carries an
        // explicit frame of `radius * 2`, so as a sibling it would make a
        // 190pt eye claim 437pt of vertical space and push the onboarding
        // button off short screens. As a background it draws outside the
        // bounds without contributing to them, and the eye measures what it
        // looks like.
        eye
            .scaleEffect(x: 1, y: blink)
            .background {
                Theme.glow(color: state.iris, radius: diameter * 1.15, intensity: state.glow)
            }
            .animation(Theme.Motion.settle, value: state)
            .accessibilityHidden(true)
            .onAppear(perform: syncDrift)
            .onChange(of: reduceMotion) { _, _ in syncDrift() }
            .task(id: reduceMotion) { await blinkLoop() }
    }

    private var eye: some View {
        Circle()
            .fill(irisGradient)
            .frame(width: diameter, height: diameter)
            .overlay { filaments }
            .overlay { pupil }
            .overlay { glint }
            .clipShape(Circle())
            .overlay { rimLight }
            .breathing(isActive: state.isActive)
    }

    /// Bright at the pupil rim, falling to the dark limbus — the way a
    /// backlit iris actually grades.
    private var irisGradient: RadialGradient {
        RadialGradient(
            colors: [state.core, state.iris, state.limbus],
            center: .center,
            startRadius: diameter * state.pupil * 0.4,
            endRadius: diameter * 0.52
        )
    }

    /// Two rings of nebula filaments turning against each other at
    /// different rates, so the iris never repeats on a period the eye can
    /// catch. Angular gradients rather than drawn spokes: at a blur this
    /// soft the eye reads striation, not geometry.
    private var filaments: some View {
        ZStack {
            filamentRing(spokes: 7, alpha: 0.55, angle: driftAngle)
            filamentRing(spokes: 11, alpha: 0.35, angle: -driftAngle * 0.63)
        }
        .blur(radius: diameter * 0.045)
        .opacity(state.churn)
        .blendMode(.screen)
    }

    private func filamentRing(spokes: Int, alpha: Double, angle: Double) -> some View {
        let stops: [Gradient.Stop] = (0...(spokes * 2)).map { index in
            Gradient.Stop(
                color: index.isMultiple(of: 2) ? state.core.opacity(alpha) : .clear,
                location: Double(index) / Double(spokes * 2)
            )
        }
        return Circle()
            .fill(AngularGradient(gradient: Gradient(stops: stops), center: .center))
            .rotationEffect(.degrees(angle))
            .mask {
                // Confine the striation to the iris band: nothing in the
                // pupil, dying out before the limbus.
                Circle()
                    .strokeBorder(
                        RadialGradient(
                            colors: [.white, .white, .clear],
                            center: .center,
                            startRadius: diameter * state.pupil * 0.5,
                            endRadius: diameter * 0.5
                        ),
                        lineWidth: diameter * (0.5 - state.pupil * 0.4)
                    )
            }
    }

    /// The darkness at the centre. Feathered, not hard-edged — a crisp
    /// disc would read as a hole punched in the light rather than a depth
    /// the light falls into.
    private var pupil: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [.ghostVoid, .ghostVoid, .ghostVoid.opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: diameter * state.pupil * 0.62
                )
            )
            .frame(width: diameter * state.pupil, height: diameter * state.pupil)
            .blur(radius: diameter * 0.012)
    }

    /// The catchlight where the light source sits. Small, sharp-ish, and
    /// well inside the edge — an eye without a catchlight reads as dead,
    /// which is the single cheapest way to ruin this component.
    private var glint: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [.ghostStarWhite.opacity(state.isActive ? 0.8 : 0.5), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: diameter * 0.05
                )
            )
            .frame(width: diameter * 0.1, height: diameter * 0.1)
            .offset(x: -diameter * 0.13, y: -diameter * 0.17)
            .blendMode(.screen)
    }

    /// A hairline catching the light along the top-leading arc and dying
    /// out before it reaches the dark side.
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

    /// Reduce Motion can be switched on by Accessibility Shortcut while the
    /// eye is on screen, and an environment change does not remount a view —
    /// so starting this only on appear would leave the rotation repeating
    /// forever for a user who just asked for it to stop.
    private func syncDrift() {
        guard !reduceMotion, !LaunchFlags.isUITesting else {
            withAnimation(nil) { driftAngle = 0 }
            return
        }
        withAnimation(.linear(duration: 34).repeatForever(autoreverses: false)) {
            driftAngle = 360
        }
    }

    /// The occasional slow blink — the one gesture that makes the eye an
    /// eye rather than a diagram of one. Irregular on purpose: a blink on
    /// a fixed period reads as a metronome. Held fully open under Reduce
    /// Motion and in UI tests, where every frame must be the same frame.
    private func blinkLoop() async {
        guard !reduceMotion, !LaunchFlags.isUITesting else {
            withAnimation(nil) { blink = 1 }
            return
        }
        while !Task.isCancelled {
            let pause = Double.random(in: 4.5...9)
            try? await Task.sleep(for: .seconds(pause))
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.09)) { blink = 0.06 }
            try? await Task.sleep(for: .milliseconds(110))
            withAnimation(.easeOut(duration: 0.18)) { blink = 1 }
        }
    }
}

#Preview {
    ZStack {
        GhostAtmosphereBackground()
        VStack(spacing: Theme.Spacing.xl) {
            HStack(spacing: Theme.Spacing.lg) {
                CosmicEye(state: .idle, diameter: 110)
                CosmicEye(state: .listening, diameter: 110)
            }
            HStack(spacing: Theme.Spacing.lg) {
                CosmicEye(state: .thinking, diameter: 110)
                CosmicEye(state: .speaking, diameter: 110)
            }
        }
    }
}

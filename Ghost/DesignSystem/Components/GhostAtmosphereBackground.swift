import SwiftUI

/// The space Ghost lives in.
///
/// Back to front: void ground, starfield, drifting nebulae, streaming
/// stardust, film grain, vignette. Liquid Glass has nothing to refract
/// over a flat fill — this is what gives every glass surface in the app
/// something to bend.
struct GhostAtmosphereBackground: View {
    /// Rises when Ghost is awake. Drives nebula brightness and stardust
    /// density together, so the sky visibly stirs when the presence wakes.
    var intensity: Double = 1

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // The ground is a lit volume, not a flat fill: indigo
                // abyss where the light is, sinking to void at the edges.
                // A single flat colour behind a scene that is otherwise
                // all falloff is the thing that makes a dark app look
                // like a dark rectangle.
                RadialGradient(
                    colors: [.ghostAbyss, .ghostVoid],
                    center: .center,
                    startRadius: 0,
                    endRadius: max(geometry.size.width, geometry.size.height) * 0.62
                )

                Starfield(intensity: intensity)

                DriftingNebulae(intensity: intensity, size: geometry.size)

                Windfield(intensity: 0.55 + intensity * 0.45)

                FilmGrain()

                // Closes the corners so the composition reads as one lit
                // volume rather than a rectangle of effects. Sized off the
                // container, not fixed points, or it crops differently on
                // every device.
                RadialGradient(
                    colors: [.clear, Color.ghostVoid.opacity(0.9)],
                    center: .center,
                    startRadius: min(geometry.size.width, geometry.size.height) * 0.34,
                    endRadius: max(geometry.size.width, geometry.size.height) * 0.72
                )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A fixed field of stars, each twinkling on its own period. The
/// positions never move — stars that drift read as particles, stars that
/// hold still and breathe read as sky.
private struct Starfield: View {
    var intensity: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let stars: [Star] = {
        var generator = SeededGenerator(seed: 0xCE1E_571A)
        return (0..<110).map { _ in
            Star(
                unitX: CGFloat.random(in: 0...1, using: &generator),
                unitY: CGFloat.random(in: 0...1, using: &generator),
                size: CGFloat.random(in: 0.6...2.2, using: &generator),
                baseAlpha: Double.random(in: 0.12...0.7, using: &generator),
                // Incommensurate-ish periods so the field never twinkles
                // in unison.
                period: Double.random(in: 2.7...9.3, using: &generator),
                phase: Double.random(in: 0...(2 * .pi), using: &generator),
                // Most stars are white; a scattering carries the identity
                // blue, and a very few burn faintly warm, because a real
                // sky is not one temperature.
                tint: {
                    let roll = Double.random(in: 0...1, using: &generator)
                    if roll < 0.72 { return .white }
                    if roll < 0.94 { return .cool }
                    return .warm
                }()
            )
        }
    }()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 10.0, paused: reduceMotion)) { timeline in
            // Hoisted out of the render closure so `Canvas` captures only
            // values, never `self`.
            let time = reduceMotion ? 0 : AtmosphereClock.seconds(timeline.date)
            let brightness = 0.6 + 0.4 * intensity
            Canvas { context, size in
                for star in Self.stars {
                    // Twinkle swings each star around its base, never to
                    // zero — a star that fully disappears reads as a bug.
                    let swing = sin(time * 2 * .pi / star.period + star.phase)
                    let alpha = star.baseAlpha * (0.65 + 0.35 * swing) * brightness
                    guard alpha > 0.01 else { continue }

                    let rect = CGRect(
                        x: star.unitX * size.width,
                        y: star.unitY * size.height,
                        width: star.size,
                        height: star.size
                    )
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(star.tint.color.opacity(alpha))
                    )
                }
            }
        }
        .blendMode(.screen)
    }
}

private struct Star: Sendable {
    enum Tint: Sendable {
        case white, cool, warm

        var color: Color {
            switch self {
            case .white: .ghostStarWhite
            case .cool: .ghostStarlight
            case .warm: .ghostDawn
            }
        }
    }

    let unitX: CGFloat
    let unitY: CGFloat
    let size: CGFloat
    let baseAlpha: Double
    let period: Double
    let phase: Double
    let tint: Tint
}

/// Slow-moving banks of nebula light. Each drifts on its own period, and
/// the periods are chosen not to share factors, so the set never resolves
/// into a pattern the eye can lock onto.
private struct DriftingNebulae: View {
    var intensity: Double
    var size: CGSize

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let layers: [NebulaLayer] = [
        NebulaLayer(
            id: 0, color: .ghostAstral, anchor: UnitPoint(x: 0.22, y: 0.14),
            radiusFactor: 0.95, alpha: 0.30, period: 41, travel: 46
        ),
        NebulaLayer(
            id: 1, color: .ghostAstralDeep, anchor: UnitPoint(x: 0.86, y: 0.72),
            radiusFactor: 0.78, alpha: 0.42, period: 57, travel: 62
        ),
        NebulaLayer(
            id: 2, color: .ghostNebula, anchor: UnitPoint(x: 0.48, y: 1.02),
            radiusFactor: 0.66, alpha: 0.28, period: 73, travel: 38
        ),
        // The warm one, low in the corner. Without it the cool layers
        // have nothing to be cool against.
        NebulaLayer(
            id: 3, color: .ghostDawn, anchor: UnitPoint(x: 0.94, y: 0.06),
            radiusFactor: 0.62, alpha: 0.18, period: 89, travel: 30
        )
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: reduceMotion)) { timeline in
            let time = reduceMotion ? 0 : AtmosphereClock.seconds(timeline.date)
            ZStack {
                ForEach(Self.layers) { layer in
                    glow(for: layer, at: time)
                }
            }
        }
    }

    private func glow(for layer: NebulaLayer, at time: Double) -> some View {
        let angle = time * 2 * .pi / layer.period
        let radius = max(size.width * layer.radiusFactor, 200)

        return Theme.glow(
            color: layer.color,
            radius: radius,
            intensity: layer.alpha * intensity
        )
        .position(
            x: size.width * layer.anchor.x + CGFloat(cos(angle)) * layer.travel,
            y: size.height * layer.anchor.y + CGFloat(sin(angle * 0.7)) * layer.travel * 0.6
        )
    }
}

private struct NebulaLayer: Identifiable, Sendable {
    let id: Int
    let color: Color
    let anchor: UnitPoint
    let radiusFactor: CGFloat
    let alpha: Double
    let period: Double
    let travel: CGFloat
}

/// Static, seeded film grain. Deliberately not animated — moving grain
/// reads as video noise, still grain reads as photographic stock, and the
/// second one is the expensive-looking one.
private struct FilmGrain: View {
    private static let specks: [GrainSpeck] = {
        var generator = SeededGenerator(seed: 0x6841_1A17)
        return (0..<1400).map { _ in
            GrainSpeck(
                unitX: CGFloat.random(in: 0...1, using: &generator),
                unitY: CGFloat.random(in: 0...1, using: &generator),
                size: CGFloat.random(in: 0.5...1.4, using: &generator),
                alpha: Double.random(in: 0.05...0.22, using: &generator)
            )
        }
    }()

    var body: some View {
        Canvas { context, size in
            for speck in Self.specks {
                let rect = CGRect(
                    x: speck.unitX * size.width,
                    y: speck.unitY * size.height,
                    width: speck.size,
                    height: speck.size
                )
                context.fill(Path(ellipseIn: rect), with: .color(.ghostStarWhite.opacity(speck.alpha)))
            }
        }
        .blendMode(.softLight)
        .opacity(0.55)
    }
}

private struct GrainSpeck: Sendable {
    let unitX: CGFloat
    let unitY: CGFloat
    let size: CGFloat
    let alpha: Double
}

#Preview {
    GhostAtmosphereBackground()
}

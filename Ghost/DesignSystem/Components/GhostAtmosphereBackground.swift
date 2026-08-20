import SwiftUI

/// The room Ghost lives in.
///
/// Back to front: sumi ground, drifting fog, streaming wind, film grain,
/// vignette. Liquid Glass has nothing to refract over a flat fill — this
/// is what gives every glass surface in the app something to bend.
struct GhostAtmosphereBackground: View {
    /// Rises when Ghost is awake. Drives fog brightness and wind density
    /// together, so the room visibly stirs when the presence wakes.
    var intensity: Double = 1

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // The ground is a lit volume, not a flat fill: warm
                // charcoal where the light is, sinking to sumi at the
                // edges. A single flat colour behind a scene that is
                // otherwise all falloff is the thing that makes a dark
                // app look like a dark rectangle.
                RadialGradient(
                    colors: [.ghostCharcoal, .ghostSumi],
                    center: .center,
                    startRadius: 0,
                    endRadius: max(geometry.size.width, geometry.size.height) * 0.62
                )

                DriftingFog(intensity: intensity, size: geometry.size)

                Windfield(intensity: 0.55 + intensity * 0.45)

                FilmGrain()

                // Closes the corners so the composition reads as one lit
                // volume rather than a rectangle of effects. Sized off the
                // container, not fixed points, or it crops differently on
                // every device.
                RadialGradient(
                    colors: [.clear, Color.ghostSumi.opacity(0.9)],
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

/// Slow-moving banks of coloured fog. Each drifts on its own period, and
/// the periods are chosen not to share factors, so the set never resolves
/// into a pattern the eye can lock onto.
private struct DriftingFog: View {
    var intensity: Double
    var size: CGSize

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let layers: [FogLayer] = [
        FogLayer(
            id: 0, color: .ghostMaple, anchor: UnitPoint(x: 0.22, y: 0.14),
            radiusFactor: 0.95, alpha: 0.34, period: 41, travel: 46
        ),
        FogLayer(
            id: 1, color: .ghostMapleDeep, anchor: UnitPoint(x: 0.86, y: 0.72),
            radiusFactor: 0.78, alpha: 0.42, period: 57, travel: 62
        ),
        FogLayer(
            id: 2, color: .ghostRust, anchor: UnitPoint(x: 0.48, y: 1.02),
            radiusFactor: 0.66, alpha: 0.30, period: 73, travel: 38
        ),
        // The cold one, deep in the corner. Without it the warm layers
        // have nothing to be warm against.
        FogLayer(
            id: 3, color: .ghostMoon, anchor: UnitPoint(x: 0.94, y: 0.06),
            radiusFactor: 0.62, alpha: 0.20, period: 89, travel: 30
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

    private func glow(for layer: FogLayer, at time: Double) -> some View {
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

private struct FogLayer: Identifiable, Sendable {
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
                context.fill(Path(ellipseIn: rect), with: .color(.ghostBone.opacity(speck.alpha)))
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

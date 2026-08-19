import SwiftUI

/// The room Ghost lives in.
///
/// Four layers, back to front: sumi ground, drifting fog, streaming wind,
/// film grain, then a vignette to close the edges. Liquid Glass has
/// nothing to refract over a flat fill — this is what gives every glass
/// surface in the app something to bend.
struct GhostAtmosphereBackground: View {
    /// Rises when Ghost is awake. Drives fog brightness and wind density
    /// together, so the room visibly stirs when the presence wakes.
    var intensity: Double = 1

    var body: some View {
        ZStack {
            Color.ghostSumi

            DriftingFog(intensity: intensity)

            Windfield(tint: .ghostFlare, intensity: 0.55 + intensity * 0.45)

            FilmGrain()

            // Closes the corners so the composition always reads as a
            // single lit volume rather than a rectangle of effects.
            RadialGradient(
                colors: [.clear, Color.ghostSumi.opacity(0.85)],
                center: .center,
                startRadius: 120,
                endRadius: 520
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A slow-moving bank of colored fog. Each layer drifts on its own period
/// so the three never resolve into a repeating pattern.
private struct DriftingFog: View {
    var intensity: Double

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
        )
    ]

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: reduceMotion)) { timeline in
                let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
                ZStack {
                    ForEach(Self.layers) { layer in
                        glow(for: layer, in: geometry.size, at: time)
                    }
                }
            }
        }
    }

    private func glow(for layer: FogLayer, in size: CGSize, at time: Double) -> some View {
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

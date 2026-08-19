import SwiftUI

/// One drifting mote of ash. Value type and `Sendable` so the whole field
/// can be captured by `Canvas`'s render closure without dragging view
/// state across the boundary.
struct WindMote: Sendable {
    let originY: CGFloat
    /// Start offset along the travel path, 0...1.
    let phase: CGFloat
    let size: CGFloat
    /// Travel cycles per second — small numbers, this is a slow wind.
    let speed: CGFloat
    /// Amplitude of the cross-wind sway, in points.
    let sway: CGFloat
    let swaySpeed: CGFloat
    let opacity: Double
    /// 0 = far (small, barely parallaxes), 1 = near (large, swings wide).
    let depth: CGFloat

    /// Builds a deterministic field. Same seed, same wind, every launch.
    static func field(count: Int, seed: UInt64, near: Bool) -> [WindMote] {
        var generator = SeededGenerator(seed: seed)
        return (0..<count).map { _ in
            let depth = CGFloat.random(in: near ? 0.55...1 : 0...0.45, using: &generator)
            return WindMote(
                originY: CGFloat.random(in: -0.1...1.1, using: &generator),
                phase: CGFloat.random(in: 0...1, using: &generator),
                size: (near ? CGFloat.random(in: 1.4...2.8, using: &generator)
                            : CGFloat.random(in: 2.5...5.5, using: &generator)),
                speed: CGFloat.random(in: 0.010...0.032, using: &generator) * (0.6 + depth),
                sway: CGFloat.random(in: 8...34, using: &generator),
                swaySpeed: CGFloat.random(in: 0.25...0.75, using: &generator),
                opacity: Double.random(in: near ? 0.35...0.85 : 0.18...0.5, using: &generator),
                depth: depth
            )
        }
    }
}

/// The always-on wind: embers and ash streaming across the frame on a
/// slow diagonal, parallaxing against device tilt.
///
/// Two `Canvas` layers rather than a stack of SwiftUI shapes — sixty
/// animated views would cost a layout pass each frame, where this costs
/// one draw call. The far layer is blurred as a whole (one filter pass for
/// the entire layer, not one per mote) and the near layer stays crisp and
/// slightly elongated, which is what sells the direction of travel.
struct Windfield: View {
    var tint: Color = .ghostMaple
    /// Scales opacity across the whole field. Rises when Ghost is awake.
    var intensity: Double = 1

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var tilt: CGSize = .zero

    private static let farField = WindMote.field(count: 34, seed: 0x5EED_1EAF, near: false)
    private static let nearField = WindMote.field(count: 22, seed: 0x0B57_1DE5, near: true)

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
            // Hoisted out of the render closures so `Canvas` captures only
            // values, never `self`.
            let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            let currentTilt = tilt
            let strength = intensity
            let color = tint
            let far = Self.budgeted(Self.farField)
            let near = Self.budgeted(Self.nearField)

            ZStack {
                Canvas { context, size in
                    Windfield.draw(
                        into: &context, size: size, motes: far, time: time,
                        tilt: currentTilt, tint: color,
                        intensity: strength * 0.55, elongation: 1
                    )
                }
                .blur(radius: 7)

                Canvas { context, size in
                    Windfield.draw(
                        into: &context, size: size, motes: near, time: time,
                        tilt: currentTilt, tint: color,
                        intensity: strength, elongation: 2.2
                    )
                }
            }
        }
        .blendMode(.screen)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task { await trackTilt() }
    }

    /// Low Power Mode thins the field rather than stopping it — a wind
    /// that halts the moment the battery dips reads as a bug.
    private static func budgeted(_ motes: [WindMote]) -> [WindMote] {
        guard ProcessInfo.processInfo.isLowPowerModeEnabled else { return motes }
        return Array(motes.prefix(motes.count / 2))
    }

    @MainActor
    private func trackTilt() async {
        let motion = WindMotion.shared
        guard !reduceMotion, motion.isAvailable else { return }

        motion.retain()
        defer { motion.release() }

        while !Task.isCancelled {
            tilt = motion.sample()
            try? await Task.sleep(for: .milliseconds(33))
        }
    }

    // swiftlint:disable:next function_parameter_count
    private static func draw(
        into context: inout GraphicsContext,
        size: CGSize,
        motes: [WindMote],
        time: Double,
        tilt: CGSize,
        tint: Color,
        intensity: Double,
        elongation: CGFloat
    ) {
        let span = size.width + 160

        for mote in motes {
            let progress = fract(mote.phase + CGFloat(time) * mote.speed)
            // Motes rise as they cross — wind off the sea, not a screensaver.
            let posX = progress * span - 80 + tilt.width * mote.depth * 30
            let rise = progress * size.height * 0.24
            let wobble = sin(time * Double(mote.swaySpeed) + Double(mote.phase) * .pi * 2)
            let posY = mote.originY * size.height * 1.15
                - rise
                + CGFloat(wobble) * mote.sway
                + tilt.height * mote.depth * 22

            // Fade in and out at the edges of travel so nothing pops.
            let fade = sin(Double(progress) * .pi)
            let alpha = mote.opacity * fade * intensity
            guard alpha > 0.004 else { continue }

            let rect = CGRect(
                x: posX,
                y: posY,
                width: mote.size * elongation,
                height: mote.size
            )
            context.fill(Path(ellipseIn: rect), with: .color(tint.opacity(alpha)))
        }
    }

    private static func fract(_ value: CGFloat) -> CGFloat {
        value - value.rounded(.down)
    }
}

#Preview {
    ZStack {
        Color.ghostCharcoal.ignoresSafeArea()
        Windfield()
    }
}

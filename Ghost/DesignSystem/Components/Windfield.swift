import SwiftUI

/// One drifting mote. Value type and `Sendable` so the whole field can be
/// captured by `Canvas`'s render closure without dragging view state
/// across the boundary.
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
    /// Bright grains burn in starlight; everything else is pale dust.
    let isBright: Bool

    /// Builds a deterministic field. Same seed, same wind, every launch.
    ///
    /// Most of the drift is dim dust. Only about a quarter of it shines,
    /// and more of that quarter sits in the near layer where it stays
    /// crisp — tinting *every* mote starlight would turn the accent into
    /// a colour cast and stop it meaning anything.
    static func field(count: Int, seed: UInt64, near: Bool) -> [WindMote] {
        var generator = SeededGenerator(seed: seed)
        let brightChance = near ? 0.35 : 0.18

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
                depth: depth,
                isBright: Double.random(in: 0...1, using: &generator) < brightChance
            )
        }
    }
}

/// The always-on drift: stardust streaming across the frame on a slow
/// diagonal, parallaxing against device tilt.
///
/// Two `Canvas` layers rather than a stack of SwiftUI shapes — sixty
/// animated views would cost a layout pass each frame, where this costs
/// one draw call. The far layer is blurred as a whole (one filter pass for
/// the entire layer, not one per mote) and the near layer stays crisp and
/// slightly elongated, which is what sells the direction of travel.
struct Windfield: View {
    /// The rare, shining minority.
    var bright: Color = .ghostStarlight
    /// The dim majority.
    var dust: Color = .ghostStarWhite
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
            let time = reduceMotion ? 0 : AtmosphereClock.seconds(timeline.date)
            let frame = WindFrame(
                bright: bright, dust: dust, intensity: intensity,
                tilt: tilt, time: time, elongation: 2.2
            )
            let far = Self.budgeted(Self.farField)
            let near = Self.budgeted(Self.nearField)

            ZStack {
                Canvas { context, size in
                    Windfield.draw(into: &context, size: size, motes: far, frame: frame.distant)
                }
                .blur(radius: 7)

                Canvas { context, size in
                    Windfield.draw(into: &context, size: size, motes: near, frame: frame)
                }
            }
        }
        .blendMode(.screen)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        // Keyed to `reduceMotion` so toggling it cancels and re-evaluates.
        // Unkeyed, enabling the setting would leave the 30Hz sampler running
        // and `tilt` updating — which keeps the parallax moving even though
        // the timeline is paused, i.e. exactly what the setting asks to stop.
        .task(id: reduceMotion) { await trackTilt() }
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

    private static func draw(
        into context: inout GraphicsContext,
        size: CGSize,
        motes: [WindMote],
        frame: WindFrame
    ) {
        let time = frame.time
        let span = size.width + 160
        // Two incommensurate periods, so the wind swells and drops without
        // ever settling into a rhythm you can count along with.
        let gust = sin(time / 11.3) * sin(time / 6.7)
        let push = CGFloat(gust) * 26

        for mote in motes {
            let progress = fract(mote.phase + CGFloat(time) * mote.speed)
            // Motes rise as they cross — wind off the sea, not a screensaver.
            let posX = progress * span - 80 + frame.tilt.width * mote.depth * 30 + push * mote.depth
            let rise = progress * size.height * 0.24
            let wobble = sin(time * Double(mote.swaySpeed) + Double(mote.phase) * .pi * 2)
            let posY = mote.originY * size.height * 1.15
                - rise
                + CGFloat(wobble) * mote.sway
                + frame.tilt.height * mote.depth * 22

            // Fade in and out at the ends of travel so nothing pops.
            let fade = sin(Double(progress) * .pi)
            let alpha = mote.opacity * fade * frame.intensity
                * (mote.isBright ? 1 : 0.55)
                * (0.8 + 0.2 * gust)
            guard alpha > 0.004 else { continue }

            let rect = CGRect(
                x: posX,
                y: posY,
                width: mote.size * frame.elongation,
                height: mote.size
            )
            let color = mote.isBright ? frame.bright : frame.dust
            context.fill(Path(ellipseIn: rect), with: .color(color.opacity(alpha)))
        }
    }

    private static func fract(_ value: CGFloat) -> CGFloat {
        value - value.rounded(.down)
    }
}

/// Everything the renderer needs that isn't per-mote, bundled so `draw`
/// keeps a signature a person can read.
struct WindFrame: Sendable {
    let bright: Color
    let dust: Color
    let intensity: Double
    let tilt: CGSize
    let time: Double
    /// How far each mote is stretched along its direction of travel.
    let elongation: CGFloat

    /// The far layer: dimmer, and round rather than streaked, because
    /// distance costs you both brightness and any sense of motion blur.
    var distant: WindFrame {
        WindFrame(
            bright: bright, dust: dust, intensity: intensity * 0.55,
            tilt: tilt, time: time, elongation: 1
        )
    }
}

#Preview {
    ZStack {
        Color.ghostAbyss.ignoresSafeArea()
        Windfield()
    }
}

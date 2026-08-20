import CoreMotion
import SwiftUI

/// Device tilt, smoothed, for parallax.
///
/// Reads `CMMotionManager` by polling rather than by handing it a callback
/// queue: the poll keeps every touch of this type on the main actor, which
/// is what lets it stay a plain `@MainActor` class under strict
/// concurrency instead of an `@unchecked Sendable` wrapper.
///
/// Shared rather than per-view, and reference counted, because the
/// atmosphere is mounted on every screen — a push from Conversation to
/// Settings would otherwise leave two motion managers running against the
/// same hardware, which Apple explicitly warns against.
///
/// Raw attitude is far too twitchy to drive a background. The smoothing
/// below is doing most of the work of making the parallax feel like weight
/// rather than jitter.
@MainActor
final class WindMotion {
    static let shared = WindMotion()

    /// How much of the new reading to accept each sample. Low, on purpose:
    /// the atmosphere should lag behind the hand.
    private static let responsiveness: CGFloat = 0.08
    /// Attitude in radians runs to roughly ±1.5; this maps it to ±1.
    private static let scale: CGFloat = 0.7

    private let manager = CMMotionManager()
    private var smoothed: CGSize = .zero
    private var subscribers = 0

    private init() {}

    var isAvailable: Bool { manager.isDeviceMotionAvailable }

    func retain() {
        subscribers += 1
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates()
    }

    func release() {
        subscribers = max(0, subscribers - 1)
        guard subscribers == 0, manager.isDeviceMotionActive else { return }
        manager.stopDeviceMotionUpdates()
    }

    /// Takes one reading and folds it into the running average. Returns
    /// the smoothed tilt as a unit-ish offset, and the last known value on
    /// a device with no motion hardware — the simulator, mostly.
    func sample() -> CGSize {
        guard let attitude = manager.deviceMotion?.attitude else { return smoothed }

        let target = CGSize(
            width: clamped(CGFloat(attitude.roll) * Self.scale),
            height: clamped(CGFloat(attitude.pitch) * Self.scale)
        )

        smoothed = CGSize(
            width: smoothed.width + (target.width - smoothed.width) * Self.responsiveness,
            height: smoothed.height + (target.height - smoothed.height) * Self.responsiveness
        )
        return smoothed
    }

    private func clamped(_ value: CGFloat) -> CGFloat {
        min(max(value, -1), 1)
    }
}

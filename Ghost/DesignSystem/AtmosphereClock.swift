import Foundation

/// The time source behind the continuously animating atmosphere.
///
/// Pinned under UI testing. The screenshots are committed to the repo, and a
/// wind field that sits somewhere different on every run would rewrite all
/// four images on every CI run — hundreds of kilobytes of churn that says
/// nothing about whether the design actually changed. Pinning the clock
/// makes a run byte-identical to the last one unless the design moved.
enum AtmosphereClock {
    /// An arbitrary but fixed offset into the animation, chosen so the wind
    /// is mid-traverse rather than parked at the edge of its fade.
    private static let pinnedSeconds: Double = 37

    static func seconds(_ date: Date) -> Double {
        LaunchFlags.isUITesting ? pinnedSeconds : date.timeIntervalSinceReferenceDate
    }
}

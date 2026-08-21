import Foundation

/// The window Ghost stays silent through, as whole hours on a 24-hour clock —
/// `startHour` inclusive, `endHour` exclusive.
///
/// A dedicated type rather than a `ClosedRange<Int>` because the realistic case
/// wraps midnight: `22...7` traps at construction, so the wraparound has to be
/// handled by hand.
struct QuietHours: Equatable {
    let startHour: Int
    let endHour: Int

    /// 10pm–7am. A v1 constant rather than a preference: `UserPreferencesStore`
    /// is documented as user-facing *playback* settings, and there is no
    /// Settings surface for quiet hours yet. Promote this to a real preference
    /// once one exists.
    static let `default` = QuietHours(startHour: 22, endHour: 7)

    func contains(hour: Int) -> Bool {
        startHour <= endHour
            ? (hour >= startHour && hour < endHour)
            : (hour >= startHour || hour < endHour)
    }

    func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        contains(hour: calendar.component(.hour, from: date))
    }
}

import SwiftUI

/// Type scale for Ghost. Serif for anything that speaks in Ghost's own
/// voice, system sans for anything that's merely a control.
///
/// Every face is built from a `Font.TextStyle` rather than a fixed point
/// size, so the whole app scales with Dynamic Type.
extension Font {
    static let ghostDisplay = Font.system(.largeTitle, design: .serif, weight: .semibold)
    static let ghostTitle = Font.system(.title2, design: .serif, weight: .medium)
    /// Ghost's own words in the transcript — serif, so the presence reads
    /// differently from the interface around it.
    static let ghostVoice = Font.system(.body, design: .serif, weight: .regular)
    static let ghostBody = Font.system(.body, design: .default, weight: .regular)
    static let ghostCaption = Font.system(.footnote, design: .default, weight: .regular)
    static let ghostLabel = Font.system(.caption, design: .default, weight: .medium)
        .smallCaps()
}

/// Letter-spacing, kept as named intent rather than scattered magic
/// numbers. Wide tracking on small caps is the cheapest luxury cue there
/// is; tight tracking on a display serif is the second cheapest.
enum Tracking {
    /// Section labels and status captions — airy, deliberate.
    static let wide: CGFloat = 2.4
    /// Body-adjacent labels that still want a little room.
    static let loose: CGFloat = 0.6
    /// Display serif — pulled slightly tight so it sits as one shape.
    static let display: CGFloat = -0.4
}

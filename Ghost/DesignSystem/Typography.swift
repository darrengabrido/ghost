import SwiftUI

/// Type scale for Ghost. Leans on rounded/serif system fonts sparingly to
/// keep the atmosphere quiet rather than decorative — most surfaces should
/// just use `.body` and `.caption`.
extension Font {
    static let ghostDisplay = Font.system(size: 34, weight: .semibold, design: .serif)
    static let ghostTitle = Font.system(size: 22, weight: .medium, design: .serif)
    static let ghostBody = Font.system(size: 17, weight: .regular, design: .default)
    static let ghostCaption = Font.system(size: 13, weight: .regular, design: .default)
    static let ghostLabel = Font.system(size: 12, weight: .medium, design: .default)
        .smallCaps()
}

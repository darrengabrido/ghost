import SwiftUI

/// The Ghost palette: near-black backgrounds, violet glow, misty text.
/// Every feature screen should pull colors from here rather than
/// hard-coding hex values, so the atmosphere stays consistent.
extension Color {
    static let ghostBackground = Color(hex: 0x0A0A0F)
    static let ghostSurface = Color(hex: 0x15141F)
    static let ghostSurfaceElevated = Color(hex: 0x1E1D2B)

    static let ghostAccent = Color(hex: 0x8B6FFF)
    static let ghostAccentSecondary = Color(hex: 0x6FE3FF)

    static let ghostTextPrimary = Color(hex: 0xF2F0FA)
    static let ghostTextSecondary = Color(hex: 0x9A96AE)
    static let ghostTextTertiary = Color(hex: 0x635F78)

    static let ghostDanger = Color(hex: 0xFF6B6B)
}

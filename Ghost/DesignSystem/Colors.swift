import SwiftUI

/// The Ghost palette: a warm charcoal night lit by maple red.
///
/// Two layers. The **palette** names a pigment; the **semantic** aliases
/// below name a job. Feature code should reach for the semantic names so
/// the pigments can shift without a sweep through every screen.
///
/// Red is the identity here, not an accent — it lives in the ambient glow,
/// the orb, and the tint of every glass surface. The one rule that keeps it
/// luxurious rather than loud: `ghostMaple` is a *field* color (fills,
/// glows, glass tints, strokes) and never small text, because at 3.3:1 on
/// the charcoal ground it fails contrast. Red type uses `ghostFlare`.
extension Color {

    // MARK: - Palette

    /// Sumi ink — the deepest ground, behind everything.
    static let ghostSumi = Color(hex: 0x070505)
    /// Warm charcoal — the app's canvas. Faintly red-shifted so it never
    /// reads as the blue-black every other dark app uses.
    static let ghostCharcoal = Color(hex: 0x0C0908)
    /// Warm ash — resting surface under glass.
    static let ghostAshDark = Color(hex: 0x17100E)
    /// Raised ash — the one step up from `ghostAshDark`.
    static let ghostAshRaised = Color(hex: 0x221715)

    /// Maple leaf red. The identity. Fields, glows and glass tints only.
    static let ghostMaple = Color(hex: 0xC1272D)
    /// Oxidised maple — the floor of a glow, and pressed states.
    static let ghostMapleDeep = Color(hex: 0x6E1418)
    /// Hot flare. Bright enough to carry text and glyphs at 6.3:1.
    static let ghostFlare = Color(hex: 0xFF5A45)
    /// Dried leaf — the earthy secondary, for anything that shouldn't
    /// compete with maple.
    static let ghostRust = Color(hex: 0x8A3A24)

    /// Bone — warm off-white. Never pure white; pure white is cheap.
    static let ghostBone = Color(hex: 0xEFE9DE)
    /// Mist — secondary type.
    static let ghostMist = Color(hex: 0xA79E95)
    /// Smoke — tertiary type. Held at 4.96:1 so it still passes AA.
    static let ghostSmoke = Color(hex: 0x8A8074)
    /// Ash smoke — decorative strokes and dividers only, never type.
    static let ghostSmokeDim = Color(hex: 0x5A5249)

    /// Crimson, shifted toward magenta so destructive actions stay
    /// distinguishable from a UI whose brand color is already red.
    static let ghostCrimson = Color(hex: 0xFF3B5C)

    // MARK: - Semantic

    static let ghostBackground = ghostCharcoal
    static let ghostSurface = ghostAshDark
    static let ghostSurfaceElevated = ghostAshRaised

    /// Fills, glows, glass tints, the orb. **Not** small text.
    static let ghostAccent = ghostMaple
    /// Red type and glyphs — passes AA where `ghostAccent` would not.
    static let ghostAccentText = ghostFlare
    /// The quieter earth tone beside the accent.
    static let ghostAccentSecondary = ghostRust

    static let ghostTextPrimary = ghostBone
    static let ghostTextSecondary = ghostMist
    static let ghostTextTertiary = ghostSmoke

    static let ghostDanger = ghostCrimson
}

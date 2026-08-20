import SwiftUI

/// The Ghost palette: a warm charcoal night lit by maple red.
///
/// Two layers, and the split is a rule rather than a suggestion. The
/// **palette** names a pigment; the **semantic** aliases name a job.
/// `DesignSystem/` may reach for pigments — it *is* the paint layer.
/// `Features/` may not: screens speak only in semantic names, so the
/// pigments can be re-mixed without a sweep through every view.
///
/// Red is the identity here, not an accent — it lives in the ambient glow,
/// the orb, and the tint of every glass surface. The one rule that keeps
/// it luxurious rather than loud: `ghostMaple` is a *field* colour (fills,
/// glows, glass tints, strokes) and never small text, where at 3.3:1 on
/// the ground it fails contrast. Red type uses `ghostFlare` at 6.3:1.
extension Color {

    // MARK: - Palette

    /// Sumi ink — the ground at the edges of every screen, and the colour
    /// the launch screen is painted so the first frame doesn't step.
    static let ghostSumi = Color(hex: 0x070505)
    /// Warm charcoal — the ground at the centre, where the light is.
    /// Faintly red-shifted so it never reads as the blue-black every other
    /// dark app uses.
    static let ghostCharcoal = Color(hex: 0x0C0908)
    /// Raised ash — the opaque stand-in for regular glass when the user
    /// has asked for reduced transparency.
    static let ghostAshRaised = Color(hex: 0x221715)
    /// Ash with maple folded into it — the opaque stand-in for ember
    /// glass, so Ghost's own surfaces stay distinguishable from the
    /// interface's even with transparency switched off.
    static let ghostAshEmber = Color(hex: 0x3C1515)

    /// Maple leaf red. The identity. Fields, glows and glass tints only.
    static let ghostMaple = Color(hex: 0xC1272D)
    /// Oxidised maple — the floor of a glow, and the orb's terminator.
    static let ghostMapleDeep = Color(hex: 0x6E1418)
    /// Hot flare. Bright enough to carry text and glyphs at 6.3:1.
    static let ghostFlare = Color(hex: 0xFF5A45)
    /// Dried leaf — the earthy secondary, for anything that shouldn't
    /// compete with maple.
    static let ghostRust = Color(hex: 0x8A3A24)

    /// Cold moonlight. Atmosphere only, and never above ~0.2 alpha.
    ///
    /// Red on red on black goes muddy: with nothing cool anywhere in the
    /// frame the eye has no reference and every warm tone flattens into
    /// the same note. In the maple groves this palette comes from, the
    /// leaves read as vivid precisely because the shadows behind them are
    /// cold blue-grey. This is that shadow — far enough back that the app
    /// never reads as blue, present enough to make the maple sing.
    static let ghostMoon = Color(hex: 0x38415C)

    /// Bone — warm off-white. Never pure white; pure white is cheap.
    static let ghostBone = Color(hex: 0xEFE9DE)
    /// Mist — secondary type.
    static let ghostMist = Color(hex: 0xA79E95)
    /// Smoke — tertiary type. Held at 4.96:1 so it still passes AA.
    static let ghostSmoke = Color(hex: 0x8A8074)

    /// Crimson, shifted toward magenta so destructive actions stay
    /// distinguishable from a UI whose brand colour is already red.
    static let ghostCrimson = Color(hex: 0xFF3B5C)

    // MARK: - Semantic

    /// The ground behind everything.
    static let ghostBackground = ghostSumi

    /// Fills, glows, glass tints, the orb. **Not** small text.
    static let ghostAccent = ghostMaple
    /// Red type and glyphs — passes AA where `ghostAccent` would not.
    static let ghostAccentText = ghostFlare

    static let ghostTextPrimary = ghostBone
    static let ghostTextSecondary = ghostMist
    static let ghostTextTertiary = ghostSmoke

    static let ghostDanger = ghostCrimson
}

import SwiftUI

/// The Ghost palette: deep space lit by cold starlight.
///
/// Two layers, and the split is a rule rather than a suggestion. The
/// **palette** names a pigment; the **semantic** aliases name a job.
/// `DesignSystem/` may reach for pigments — it *is* the paint layer.
/// `Features/` may not: screens speak only in semantic names, so the
/// pigments can be re-mixed without a sweep through every view.
///
/// Blue-white is the identity here, not an accent — it lives in the
/// ambient glow, the eye, and the tint of every glass surface. The one
/// rule that keeps it luminous rather than loud: `ghostAstral` is a
/// *field* colour (fills, glows, glass tints, strokes) and never small
/// text, where on the ground it sits below contrast. Bright type uses
/// `ghostStarlight`, which carries text at better than 12:1.
extension Color {

    // MARK: - Palette

    /// The void — the ground at the edges of every screen, and the colour
    /// the launch screen is painted so the first frame doesn't step.
    static let ghostVoid = Color(hex: 0x05070F)
    /// Indigo abyss — the ground at the centre, where the light is.
    /// Faintly blue-shifted so the dark reads as depth, not absence.
    static let ghostAbyss = Color(hex: 0x0A0E1C)
    /// Raised slate — the opaque stand-in for regular glass when the user
    /// has asked for reduced transparency.
    static let ghostSlate = Color(hex: 0x161C2E)
    /// Slate with astral folded into it — the opaque stand-in for aurora
    /// glass, so Ghost's own surfaces stay distinguishable from the
    /// interface's even with transparency switched off.
    static let ghostSlateAurora = Color(hex: 0x152244)

    /// Astral blue. The identity. Fields, glows and glass tints only.
    static let ghostAstral = Color(hex: 0x4C7DE0)
    /// Deep current — the floor of a glow, and the eye's outer dark.
    static let ghostAstralDeep = Color(hex: 0x1D3B7A)
    /// Starlight. Bright enough to carry text and glyphs at 12:1.
    static let ghostStarlight = Color(hex: 0xA8DCFF)
    /// Nebula violet — the quiet secondary, for anything that shouldn't
    /// compete with astral.
    static let ghostNebula = Color(hex: 0x7061B8)

    /// Distant dawn — a desaturated ember warmth. Atmosphere only, and
    /// never above ~0.2 alpha.
    ///
    /// Blue on blue on black goes glassy and cold in the wrong way: with
    /// nothing warm anywhere in the frame the eye has no reference and
    /// every cool tone flattens into the same note. In a night sky the
    /// stars read as cold precisely because somewhere at the horizon
    /// there is a trace of warmth. This is that trace — far enough back
    /// that the app never reads as warm, present enough to make the
    /// starlight sing.
    static let ghostDawn = Color(hex: 0x5C4530)

    /// Star white — cool off-white. Never pure white; pure white is cheap.
    static let ghostStarWhite = Color(hex: 0xEAF0F8)
    /// Mist — secondary type.
    static let ghostMist = Color(hex: 0x9AA5BD)
    /// Smoke — tertiary type. Held at 5.3:1 so it still passes AA.
    static let ghostSmoke = Color(hex: 0x7C87A0)

    /// Crimson — the only red left in the app, which is exactly what makes
    /// destructive actions unmistakable against an all-cool interface.
    static let ghostCrimson = Color(hex: 0xFF3B5C)

    // MARK: - Semantic

    /// The ground behind everything.
    static let ghostBackground = ghostVoid

    /// Fills, glows, glass tints, the eye. **Not** small text.
    static let ghostAccent = ghostAstral
    /// Bright type and glyphs — passes AA where `ghostAccent` would not.
    static let ghostAccentText = ghostStarlight

    static let ghostTextPrimary = ghostStarWhite
    static let ghostTextSecondary = ghostMist
    static let ghostTextTertiary = ghostSmoke

    static let ghostDanger = ghostCrimson
}

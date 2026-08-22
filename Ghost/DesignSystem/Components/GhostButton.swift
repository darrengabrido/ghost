import SwiftUI

/// The one button in Ghost. Liquid Glass throughout, because a filled
/// rectangle would be the only opaque object in an app made of light.
///
/// Note that `.primary` tints with `ghostAstral` while `.subtle` tints
/// with `ghostStarlight`: prominent glass carries its own label contrast,
/// but plain glass leaves the label on the background, where astral would
/// fall below AA. Same cold-light family, two jobs.
struct GhostButton: View {
    enum Style {
        case primary
        case subtle
        case destructive
    }

    var title: String
    var style: Style = .primary
    /// Full-bleed or hugging. Hugging is the default because a
    /// full-width filled slab is the least considered shape a button can
    /// take; reach for `isWide` only when a control genuinely needs to
    /// span its container.
    var isWide = false
    var action: () -> Void

    var body: some View {
        switch style {
        case .primary:
            label
                .buttonStyle(.glassProminent)
                .tint(Color.ghostAstral)
        case .subtle:
            label
                .buttonStyle(.glass)
                .tint(Color.ghostStarlight)
        case .destructive:
            label
                .buttonStyle(.glass)
                .tint(Color.ghostCrimson)
        }
    }

    private var label: some View {
        Button(action: action) {
            Text(title)
                .font(.ghostBody.weight(.medium))
                .tracking(Tracking.loose)
                .frame(maxWidth: isWide ? .infinity : nil)
                .padding(.horizontal, isWide ? 0 : Theme.Spacing.xl)
                .padding(.vertical, Theme.Spacing.sm)
        }
        .controlSize(.large)
    }
}

#Preview {
    ZStack {
        GhostAtmosphereBackground()
        GhostGlassContainer(spacing: Theme.Spacing.md) {
            VStack(spacing: Theme.Spacing.md) {
                GhostButton(title: "Continue") {}
                GhostButton(title: "Not now", style: .subtle) {}
                GhostButton(title: "Erase everything", style: .destructive) {}
            }
            .padding(Theme.Spacing.xl)
        }
    }
}

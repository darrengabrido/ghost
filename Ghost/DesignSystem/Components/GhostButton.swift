import SwiftUI

/// The one button in Ghost. Liquid Glass throughout, because a filled
/// rectangle would be the only opaque object in an app made of light.
///
/// Note that `.primary` tints with `ghostMaple` while `.subtle` tints with
/// `ghostFlare`: prominent glass carries its own label contrast, but plain
/// glass leaves the label on the background, where maple would fall to
/// 3.3:1. Same red family, two jobs.
struct GhostButton: View {
    enum Style {
        case primary
        case subtle
        case destructive
    }

    var title: String
    var style: Style = .primary
    /// Primary actions fill their container; secondary ones hug.
    var isWide = true
    var action: () -> Void

    var body: some View {
        switch style {
        case .primary:
            label
                .buttonStyle(.glassProminent)
                .tint(Color.ghostMaple)
        case .subtle:
            label
                .buttonStyle(.glass)
                .tint(Color.ghostFlare)
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
                GhostButton(title: "Erase everything", style: .destructive, isWide: false) {}
            }
            .padding(Theme.Spacing.xl)
        }
    }
}

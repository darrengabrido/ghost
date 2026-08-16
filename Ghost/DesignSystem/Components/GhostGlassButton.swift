import SwiftUI

/// Compact capsule actions for any remaining sibling glass controls.
/// Settings primary actions now live *on* glass cards as accent text,
/// so they are not wrapped in a second glass material.
struct GhostGlassButton: View {
    enum Style {
        case prominent
        case regular
        case danger
    }

    var title: String
    var style: Style = .regular
    var action: () -> Void

    var body: some View {
        if #available(iOS 26, *) {
            modernButton
        } else {
            fallbackButton
        }
    }

    @available(iOS 26, *)
    @ViewBuilder
    private var modernButton: some View {
        switch style {
        case .prominent:
            Button(title, action: action)
                .font(.ghostBody.weight(.medium))
                .buttonStyle(.glassProminent)
                .tint(Color.ghostAccent)
        case .regular:
            Button(title, action: action)
                .font(.ghostBody.weight(.medium))
                .buttonStyle(.glass)
        case .danger:
            Button(title, action: action)
                .font(.ghostBody.weight(.medium))
                .buttonStyle(.glass)
                .foregroundStyle(Color.ghostDanger)
        }
    }

    private var fallbackButton: some View {
        Button(action: action) {
            Text(title)
                .font(.ghostBody.weight(.medium))
                .foregroundStyle(fallbackForeground)
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.sm)
                .background(fallbackBackground)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(fallbackStroke))
        }
        .buttonStyle(.plain)
    }

    private var fallbackForeground: Color {
        style == .danger ? .ghostDanger : .ghostTextPrimary
    }

    private var fallbackBackground: Color {
        style == .prominent ? Color.ghostAccent.opacity(0.18) : Color.ghostSurface
    }

    private var fallbackStroke: Color {
        switch style {
        case .prominent: Color.ghostAccent.opacity(0.6)
        case .regular: Color.ghostAccent.opacity(0.15)
        case .danger: Color.ghostDanger.opacity(0.4)
        }
    }
}

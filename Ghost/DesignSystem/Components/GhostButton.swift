import SwiftUI

/// The one button style Ghost uses. Deliberately quiet: a soft glass
/// surface rather than a loud filled button, to stay in tone with a
/// minimal, atmospheric UI.
struct GhostButton: View {
    enum Style {
        case primary
        case subtle
    }

    var title: String
    var style: Style = .primary
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.ghostBody.weight(.medium))
                .foregroundStyle(foregroundColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                        .strokeBorder(Color.ghostAccent.opacity(style == .primary ? 0.6 : 0.15))
                )
        }
        .buttonStyle(.plain)
    }

    private var foregroundColor: Color {
        style == .primary ? .ghostTextPrimary : .ghostTextSecondary
    }

    private var background: some ShapeStyle {
        switch style {
        case .primary: AnyShapeStyle(Color.ghostAccent.opacity(0.18))
        case .subtle: AnyShapeStyle(Color.ghostSurface)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        GhostButton(title: "Continue", style: .primary) {}
        GhostButton(title: "Not now", style: .subtle) {}
    }
    .padding()
    .background(Color.ghostBackground)
}

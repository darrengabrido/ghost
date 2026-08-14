import SwiftUI

/// A slow, ambient scale+opacity pulse — the base motion language for
/// anything meant to feel "alive" (the orb, glows, idle indicators).
struct BreathingModifier: ViewModifier {
    var isActive: Bool = true
    @State private var isExpanded = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isExpanded ? 1.06 : 0.94)
            .opacity(isExpanded ? 1.0 : 0.75)
            .onAppear {
                guard isActive else { return }
                withAnimation(Theme.Motion.breathe) {
                    isExpanded = true
                }
            }
    }
}

extension View {
    func breathing(isActive: Bool = true) -> some View {
        modifier(BreathingModifier(isActive: isActive))
    }
}

import SwiftUI

/// A slow, ambient scale+opacity pulse — the base motion language for
/// anything meant to feel alive.
///
/// Narrower than a typical "pulse" on purpose: a big swing reads as a
/// loading indicator, a small one reads as breath.
struct BreathingModifier: ViewModifier {
    var isActive = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isExpanded = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isExpanded ? 1.04 : 0.97)
            .opacity(isExpanded ? 1.0 : 0.85)
            .onAppear {
                guard isActive, !reduceMotion else { return }
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

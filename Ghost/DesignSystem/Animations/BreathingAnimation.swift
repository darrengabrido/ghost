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
            .onAppear(perform: sync)
            // Without this the breath only ever starts for a view that was
            // already active when it mounted — the eye wakes from idle
            // after appearing, so `onAppear` alone leaves it inert for the
            // entire life of the screen.
            .onChange(of: isActive) { _, _ in sync() }
            // Same reasoning for Reduce Motion: it can be toggled mid-screen,
            // and without this the repeat-forever breath outlives the setting.
            .onChange(of: reduceMotion) { _, _ in sync() }
    }

    private func sync() {
        guard !LaunchFlags.isUITesting else {
            // Screenshots hold the fully-open pose, unanimated, so the frame
            // is the same one every run.
            withAnimation(nil) { isExpanded = true }
            return
        }
        guard isActive, !reduceMotion else {
            withAnimation(Theme.Motion.quick) { isExpanded = false }
            return
        }
        withAnimation(Theme.Motion.breathe) { isExpanded = true }
    }
}

extension View {
    func breathing(isActive: Bool = true) -> some View {
        modifier(BreathingModifier(isActive: isActive))
    }
}

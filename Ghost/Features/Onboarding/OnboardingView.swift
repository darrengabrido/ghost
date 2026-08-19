import SwiftUI

struct OnboardingView: View {
    var viewModel: OnboardingViewModel

    var body: some View {
        ZStack {
            // Held back from full strength: the room hasn't woken yet.
            GhostAtmosphereBackground(intensity: 0.7)

            VStack(spacing: Theme.Spacing.xxl) {
                Spacer()

                PulsingOrb(state: .idle, diameter: 190)

                VStack(spacing: Theme.Spacing.md) {
                    Text("onboarding.title")
                        .font(.ghostDisplay)
                        .tracking(Tracking.display)
                        .foregroundStyle(Self.titleGradient)
                        .multilineTextAlignment(.center)

                    Text("onboarding.subtitle")
                        .font(.ghostBody)
                        .foregroundStyle(Color.ghostTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                }
                .padding(.horizontal, Theme.Spacing.xl)

                Spacer()

                GhostGlassContainer {
                    GhostButton(title: String(localized: "onboarding.continue")) {
                        viewModel.continueTapped()
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xl)
            }
        }
        .toolbar(.hidden)
    }

    /// The title fades toward mist at its baseline, as though the words are
    /// only half-surfaced out of the dark.
    private static let titleGradient = LinearGradient(
        colors: [.ghostBone, .ghostMist],
        startPoint: .top,
        endPoint: .bottom
    )
}

#Preview {
    OnboardingView(viewModel: OnboardingViewModel(router: AppRouter()))
}

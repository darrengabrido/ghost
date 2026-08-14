import SwiftUI

struct OnboardingView: View {
    var viewModel: OnboardingViewModel

    var body: some View {
        ZStack {
            Color.ghostBackground.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.xl) {
                Spacer()

                PulsingOrb(state: .idle, diameter: 180)

                VStack(spacing: Theme.Spacing.sm) {
                    Text("onboarding.title")
                        .font(.ghostDisplay)
                        .foregroundStyle(Color.ghostTextPrimary)
                        .multilineTextAlignment(.center)

                    Text("onboarding.subtitle")
                        .font(.ghostBody)
                        .foregroundStyle(Color.ghostTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, Theme.Spacing.lg)

                Spacer()

                GhostButton(title: String(localized: "onboarding.continue")) {
                    viewModel.continueTapped()
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.lg)
            }
        }
        .toolbar(.hidden)
    }
}

#Preview {
    OnboardingView(viewModel: OnboardingViewModel(router: AppRouter()))
}

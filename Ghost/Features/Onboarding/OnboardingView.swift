import SwiftUI

struct OnboardingView: View {
    var viewModel: OnboardingViewModel

    var body: some View {
        ZStack {
            // Held back from full strength: the sky hasn't woken yet.
            GhostAtmosphereBackground(intensity: 0.7)

            // Centred when it fits, scrollable when it doesn't. Onboarding
            // hides the toolbar and offers no other route into the app, so
            // the Continue button being pushed off a short screen — or off a
            // normal screen at accessibility type sizes — would strand the
            // user completely. `minHeight` makes the spacers do the centring
            // in the common case and lets the content overflow in the rest.
            GeometryReader { geometry in
                ScrollView {
                    content
                        .frame(minHeight: geometry.size.height)
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollIndicators(.hidden)
            }
        }
        .toolbar(.hidden)
    }

    private var content: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer(minLength: 0)

            SpiritWisp(state: .idle, diameter: 190)

            VStack(spacing: Theme.Spacing.md) {
                Text("onboarding.title")
                    .font(.ghostDisplay)
                    .tracking(Tracking.display)
                    .foregroundStyle(Self.titleGradient)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)

                Text("onboarding.subtitle")
                    .font(.ghostBody)
                    .foregroundStyle(Color.ghostTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
            }

            Spacer(minLength: 0)

            GhostGlassContainer {
                GhostButton(title: String(localized: "onboarding.continue")) {
                    viewModel.continueTapped()
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.xl)
    }

    /// The title fades toward mist at its baseline, as though the words are
    /// only half-surfaced out of the dark.
    private static let titleGradient = LinearGradient(
        colors: [.ghostTextPrimary, .ghostTextSecondary],
        startPoint: .top,
        endPoint: .bottom
    )
}

#Preview {
    OnboardingView(viewModel: OnboardingViewModel(router: AppRouter()))
}

import SwiftUI

@main
struct GhostApp: App {
    @State private var environment = AppEnvironment.live()

    var body: some Scene {
        WindowGroup {
            AppRootView(environment: environment)
                .preferredColorScheme(.dark)
        }
    }
}

/// Top-level view that hosts the router and hands the composition root
/// down to whichever feature is currently active.
private struct AppRootView: View {
    let environment: AppEnvironment
    @State private var router = AppRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            OnboardingView(
                viewModel: OnboardingViewModel(router: router)
            )
            .navigationDestination(for: Route.self) { route in
                router.destination(for: route, environment: environment)
            }
        }
        .tint(Color.ghostAccentText)
        .background(Color.ghostBackground.ignoresSafeArea())
    }
}

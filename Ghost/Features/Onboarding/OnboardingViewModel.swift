import Foundation

@Observable
@MainActor
final class OnboardingViewModel {
    private let router: AppRouter

    init(router: AppRouter) {
        self.router = router
    }

    func continueTapped() {
        router.push(.conversation)
    }
}

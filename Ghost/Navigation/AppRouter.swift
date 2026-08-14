import SwiftUI

/// Owns the navigation stack and knows how to build the View for a given
/// `Route`, wiring each feature's ViewModel from the shared `AppEnvironment`.
/// Kept separate from `AppEnvironment` itself so navigation state doesn't
/// get mixed into the composition root.
@Observable
@MainActor
final class AppRouter {
    var path = NavigationPath()

    func push(_ route: Route) {
        path.append(route)
    }

    func popToRoot() {
        path.removeLast(path.count)
    }

    @ViewBuilder
    func destination(for route: Route, environment: AppEnvironment) -> some View {
        switch route {
        case .conversation:
            ConversationView(
                viewModel: ConversationViewModel(
                    voiceEngine: environment.voiceEngine,
                    aiConversationService: environment.aiConversationService,
                    conversationStore: environment.conversationStore
                )
            )
        case .history:
            HistoryView(
                viewModel: HistoryViewModel(conversationStore: environment.conversationStore)
            )
        case .settings:
            SettingsView(viewModel: SettingsViewModel())
        }
    }
}

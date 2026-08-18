import SwiftUI

struct HistoryView: View {
    @Bindable var viewModel: HistoryViewModel

    var body: some View {
        ZStack {
            Color.ghostBackground.ignoresSafeArea()

            if viewModel.conversations.isEmpty {
                Text("history.empty")
                    .font(.ghostBody)
                    .foregroundStyle(Color.ghostTextSecondary)
            } else if viewModel.filteredConversations.isEmpty {
                Text("history.noResults")
                    .font(.ghostBody)
                    .foregroundStyle(Color.ghostTextSecondary)
            } else {
                List {
                    ForEach(viewModel.filteredConversations) { record in
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text(record.title)
                                .font(.ghostBody)
                                .foregroundStyle(Color.ghostTextPrimary)
                            Text(record.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.ghostCaption)
                                .foregroundStyle(Color.ghostTextTertiary)
                        }
                        .listRowBackground(Color.ghostSurface)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let record = viewModel.filteredConversations[index]
                            Task { await viewModel.delete(record) }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle(String(localized: "history.title"))
        .searchable(text: $viewModel.searchText, prompt: String(localized: "history.search.prompt"))
        .task { await viewModel.load() }
    }
}

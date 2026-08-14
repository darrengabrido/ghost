import SwiftUI

struct HistoryView: View {
    var viewModel: HistoryViewModel

    var body: some View {
        ZStack {
            Color.ghostBackground.ignoresSafeArea()

            if viewModel.conversations.isEmpty {
                Text("history.empty")
                    .font(.ghostBody)
                    .foregroundStyle(Color.ghostTextSecondary)
            } else {
                List {
                    ForEach(viewModel.conversations) { record in
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
                            let record = viewModel.conversations[index]
                            Task { await viewModel.delete(record) }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle(String(localized: "history.title"))
        .task { await viewModel.load() }
    }
}

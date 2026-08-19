import SwiftUI

struct HistoryView: View {
    var viewModel: HistoryViewModel

    var body: some View {
        ZStack {
            GhostAtmosphereBackground(intensity: 0.6)

            if viewModel.conversations.isEmpty {
                emptyState
            } else {
                conversationList
            }
        }
        .navigationTitle(String(localized: "history.title"))
        .task { await viewModel.load() }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            PulsingOrb(state: .idle, diameter: 76)
                .opacity(0.5)

            Text("history.empty")
                .font(.ghostTitle)
                .foregroundStyle(Color.ghostTextSecondary)
                .multilineTextAlignment(.center)
        }
    }

    /// Still a `List` rather than a hand-rolled stack: swipe-to-delete,
    /// its accessibility, and the edit affordances all come free here, and
    /// none of them are worth reimplementing for a visual result that
    /// `.listRowBackground(.clear)` already gets us.
    private var conversationList: some View {
        List {
            ForEach(viewModel.conversations) { record in
                row(for: record)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(
                        EdgeInsets(
                            top: Theme.Spacing.xs,
                            leading: Theme.Spacing.md,
                            bottom: Theme.Spacing.xs,
                            trailing: Theme.Spacing.md
                        )
                    )
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let record = viewModel.conversations[index]
                    Task { await viewModel.delete(record) }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
    }

    private func row(for record: ConversationRecord) -> some View {
        // `.regular`, not `.interactive`: interactive glass lifts under a
        // finger, and there is no conversation-detail route for these rows
        // to open. An affordance that promises a tap and does nothing is
        // worse than no affordance.
        GhostGlass(cornerRadius: Theme.Radius.md) {
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                // A dim ember standing in for the orb — each conversation
                // is one of the times the presence was awake.
                Circle()
                    .fill(Color.ghostAccent)
                    .frame(width: 5, height: 5)
                    .padding(.top, 7)

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(record.title)
                        .font(.ghostVoice)
                        .foregroundStyle(Color.ghostTextPrimary)
                        .lineLimit(2)

                    Text(record.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.ghostLabel)
                        .tracking(Tracking.wide)
                        .foregroundStyle(Color.ghostTextTertiary)
                }

                Spacer(minLength: 0)
            }
            .padding(Theme.Spacing.md)
        }
    }
}

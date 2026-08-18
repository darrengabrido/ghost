import SwiftUI

struct ConversationView: View {
    var viewModel: ConversationViewModel
    var router: AppRouter

    var body: some View {
        ZStack {
            Color.ghostBackground.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                transcriptList

                Spacer(minLength: 0)

                VStack(spacing: Theme.Spacing.md) {
                    PulsingOrb(state: viewModel.orbState, diameter: 160)
                        .onTapGesture { viewModel.micTapped() }

                    if viewModel.orbState == .listening {
                        WaveformView(levels: viewModel.audioLevels)
                    }

                    Text(statusText)
                        .font(.ghostCaption)
                        .foregroundStyle(Color.ghostTextSecondary)
                }
                .padding(.bottom, Theme.Spacing.xl)
            }
            .padding(.top, Theme.Spacing.lg)
        }
        .task { await viewModel.start() }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    router.push(.history)
                } label: {
                    Image(systemName: "clock")
                }
                .accessibilityLabel(String(localized: "history.title"))
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    router.push(.settings)
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel(String(localized: "settings.title"))
            }
        }
        .alert(
            "Something went wrong",
            isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var transcriptList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                ForEach(viewModel.messages) { message in
                    MessageBubble(message: message)
                }

                if !viewModel.liveTranscript.isEmpty {
                    Text(viewModel.liveTranscript)
                        .font(.ghostBody)
                        .foregroundStyle(Color.ghostTextTertiary)
                        .padding(.horizontal, Theme.Spacing.md)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private var statusText: LocalizedStringKey {
        switch viewModel.orbState {
        case .idle: "conversation.idle"
        case .listening: "conversation.listening"
        case .thinking: "conversation.thinking"
        case .speaking: "conversation.speaking"
        }
    }
}

private struct MessageBubble: View {
    let message: Message

    var body: some View {
        HStack {
            if message.speaker == .ghost { Spacer(minLength: 40) }

            Text(message.text)
                .font(.ghostBody)
                .foregroundStyle(Color.ghostTextPrimary)
                .padding(Theme.Spacing.md)
                .background(BlurBackground(cornerRadius: Theme.Radius.md))

            if message.speaker == .user { Spacer(minLength: 40) }
        }
    }
}

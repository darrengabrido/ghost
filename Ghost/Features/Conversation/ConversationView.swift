import SwiftUI

struct ConversationView: View {
    var viewModel: ConversationViewModel
    var router: AppRouter

    var body: some View {
        ZStack {
            GhostAtmosphereBackground(intensity: atmosphereIntensity)
                .animation(Theme.Motion.settle, value: viewModel.orbState)

            VStack(spacing: Theme.Spacing.lg) {
                transcriptList

                Spacer(minLength: 0)

                orbCluster
                    .padding(.bottom, Theme.Spacing.xl)
            }
            .padding(.top, Theme.Spacing.md)
        }
        .task { await viewModel.start() }
        .toolbar { toolbarItems }
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

    /// The room brightens and the wind picks up while Ghost is awake, then
    /// settles back when it stops. This is the main way the app signals
    /// state — the status caption below the orb is only a caption.
    private var atmosphereIntensity: Double {
        switch viewModel.orbState {
        case .idle: 0.55
        case .listening: 1.0
        case .thinking: 0.85
        case .speaking: 0.95
        }
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
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

    private var transcriptList: some View {
        // Deliberately not wrapped in a GhostGlassContainer: that shares
        // one lighting model across its children, which is right for a
        // handful of sibling cards and wrong for an unbounded scrolling
        // list.
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Theme.Spacing.md) {
                ForEach(viewModel.messages) { message in
                    MessageBubble(message: message)
                }

                if !viewModel.liveTranscript.isEmpty {
                    liveTranscript
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
        .scrollIndicators(.hidden)
        // The transcript dissolves into the dark at the top rather than
        // being cut off by an edge.
        .mask { Self.topFade }
    }

    private var liveTranscript: some View {
        Text(viewModel.liveTranscript)
            .font(.ghostBody)
            .italic()
            .foregroundStyle(Color.ghostTextTertiary)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.leading, Theme.Spacing.xl)
    }

    private var orbCluster: some View {
        VStack(spacing: Theme.Spacing.md) {
            Button {
                viewModel.micTapped()
            } label: {
                PulsingOrb(state: viewModel.orbState, diameter: 168)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(statusText))

            // Reserved height so the orb never shifts when listening
            // starts or stops.
            ZStack {
                if viewModel.orbState == .listening {
                    WaveformView(levels: viewModel.audioLevels)
                }
            }
            .frame(height: 44)

            Text(statusText)
                .font(.ghostLabel)
                .tracking(Tracking.wide)
                .foregroundStyle(Color.ghostTextSecondary)
        }
    }

    private static let topFade = LinearGradient(
        colors: [.clear, .black, .black],
        startPoint: .top,
        endPoint: .init(x: 0.5, y: 0.22)
    )

    private var statusText: LocalizedStringKey {
        switch viewModel.orbState {
        case .idle: "conversation.idle"
        case .listening: "conversation.listening"
        case .thinking: "conversation.thinking"
        case .speaking: "conversation.speaking"
        }
    }
}

/// User speech sits in neutral glass on the right; Ghost's own words sit
/// in maple-tinted glass on the left, set in serif. The tint and the
/// typeface both mean the same thing — this half of the transcript is the
/// presence talking, not the interface.
private struct MessageBubble: View {
    let message: Message

    private var isGhost: Bool { message.speaker == .ghost }

    var body: some View {
        HStack(spacing: 0) {
            if !isGhost { Spacer(minLength: Theme.Spacing.xl) }

            GhostGlass(
                style: isGhost ? .ember : .regular,
                cornerRadius: Theme.Radius.md
            ) {
                Text(message.text)
                    .font(isGhost ? .ghostVoice : .ghostBody)
                    .foregroundStyle(Color.ghostTextPrimary)
                    .lineSpacing(3)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm + Theme.Spacing.xs)
            }

            if isGhost { Spacer(minLength: Theme.Spacing.xl) }
        }
    }
}

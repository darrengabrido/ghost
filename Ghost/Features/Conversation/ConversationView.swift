import SwiftUI

struct ConversationView: View {
    var viewModel: ConversationViewModel
    var router: AppRouter

    /// The screen has two compositions, not one. With nothing said yet the
    /// orb is centred and alone; once there's a transcript it settles to
    /// the bottom and gives the words the room. Pinning it to the bottom
    /// from the start leaves the first screen you ever see 70% empty with
    /// its only subject stranded at the edge.
    private var hasTranscript: Bool {
        !viewModel.messages.isEmpty || !viewModel.liveTranscript.isEmpty
    }

    var body: some View {
        ZStack {
            GhostAtmosphereBackground(intensity: atmosphereIntensity)
                .animation(Theme.Motion.settle, value: viewModel.orbState)

            VStack(spacing: Theme.Spacing.lg) {
                if hasTranscript {
                    transcriptList
                        .transition(.opacity)
                } else {
                    Spacer(minLength: 0)
                }

                orbCluster
                    .padding(.bottom, hasTranscript ? Theme.Spacing.xl : 0)

                if !hasTranscript {
                    Spacer(minLength: 0)
                }
            }
            .padding(.top, Theme.Spacing.md)
            .animation(Theme.Motion.morph, value: hasTranscript)
        }
        .task { await viewModel.start() }
        // Onboarding is behind this screen on the navigation stack, and the
        // system back chevron happily took you there — crowding the History
        // button in the first render and offering a "back" that means
        // nothing. Once you're in, you're in.
        .navigationBarBackButtonHidden(true)
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
    /// state — the caption under the orb is only a caption.
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

    // MARK: - Transcript

    private var transcriptList: some View {
        // Deliberately not wrapped in a GhostGlassContainer: that shares
        // one lighting model across its children, which is right for a
        // handful of sibling cards and wrong for an unbounded list.
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                        MessageBubble(message: message)
                            .padding(.top, spacingBefore(index))
                    }

                    if !viewModel.liveTranscript.isEmpty {
                        liveTranscript
                            .padding(.top, Theme.Spacing.md)
                    }

                    Color.clear
                        .frame(height: 1)
                        .id(Self.bottomAnchor)
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
            .scrollIndicators(.hidden)
            // Dissolves into the dark at the top instead of being cut by an
            // edge. The bottom only half-fades — the newest line is the one
            // you most need to read.
            .mask { Self.edgeFade }
            .onChange(of: viewModel.messages.count) { _, _ in scrollToLatest(proxy) }
            .onChange(of: viewModel.liveTranscript) { _, _ in scrollToLatest(proxy) }
        }
    }

    /// Consecutive turns from the same speaker sit close together and a
    /// change of speaker opens a gap, so the transcript has the rhythm of
    /// a conversation rather than an evenly spaced list.
    private func spacingBefore(_ index: Int) -> CGFloat {
        guard index > 0 else { return 0 }
        let isSameSpeaker = viewModel.messages[index - 1].speaker == viewModel.messages[index].speaker
        return isSameSpeaker ? Theme.Spacing.xs : Theme.Spacing.md
    }

    private func scrollToLatest(_ proxy: ScrollViewProxy) {
        withAnimation(Theme.Motion.settle) {
            proxy.scrollTo(Self.bottomAnchor, anchor: .bottom)
        }
    }

    private var liveTranscript: some View {
        Text(viewModel.liveTranscript)
            .font(.ghostBody)
            .italic()
            .foregroundStyle(Color.ghostTextSecondary)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.leading, Theme.Spacing.xl)
    }

    // MARK: - Orb

    private var orbCluster: some View {
        VStack(spacing: Theme.Spacing.md) {
            Button {
                viewModel.micTapped()
            } label: {
                PulsingOrb(state: viewModel.orbState, diameter: 168)
            }
            .buttonStyle(OrbPressStyle())
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
                .contentTransition(.opacity)
                .animation(Theme.Motion.quick, value: viewModel.orbState)
        }
    }

    private static let bottomAnchor = "transcript.bottom"

    private static let edgeFade = LinearGradient(
        stops: [
            .init(color: .clear, location: 0),
            .init(color: .black, location: 0.10),
            .init(color: .black, location: 0.93),
            .init(color: .black.opacity(0.25), location: 1)
        ],
        startPoint: .top,
        endPoint: .bottom
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

/// The orb needs to acknowledge a press without a button chrome appearing
/// around it. `.plain` gives no feedback at all, which on the app's only
/// control reads as a dropped tap.
private struct OrbPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
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

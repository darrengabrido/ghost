import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var isConfirmingClearHistory = false

    var body: some View {
        ZStack {
            GhostAtmosphereBackground()

            ScrollView {
                GhostGlassContainer(spacing: Theme.Spacing.xl) {
                    VStack(spacing: Theme.Spacing.xl) {
                        voiceSection
                        apiKeySection
                        dataSection
                        aboutSection
                    }
                }
                .padding(Theme.Spacing.md)
            }
        }
        .navigationTitle(String(localized: "settings.title"))
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
        .confirmationDialog(
            String(localized: "settings.data.clear.confirm.title"),
            isPresented: $isConfirmingClearHistory,
            titleVisibility: .visible
        ) {
            Button(String(localized: "settings.data.clear.confirm"), role: .destructive) {
                Task { await viewModel.clearHistory() }
            }
        } message: {
            Text("settings.data.clear.confirm.message")
        }
    }

    private var voiceSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionLabel("settings.voice")
            GhostGlass {
                VStack(spacing: 0) {
                    NavigationLink {
                        VoicePickerView(viewModel: viewModel)
                    } label: {
                        voiceIdentityRow
                    }

                    settingsDivider

                    speechRateBlock
                        .padding(.vertical, Theme.Spacing.md)

                    settingsDivider

                    Toggle("settings.voice.interrupt", isOn: $viewModel.isVoiceInterruptionEnabled)
                        .font(.ghostBody)
                        .foregroundStyle(Color.ghostTextPrimary)
                        .tint(Color.ghostAccent)
                        .padding(.vertical, Theme.Spacing.md)

                    settingsDivider

                    HStack {
                        Spacer()
                        Button(String(localized: "settings.voice.hearSample")) {
                            Task { await viewModel.previewVoice() }
                        }
                        .font(.ghostBody.weight(.medium))
                        .foregroundStyle(Color.ghostAccentText)
                        .buttonStyle(.plain)
                    }
                    .padding(.top, Theme.Spacing.md)
                }
                .padding(Theme.Spacing.lg)
            }
        }
    }

    private var voiceIdentityRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "speaker.wave.2")
                .font(.ghostBody)
                .foregroundStyle(Color.ghostAccentText)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("settings.voice.identity")
                    .font(.ghostBody)
                    .foregroundStyle(Color.ghostTextPrimary)
                Text(viewModel.selectedVoiceName)
                    .font(.ghostCaption)
                    .foregroundStyle(Color.ghostTextSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.ghostCaption)
                .foregroundStyle(Color.ghostTextTertiary)
        }
        .padding(.bottom, Theme.Spacing.md)
    }

    private var speechRateBlock: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("settings.voice.rate")
                .font(.ghostBody)
                .foregroundStyle(Color.ghostTextPrimary)
            Slider(value: $viewModel.speechRate, in: 0...1)
                .tint(Color.ghostAccent)
            HStack {
                Text("settings.voice.rate.slow")
                Spacer()
                Text("settings.voice.rate.fast")
            }
            .font(.ghostCaption)
            .foregroundStyle(Color.ghostTextTertiary)
        }
    }

    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionLabel("settings.api")
            GhostGlass {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    apiStatusCapsule

                    Text("settings.api.hint")
                        .font(.ghostCaption)
                        .foregroundStyle(Color.ghostTextSecondary)

                    SecureField(
                        String(localized: "settings.api.key.placeholder"),
                        text: $viewModel.draftAPIKey
                    )
                    .textContentType(.password)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.ghostBody)
                    .foregroundStyle(Color.ghostTextPrimary)
                    .padding(Theme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                            .fill(Color.ghostSumi.opacity(0.6))
                    )

                    HStack {
                        if viewModel.keychainHasKey {
                            Button(String(localized: "settings.api.remove"), action: viewModel.removeAPIKey)
                                .font(.ghostBody)
                                .foregroundStyle(Color.ghostTextSecondary)
                                .buttonStyle(.plain)
                        }
                        Spacer()
                        Button(String(localized: "settings.api.save"), action: viewModel.saveAPIKey)
                            .font(.ghostBody.weight(.medium))
                            .foregroundStyle(Color.ghostAccentText)
                            .buttonStyle(.plain)
                    }
                }
                .padding(Theme.Spacing.lg)
            }
        }
    }

    private var apiStatusCapsule: some View {
        Text(apiKeyStatusShort)
            .font(.ghostCaption.weight(.medium))
            .foregroundStyle(apiKeyStatusForeground)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(apiKeyStatusForeground.opacity(0.16), in: Capsule())
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionLabel("settings.data")
            GhostGlass {
                Button {
                    isConfirmingClearHistory = true
                } label: {
                    // Ghost's brand colour is already red, so a red label
                    // alone can't mark this as destructive. The glyph does.
                    Label("settings.data.clear", systemImage: "trash")
                        .font(.ghostBody)
                        .foregroundStyle(Color.ghostDanger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(Theme.Spacing.lg)
            }
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionLabel("settings.about")
            GhostGlass {
                VStack(spacing: 0) {
                    aboutRow(
                        label: String(localized: "settings.about.version"),
                        value: viewModel.version
                    )
                    settingsDivider
                        .padding(.vertical, Theme.Spacing.md)
                    aboutRow(
                        label: String(localized: "settings.about.build"),
                        value: viewModel.build
                    )
                }
                .padding(Theme.Spacing.lg)
            }
        }
    }

    private func sectionLabel(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.ghostLabel)
            .tracking(Tracking.wide)
            .foregroundStyle(Color.ghostTextSecondary)
            .padding(.horizontal, Theme.Spacing.sm)
    }

    private func aboutRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.ghostBody)
                .foregroundStyle(Color.ghostTextPrimary)
            Spacer()
            Text(value)
                .font(.ghostCaption)
                .foregroundStyle(Color.ghostTextSecondary)
        }
    }

    private var settingsDivider: some View {
        Rectangle()
            .fill(Theme.hairline(Theme.Hairline.faint))
            .frame(height: 1)
    }

    private var apiKeyStatusShort: LocalizedStringKey {
        switch viewModel.apiKeyStatus {
        case .keychain: "settings.api.status.keychain.short"
        case .buildTime: "settings.api.status.buildTime.short"
        case .missing: "settings.api.status.missing.short"
        }
    }

    private var apiKeyStatusForeground: Color {
        switch viewModel.apiKeyStatus {
        case .keychain: .ghostAccentText
        case .buildTime: .ghostTextSecondary
        case .missing: .ghostTextTertiary
        }
    }
}

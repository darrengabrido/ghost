import AVFoundation
import SwiftUI

struct VoicePickerView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        ZStack {
            GhostAtmosphereBackground()

            ScrollView {
                GhostGlassContainer {
                    GhostGlass {
                        VStack(spacing: 0) {
                            voiceRow(
                                title: String(localized: "settings.voice.default"),
                                subtitle: nil,
                                identifier: ""
                            )
                            ForEach(viewModel.englishVoices, id: \.identifier) { voice in
                                settingsDivider
                                voiceRow(
                                    title: voice.name,
                                    subtitle: qualityLabel(voice),
                                    identifier: voice.identifier
                                )
                            }
                        }
                        .padding(.vertical, Theme.Spacing.sm)
                    }
                }
                .padding(Theme.Spacing.md)
            }
        }
        .navigationTitle(String(localized: "settings.voice.picker.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func voiceRow(title: String, subtitle: String?, identifier: String) -> some View {
        let isSelected = viewModel.voiceIdentifier == identifier
        return Button {
            viewModel.voiceIdentifier = identifier
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(title)
                        .font(.ghostBody)
                        .foregroundStyle(Color.ghostTextPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.ghostCaption)
                            .foregroundStyle(Color.ghostTextSecondary)
                    }
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.ghostAccentText)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var settingsDivider: some View {
        Rectangle()
            .fill(Theme.hairline(Theme.Hairline.faint))
            .frame(height: 1)
            .padding(.leading, Theme.Spacing.lg)
    }

    private func qualityLabel(_ voice: AVSpeechSynthesisVoice) -> String {
        switch voice.quality {
        case .premium:
            String(localized: "settings.voice.quality.premium")
        case .enhanced:
            String(localized: "settings.voice.quality.enhanced")
        default:
            String(localized: "settings.voice.quality.default")
        }
    }
}

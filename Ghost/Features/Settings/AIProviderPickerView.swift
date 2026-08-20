import SwiftUI

struct AIProviderPickerView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        ZStack {
            GhostAtmosphereBackground()

            ScrollView {
                GhostGlassContainer {
                    GhostGlass {
                        VStack(spacing: 0) {
                            ForEach(AIProvider.allCases) { provider in
                                if provider != AIProvider.allCases.first {
                                    settingsDivider
                                }
                                providerRow(provider)
                            }
                        }
                        .padding(.vertical, Theme.Spacing.sm)
                    }
                }
                .padding(Theme.Spacing.md)
            }
        }
        .navigationTitle(String(localized: "settings.api.provider.picker.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func providerRow(_ provider: AIProvider) -> some View {
        let isSelected = viewModel.selectedProvider == provider
        return Button {
            viewModel.selectedProvider = provider
        } label: {
            HStack {
                Text(provider.displayName)
                    .font(.ghostBody)
                    .foregroundStyle(Color.ghostTextPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.ghostAccent)
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
            .fill(Color.ghostTextPrimary.opacity(0.06))
            .frame(height: 1)
            .padding(.leading, Theme.Spacing.lg)
    }
}

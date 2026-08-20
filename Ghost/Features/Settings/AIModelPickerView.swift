import SwiftUI

struct AIModelPickerView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        ZStack {
            GhostAtmosphereBackground()

            ScrollView {
                VStack(spacing: Theme.Spacing.md) {
                    GhostGlassContainer {
                        GhostGlass {
                            VStack(spacing: 0) {
                                let models = viewModel.selectedProvider.availableModels
                                ForEach(models, id: \.self) { model in
                                    if model != models.first {
                                        settingsDivider
                                    }
                                    modelRow(model)
                                }
                            }
                            .padding(.vertical, Theme.Spacing.sm)
                        }
                    }

                    GhostGlassContainer {
                        GhostGlass {
                            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                                Text("settings.api.model.custom.hint")
                                    .font(.ghostCaption)
                                    .foregroundStyle(Color.ghostTextSecondary)

                                TextField(viewModel.selectedModel, text: $viewModel.draftModel)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .font(.ghostBody)
                                    .foregroundStyle(Color.ghostTextPrimary)
                                    .padding(Theme.Spacing.sm)
                                    .background(
                                        RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                                            .fill(Color.ghostBackground.opacity(0.55))
                                    )

                                HStack {
                                    Spacer()
                                    Button(String(localized: "settings.api.model.custom.save")) {
                                        viewModel.selectModel(viewModel.draftModel)
                                    }
                                    .font(.ghostBody.weight(.medium))
                                    .foregroundStyle(Color.ghostAccent)
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(Theme.Spacing.lg)
                        }
                    }
                }
                .padding(Theme.Spacing.md)
            }
        }
        .navigationTitle(String(localized: "settings.api.model.picker.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func modelRow(_ model: String) -> some View {
        let isSelected = viewModel.selectedModel == model
        return Button {
            viewModel.selectModel(model)
        } label: {
            HStack {
                Text(model)
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

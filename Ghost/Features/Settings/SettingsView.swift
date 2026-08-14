import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("settings.voice") {
                Toggle("Allow interrupting Ghost while speaking", isOn: $viewModel.isVoiceInterruptionEnabled)

                VStack(alignment: .leading) {
                    Text("Speech rate")
                    Slider(value: $viewModel.speechRate)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.ghostBackground.ignoresSafeArea())
        .navigationTitle(String(localized: "settings.title"))
    }
}

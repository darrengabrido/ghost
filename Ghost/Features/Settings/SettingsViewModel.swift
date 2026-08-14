import Foundation

@Observable
@MainActor
final class SettingsViewModel {
    var isVoiceInterruptionEnabled = true
    var speechRate: Double = 0.5
}

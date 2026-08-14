import AVFoundation

/// Wraps `AVAudioSession` category management so voice recording and
/// speech playback don't fight each other.
final class AudioSessionManager {
    enum Mode {
        case record
        case playback
    }

    func activate(for mode: Mode) throws {
        let session = AVAudioSession.sharedInstance()
        switch mode {
        case .record:
            try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.duckOthers, .allowBluetooth])
        case .playback:
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        }
        try session.setActive(true)
    }

    func deactivate() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

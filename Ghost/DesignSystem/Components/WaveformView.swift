import SwiftUI

/// A minimal live waveform driven by microphone amplitude samples
/// (0...1). Intended for the listening state, directly below the orb.
struct WaveformView: View {
    var levels: [CGFloat]
    var color: Color = .ghostAccentSecondary
    var barWidth: CGFloat = 3
    var spacing: CGFloat = 4

    var body: some View {
        HStack(alignment: .center, spacing: spacing) {
            ForEach(Array(levels.enumerated()), id: \.offset) { _, level in
                RoundedRectangle(cornerRadius: barWidth / 2)
                    .fill(color)
                    .frame(width: barWidth, height: max(4, level * 48))
            }
        }
        .frame(height: 48)
        .animation(.easeInOut(duration: 0.15), value: levels)
        .accessibilityHidden(true)
    }
}

#Preview {
    ZStack {
        Color.ghostBackground.ignoresSafeArea()
        WaveformView(levels: (0..<24).map { _ in CGFloat.random(in: 0.1...1) })
    }
}

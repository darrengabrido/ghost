import SwiftUI

/// A minimal live waveform driven by microphone amplitude samples
/// (0...1). Sits directly below the orb while Ghost is listening.
struct WaveformView: View {
    var levels: [CGFloat]
    var color: Color = .ghostFlare
    var barWidth: CGFloat = 2.5
    var spacing: CGFloat = 5
    var maxHeight: CGFloat = 44

    var body: some View {
        HStack(alignment: .center, spacing: spacing) {
            ForEach(Array(levels.enumerated()), id: \.offset) { _, level in
                Capsule()
                    .fill(gradient)
                    .frame(width: barWidth, height: max(barWidth, level * maxHeight))
            }
        }
        .frame(height: maxHeight)
        .animation(.easeInOut(duration: 0.15), value: levels)
        .accessibilityHidden(true)
    }

    /// Bars burn out toward their tips rather than ending on a hard edge.
    private var gradient: LinearGradient {
        LinearGradient(
            colors: [color.opacity(0.45), color, color.opacity(0.45)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#Preview {
    ZStack {
        GhostAtmosphereBackground()
        WaveformView(levels: (0..<24).map { _ in CGFloat.random(in: 0.1...1) })
    }
}

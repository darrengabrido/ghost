import SwiftUI

/// Full-screen atmosphere so Liquid Glass has light to refract: violet
/// upper-left, quieter cyan lower-right, over Ghost's near-black canvas.
struct GhostAtmosphereBackground: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.ghostBackground
                Theme.glow(color: .ghostAccent, radius: max(geo.size.width * 0.55, 220))
                    .position(x: geo.size.width * 0.18, y: geo.size.height * 0.08)
                Theme.glow(color: .ghostAccentSecondary, radius: max(geo.size.width * 0.42, 180))
                    .position(x: geo.size.width * 0.88, y: geo.size.height * 0.78)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

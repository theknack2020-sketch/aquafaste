import SwiftUI

/// Ripple + splash effect that plays when water is logged.
/// Overlaid on the circular progress view.
struct SplashEffectView: View {
    @Binding var trigger: Bool

    @State private var ringScale: CGFloat = 0.5
    @State private var ringOpacity: Double = 0
    @State private var ring2Scale: CGFloat = 0.5
    @State private var ring2Opacity: Double = 0
    @State private var droplets: [SplashDroplet] = []

    var body: some View {
        ZStack {
            // Expanding ripple ring 1
            Circle()
                .stroke(Color.aquaPrimary.opacity(ringOpacity), lineWidth: 3)
                .scaleEffect(ringScale)

            // Expanding ripple ring 2 (delayed)
            Circle()
                .stroke(Color.aquaSecondary.opacity(ring2Opacity), lineWidth: 2)
                .scaleEffect(ring2Scale)

            // Splash droplets
            ForEach(droplets) { droplet in
                Circle()
                    .fill(Color.aquaPrimary.opacity(droplet.opacity))
                    .frame(width: droplet.size, height: droplet.size)
                    .offset(x: droplet.offset.width, y: droplet.offset.height)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, newValue in
            if newValue {
                playSplash()
                // Auto-reset
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    trigger = false
                }
            }
        }
    }

    private func playSplash() {
        // Reset
        ringScale = 0.5
        ringOpacity = 0
        ring2Scale = 0.5
        ring2Opacity = 0

        // Generate droplets
        droplets = (0..<8).map { i in
            let angle = Double(i) * (.pi * 2 / 8) + Double.random(in: -0.3...0.3)
            let distance = CGFloat.random(in: 40...80)
            return SplashDroplet(
                id: i,
                offset: CGSize(
                    width: cos(angle) * distance,
                    height: sin(angle) * distance
                ),
                size: CGFloat.random(in: 4...8),
                opacity: 0
            )
        }

        // Animate ring 1
        withAnimation(.easeOut(duration: 0.6)) {
            ringScale = 1.1
            ringOpacity = 0.6
        }
        withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
            ringOpacity = 0
        }

        // Animate ring 2 (delayed)
        withAnimation(.easeOut(duration: 0.6).delay(0.15)) {
            ring2Scale = 1.0
            ring2Opacity = 0.4
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.45)) {
            ring2Opacity = 0
        }

        // Animate droplets
        for i in droplets.indices {
            let delay = Double.random(in: 0...0.15)
            withAnimation(.easeOut(duration: 0.4).delay(delay)) {
                droplets[i].opacity = 0.7
            }
            withAnimation(.easeOut(duration: 0.4).delay(delay + 0.25)) {
                droplets[i].opacity = 0
                droplets[i].offset.height += 20
            }
        }
    }
}

struct SplashDroplet: Identifiable {
    let id: Int
    var offset: CGSize
    var size: CGFloat
    var opacity: Double
}

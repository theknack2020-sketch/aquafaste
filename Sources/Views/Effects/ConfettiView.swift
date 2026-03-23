import SwiftUI

/// Full-screen confetti burst that fires once and auto-dismisses.
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var isAnimating = false

    private let colors: [Color] = [
        .aquaPrimary, .aquaSecondary, .aquaAccent,
        .orange, .yellow, .green, .pink, .mint
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiPiece(particle: particle, isAnimating: isAnimating)
                }
            }
            .onAppear {
                generateParticles(in: geo.size)
                withAnimation(.easeOut(duration: 3.0)) {
                    isAnimating = true
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func generateParticles(in size: CGSize) {
        particles = (0..<60).map { i in
            ConfettiParticle(
                id: i,
                color: colors[i % colors.count],
                startX: size.width * 0.5 + CGFloat.random(in: -40...40),
                startY: size.height * 0.35,
                endX: CGFloat.random(in: -size.width * 0.4...size.width * 1.4),
                endY: size.height + 40,
                rotation: Double.random(in: 0...720),
                scale: CGFloat.random(in: 0.4...1.0),
                delay: Double.random(in: 0...0.4),
                shape: ConfettiShape.allCases[i % ConfettiShape.allCases.count]
            )
        }
    }
}

// MARK: - Particle Data

struct ConfettiParticle: Identifiable {
    let id: Int
    let color: Color
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let rotation: Double
    let scale: CGFloat
    let delay: Double
    let shape: ConfettiShape
}

enum ConfettiShape: CaseIterable {
    case circle, rectangle, triangle
}

// MARK: - Particle View

struct ConfettiPiece: View {
    let particle: ConfettiParticle
    let isAnimating: Bool

    var body: some View {
        confettiShape
            .fill(particle.color)
            .frame(width: 8 * particle.scale, height: 12 * particle.scale)
            .position(
                x: isAnimating ? particle.endX : particle.startX,
                y: isAnimating ? particle.endY : particle.startY
            )
            .rotationEffect(.degrees(isAnimating ? particle.rotation : 0))
            .opacity(isAnimating ? 0 : 1)
            .animation(
                .easeOut(duration: 2.5)
                .delay(particle.delay),
                value: isAnimating
            )
    }

    private var confettiShape: AnyShape {
        switch particle.shape {
        case .circle:
            AnyShape(Circle())
        case .rectangle:
            AnyShape(RoundedRectangle(cornerRadius: 1))
        case .triangle:
            AnyShape(ConfettiTriangle())
        }
    }
}

struct ConfettiTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

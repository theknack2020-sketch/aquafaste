import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    let currentAmount: Double
    let goalAmount: Double
    let unit: MeasurementUnit

    @State private var animatedProgress: Double = 0

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)

            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.aquaPrimary.opacity(0.15), lineWidth: 12)

                // Progress ring
                Circle()
                    .trim(from: 0, to: min(animatedProgress, 1.0))
                    .stroke(
                        AngularGradient(
                            colors: [Color.aquaGradientStart, Color.aquaGradientEnd, Color.aquaGradientStart],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                // Wave fill inside circle
                WaveView(progress: min(animatedProgress, 1.0))
                    .clipShape(Circle().inset(by: 14))

                // Center content
                VStack(spacing: 8) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.aquaPrimary)

                    Text(unit.formatAmount(currentAmount))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.aquaTextPrimary)

                    Text("of \(unit.formatAmount(goalAmount))")
                        .font(.subheadline)
                        .foregroundStyle(Color.aquaTextSecondary)

                    Text("\(Int(min(animatedProgress, 1.0) * 100))%")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.aquaPrimary)
                }
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animatedProgress = newValue
            }
        }
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) {
                animatedProgress = progress
            }
        }
    }
}

// MARK: - Wave Animation

struct WaveView: View {
    let progress: Double

    var body: some View {
        TimelineView(.animation) { timeline in
            let now = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                drawWaves(context: context, size: size, time: now)
            }
        }
    }

    private func drawWaves(context: GraphicsContext, size: CGSize, time: Double) {
        let waterHeight = size.height * (1 - progress)
        let amplitude = 6.0 * (1 - progress * 0.5)
        let frequency = 2.0

        // First wave
        var path1 = Path()
        path1.move(to: CGPoint(x: 0, y: size.height))
        for x in stride(from: 0, through: size.width, by: 2) {
            let relX = x / size.width
            let y = waterHeight + sin((relX * frequency * .pi * 2) + time * 2) * amplitude
            path1.addLine(to: CGPoint(x: x, y: y))
        }
        path1.addLine(to: CGPoint(x: size.width, y: size.height))
        path1.closeSubpath()

        let color1 = Color.aquaGradientStart.opacity(0.3)
        context.fill(path1, with: .color(color1))

        // Second wave
        var path2 = Path()
        path2.move(to: CGPoint(x: 0, y: size.height))
        for x in stride(from: 0, through: size.width, by: 2) {
            let relX = x / size.width
            let y = waterHeight + sin((relX * frequency * .pi * 2) + time * 2.5 + .pi) * amplitude * 0.7
            path2.addLine(to: CGPoint(x: x, y: y))
        }
        path2.addLine(to: CGPoint(x: size.width, y: size.height))
        path2.closeSubpath()

        let color2 = Color.aquaGradientEnd.opacity(0.15)
        context.fill(path2, with: .color(color2))
    }
}

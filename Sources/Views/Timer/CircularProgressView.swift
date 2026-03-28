import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    let currentAmount: Double
    let goalAmount: Double
    let unit: MeasurementUnit
    var showSplash: Binding<Bool>?

    @State private var animatedProgress: Double = 0
    @State private var splashTrigger = false
    @State private var glowPulse = false

    private var percentageComplete: Int {
        Int(min(animatedProgress, 1.0) * 100)
    }

    private var accessibilityProgressLabel: String {
        let current = unit.formatAmount(currentAmount)
        let goal = unit.formatAmount(goalAmount)
        let pct = Int(min(progress, 1.0) * 100)
        if progress >= 1.0 {
            return "Hydration goal complete. \(current) of \(goal), \(pct) percent"
        } else {
            return "Hydration progress: \(current) of \(goal), \(pct) percent"
        }
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)

            ZStack {
                // Outer glow ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.aquaGradientStart.opacity(0.25), Color.aquaGradientEnd.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 20
                    )
                    .blur(radius: 8)
                    .opacity(glowPulse ? 0.6 : 0.3)

                // Background ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.aquaPrimary.opacity(0.12), Color.aquaGradientEnd.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 14
                    )

                // Progress ring with spring animation and glow
                Circle()
                    .trim(from: 0, to: min(animatedProgress, 1.0))
                    .stroke(
                        AngularGradient(
                            colors: [Color.aquaGradientStart, Color.aquaGradientEnd, Color.aquaGradientStart],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Color.aquaGradientStart.opacity(0.5), radius: 8, x: 0, y: 0)
                    .shadow(color: Color.aquaGradientEnd.opacity(0.3), radius: 16, x: 0, y: 4)

                // Glowing dot at progress tip
                if animatedProgress > 0.02 {
                    Circle()
                        .fill(Color.aquaGradientEnd)
                        .frame(width: 18, height: 18)
                        .shadow(color: Color.aquaGradientEnd.opacity(0.8), radius: 10)
                        .shadow(color: Color.aquaGradientStart.opacity(0.4), radius: 20)
                        .offset(y: -(size - 28) / 2)
                        .rotationEffect(.degrees(min(animatedProgress, 1.0) * 360 - 90))
                }

                // Wave fill inside circle with inner glow
                ZStack {
                    WaveView(progress: min(animatedProgress, 1.0))

                    // Inner glow at water surface
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.aquaGradientStart.opacity(0.15), .clear],
                                center: .center,
                                startRadius: size * 0.1,
                                endRadius: size * 0.45
                            )
                        )
                }
                .clipShape(Circle().inset(by: 14))

                // Center content
                VStack(spacing: 8) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.aquaPrimary)
                        .symbolEffect(.bounce, value: splashTrigger)
                        .accessibilityHidden(true)

                    AnimatedNumberView(
                        value: currentAmount,
                        unit: unit,
                        font: .system(size: 36, weight: .bold, design: .rounded),
                        color: Color.aquaTextPrimary
                    )
                    .accessibilityHidden(true)

                    Text("of \(unit.formatAmount(goalAmount))")
                        .font(.subheadline)
                        .foregroundStyle(Color.aquaTextSecondary)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                        .accessibilityHidden(true)

                    Text("\(percentageComplete)%")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.aquaPrimary)
                        .contentTransition(.numericText())
                        .animation(.snappy, value: percentageComplete)
                        .accessibilityHidden(true)
                }

                // Splash effect overlay
                SplashEffectView(trigger: $splashTrigger)
                    .frame(width: size, height: size)
                    .accessibilityHidden(true)
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityProgressLabel)
        .accessibilityValue("\(percentageComplete) percent")
        .accessibilityAddTraits(.updatesFrequently)
        .accessibilityIdentifier("progressRingView")
        .onChange(of: progress) { oldValue, newValue in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.65, blendDuration: 0.3)) {
                animatedProgress = newValue
            }
            // Trigger splash on increase
            if newValue > oldValue {
                splashTrigger = true
            }
        }
        .onChange(of: showSplash?.wrappedValue) { _, newValue in
            if newValue == true {
                splashTrigger = true
                showSplash?.wrappedValue = false
            }
        }
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) {
                animatedProgress = progress
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowPulse = true
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
        .accessibilityHidden(true)
    }

    private func drawWaves(context: GraphicsContext, size: CGSize, time: Double) {
        let waterHeight = size.height * (1 - progress)
        let amplitude = 6.0 * (1 - progress * 0.5)
        let frequency = 2.0

        // First wave — animated gradient fill
        var path1 = Path()
        path1.move(to: CGPoint(x: 0, y: size.height))
        for x in stride(from: 0, through: size.width, by: 2) {
            let relX = x / size.width
            let y = waterHeight + sin((relX * frequency * .pi * 2) + time * 2) * amplitude
            path1.addLine(to: CGPoint(x: x, y: y))
        }
        path1.addLine(to: CGPoint(x: size.width, y: size.height))
        path1.closeSubpath()

        // Subtle animated gradient inside the wave
        let gradientStart = CGPoint(
            x: size.width * (0.3 + 0.2 * sin(time * 0.5)),
            y: waterHeight
        )
        let gradientEnd = CGPoint(
            x: size.width * (0.7 + 0.2 * cos(time * 0.5)),
            y: size.height
        )
        context.fill(
            path1,
            with: .linearGradient(
                Gradient(colors: [
                    Color.aquaGradientStart.opacity(0.35),
                    Color.aquaGradientEnd.opacity(0.2)
                ]),
                startPoint: gradientStart,
                endPoint: gradientEnd
            )
        )

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

        context.fill(
            path2,
            with: .linearGradient(
                Gradient(colors: [
                    Color.aquaGradientEnd.opacity(0.15),
                    Color.aquaPrimary.opacity(0.1)
                ]),
                startPoint: CGPoint(x: 0, y: waterHeight),
                endPoint: CGPoint(x: size.width, y: size.height)
            )
        )

        // Third shimmer wave — extra subtle
        var path3 = Path()
        path3.move(to: CGPoint(x: 0, y: size.height))
        for x in stride(from: 0, through: size.width, by: 2) {
            let relX = x / size.width
            let y = waterHeight + sin((relX * 3 * .pi * 2) + time * 1.5 + .pi * 0.5) * amplitude * 0.3
            path3.addLine(to: CGPoint(x: x, y: y))
        }
        path3.addLine(to: CGPoint(x: size.width, y: size.height))
        path3.closeSubpath()

        context.fill(path3, with: .color(Color.white.opacity(0.07)))

        // Bubble/sparkle effect — small circles that float upward
        let bubbleCount = 5
        for i in 0..<bubbleCount {
            let phase = Double(i) / Double(bubbleCount)
            let bubbleX = size.width * (0.15 + 0.7 * frac(phase + time * 0.08))
            let cyclePos = frac(phase * 2.3 + time * 0.15)
            let bubbleY = size.height - (size.height * progress * cyclePos)
            let bubbleRadius = 2.0 + sin(time + Double(i)) * 1.5
            let bubbleOpacity = 0.15 * (1.0 - cyclePos)
            if bubbleY > waterHeight {
                let bubble = Path(ellipseIn: CGRect(
                    x: bubbleX - bubbleRadius,
                    y: bubbleY - bubbleRadius,
                    width: bubbleRadius * 2,
                    height: bubbleRadius * 2
                ))
                context.fill(bubble, with: .color(Color.white.opacity(bubbleOpacity)))
            }
        }
    }

    private func frac(_ x: Double) -> Double {
        x - floor(x)
    }
}

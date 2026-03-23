import SwiftUI

/// Smoothly animates a number counting up/down using a `TimelineView`.
/// Uses DisplayLink-style animation for fluid number transitions.
struct AnimatedNumberView: View {
    let value: Double
    let unit: MeasurementUnit
    let font: Font
    let color: Color

    @State private var displayedValue: Double = 0
    @State private var animationStartValue: Double = 0
    @State private var animationTargetValue: Double = 0
    @State private var animationStartTime: Date = .now
    @State private var isAnimating = false

    private let animationDuration: Double = 0.8

    var body: some View {
        Group {
            if isAnimating {
                TimelineView(.animation) { timeline in
                    let elapsed = timeline.date.timeIntervalSince(animationStartTime)
                    let progress = min(elapsed / animationDuration, 1.0)
                    // Ease-out cubic for natural deceleration
                    let eased = 1 - pow(1 - progress, 3)
                    let current = animationStartValue + (animationTargetValue - animationStartValue) * eased

                    Text(unit.formatAmount(current))
                        .font(font)
                        .foregroundStyle(color)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .onChange(of: progress >= 1.0) { _, done in
                            if done {
                                displayedValue = animationTargetValue
                                isAnimating = false
                            }
                        }
                }
            } else {
                Text(unit.formatAmount(displayedValue))
                    .font(font)
                    .foregroundStyle(color)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
        }
        .onChange(of: value) { oldVal, newVal in
            startAnimation(from: displayedValue, to: newVal)
        }
        .onAppear {
            if displayedValue == 0 && value > 0 {
                startAnimation(from: 0, to: value)
            } else {
                displayedValue = value
            }
        }
    }

    private func startAnimation(from: Double, to: Double) {
        animationStartValue = from
        animationTargetValue = to
        animationStartTime = .now
        isAnimating = true
    }
}

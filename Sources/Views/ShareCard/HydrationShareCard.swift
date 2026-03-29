import SwiftUI

// MARK: - Hydration Share Card

struct HydrationShareCard: View {
    let todayTotal: Double
    let dailyGoal: Double
    let streak: Int
    let drinkCount: Int
    let unit: MeasurementUnit

    private var progress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(1.0, todayTotal / dailyGoal)
    }

    private var percentage: Int {
        Int(progress * 100)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "drop.fill")
                    .font(.title3)
                    .foregroundStyle(.cyan)
                Text("AquaFaste")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
                if streak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                        Text("\(streak) day streak")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.orange.opacity(0.15), in: Capsule())
                }
            }

            // Big progress ring
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.1), lineWidth: 12)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text("\(percentage)%")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("hydrated")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .frame(width: 160, height: 160)

            // Stats
            HStack(spacing: 0) {
                statCell(value: unit.formatAmount(todayTotal), label: "Total")
                Capsule().fill(.white.opacity(0.15)).frame(width: 1, height: 30)
                statCell(value: "\(drinkCount)", label: "Drinks")
                Capsule().fill(.white.opacity(0.15)).frame(width: 1, height: 30)
                statCell(value: unit.formatAmount(dailyGoal), label: "Goal")
            }

            if progress >= 1.0 {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Daily Goal Reached!")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.green)
            }
        }
        .padding(28)
        .frame(width: 340)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.05, green: 0.12, blue: 0.30),
                                Color(red: 0.08, green: 0.20, blue: 0.45)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Glow
                Circle()
                    .fill(RadialGradient(colors: [.cyan.opacity(0.15), .clear], center: .center, startRadius: 10, endRadius: 100))
                    .frame(width: 200, height: 200)
                    .offset(x: -60, y: -80)
                    .blur(radius: 30)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Share Card Renderer

@MainActor
enum ShareCardRenderer {
    static func render(
        todayTotal: Double,
        dailyGoal: Double,
        streak: Int,
        drinkCount: Int,
        unit: MeasurementUnit
    ) -> UIImage? {
        let card = HydrationShareCard(
            todayTotal: todayTotal,
            dailyGoal: dailyGoal,
            streak: streak,
            drinkCount: drinkCount,
            unit: unit
        )

        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0
        return renderer.uiImage
    }
}

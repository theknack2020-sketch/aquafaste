import SwiftUI

struct WeeklyRecapView: View {
    let totalWater: Double
    let avgDaily: Double
    let bestDay: Double
    let goalHitDays: Int
    let streak: Int
    let totalDrinks: Int
    let unit: MeasurementUnit

    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom)
                        )
                        .shadow(color: .cyan.opacity(0.4), radius: 12, y: 4)
                        .scaleEffect(appeared ? 1 : 0.3)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6), value: appeared)

                    Text("Weekly Recap")
                        .font(.system(size: 28, weight: .bold, design: .rounded))

                    Text("Here's how you did this week")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)

                // Big stat card
                VStack(spacing: 6) {
                    Text(unit.formatAmount(totalWater))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing)
                        )
                        .contentTransition(.numericText())

                    Text("total water this week")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(.white.opacity(0.08), lineWidth: 0.5))
                .shadow(color: .cyan.opacity(0.1), radius: 16, y: 8)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 30)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appeared)

                // Stats grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    recapStat(icon: "chart.line.uptrend.xyaxis", value: unit.formatAmount(avgDaily), label: "Daily Average", color: .blue, delay: 0.15)
                    recapStat(icon: "trophy.fill", value: unit.formatAmount(bestDay), label: "Best Day", color: .yellow, delay: 0.2)
                    recapStat(icon: "target", value: "\(goalHitDays)/7", label: "Goals Hit", color: .green, delay: 0.25)
                    recapStat(icon: "flame.fill", value: "\(streak) days", label: "Current Streak", color: .orange, delay: 0.3)
                    recapStat(icon: "drop.fill", value: "\(totalDrinks)", label: "Total Drinks", color: .cyan, delay: 0.35)
                    recapStat(icon: "clock.fill", value: avgDrinksPerDay, label: "Drinks/Day", color: .purple, delay: 0.4)
                }

                // Motivational message
                VStack(spacing: 8) {
                    Text(motivationalMessage)
                        .font(.body.weight(.medium))
                        .multilineTextAlignment(.center)
                    Text(motivationalEmoji)
                        .font(.system(size: 32))
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5), value: appeared)
            }
            .padding()
        }
        .onAppear { appeared = true }
    }

    private func recapStat(icon: String, value: String, label: String, color: Color, delay: Double) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .shadow(color: color.opacity(0.3), radius: 6, y: 2)

            Text(value)
                .font(.title3.bold().monospacedDigit())

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.06), lineWidth: 0.5))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay), value: appeared)
    }

    private var avgDrinksPerDay: String {
        let avg = totalDrinks > 0 ? Double(totalDrinks) / 7.0 : 0
        return String(format: "%.1f", avg)
    }

    private var motivationalMessage: String {
        switch goalHitDays {
        case 7: "Perfect week! You crushed every single day."
        case 5...6: "Almost perfect! Keep pushing for that 7/7."
        case 3...4: "Good effort! Try to hit your goal more consistently."
        case 1...2: "Room to grow. Small improvements lead to big results."
        default: "Every drop counts. Let's make next week better!"
        }
    }

    private var motivationalEmoji: String {
        switch goalHitDays {
        case 7: "🏆"
        case 5...6: "💪"
        case 3...4: "👍"
        default: "💧"
        }
    }
}

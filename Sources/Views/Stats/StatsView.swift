import Charts
import SwiftUI

struct StatsView: View {
    @Environment(HydrationManager.self) private var manager
    private let profile = UserProfile.shared
    private let subscription = SubscriptionManager.shared
    private let insights = InsightsEngine()

    private let haptics = HapticManager.shared
    private let sounds = SoundManager.shared

    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Group {
                if manager.allLogs().count < 3 {
                    emptyState
                } else {
                    statsContent
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
            .background(Color.aquaBackground)
            .aquaBackgroundGradient()
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundStyle(Color.aquaPrimary)
                .symbolEffect(.pulse)

            Text("Not Enough Data Yet")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.aquaTextPrimary)

            Text("Track for 3+ days to see your patterns. The more you log, the smarter your insights.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Not enough data yet. Track for three or more days to see your patterns.")
    }

    // MARK: - Stats Content

    private var statsContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                hydrationScoreCard
                summaryCards

                // This Week
                let weekData = insights.weeklyBarData(from: manager.allLogs())
                WeeklyBarChart(data: weekData)
                weekComparisonBanner(weekData: weekData)

                // Monthly Heatmap
                let heatmapData = insights.monthlyHeatmapData(from: manager.allLogs())
                MonthlyHeatmapGrid(data: heatmapData)

                // Drink Breakdown
                let breakdown = insights.drinkTypeBreakdown(from: manager.allLogs())
                DrinkTypeDonutChart(data: breakdown)

                // Time Patterns — PRO ONLY
                if subscription.isPro {
                    let todData = insights.timeOfDayDistribution(from: manager.allLogs())
                    TimeOfDayAreaChart(data: todData)
                } else {
                    proLockedSection(
                        title: "Time Patterns",
                        icon: "clock.fill",
                        description: "See when you drink most throughout the day"
                    )
                }

                // Caffeine Trends — PRO ONLY
                if subscription.isPro {
                    let cafData = insights.caffeineWeeklyTrend(from: manager.allLogs())
                    CaffeineLineChart(data: cafData)
                } else {
                    proLockedSection(
                        title: "Caffeine Trends",
                        icon: "bolt.fill",
                        description: "Track your caffeine intake with a safe limit line"
                    )
                }

                // Personal Insights
                insightsSection
            }
            .padding()
        }
    }

    // MARK: - Hydration Score Card

    private var hydrationScoreCard: some View {
        let score = insights.hydrationScore(from: manager.allLogs())
        let scoreColor = scoreGradientColor(score)

        return VStack(spacing: 16) {
            Text("HYDRATION SCORE")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(Color.aquaTextSecondary)

            ZStack {
                // Background track
                Circle()
                    .stroke(Color.aquaPrimary.opacity(0.10), lineWidth: 12)
                    .frame(width: 130, height: 130)

                // Progress arc
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100.0)
                    .stroke(
                        AngularGradient(
                            colors: [scoreColor.opacity(0.6), scoreColor],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 130, height: 130)
                    .rotationEffect(.degrees(-90))

                // Score number
                VStack(spacing: 2) {
                    Text("\(score)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(scoreColor)
                        .contentTransition(.numericText())

                    Text("out of 100")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.aquaTextSecondary)
                }
            }

            Text(scoreLabel(score))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(scoreColor)
        }
        .frame(maxWidth: .infinity)
        .aquaCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Hydration score \(score) out of 100, \(scoreLabel(score))")
        .accessibilityIdentifier("hydrationScoreCard")
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        let currentStreak = manager.computeCurrentStreak()
        let bestStreak = manager.computeBestStreak()
        let avgDaily = manager.averageDailyIntake()
        let achievementRate = manager.goalAchievementRate()
        let allTimeTotal = manager.allTimeTotalMl()

        return VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    icon: "flame.fill",
                    iconColor: .orange,
                    title: "Current Streak",
                    value: "\(currentStreak)",
                    unit: currentStreak == 1 ? "day" : "days"
                )
                StatCard(
                    icon: "trophy.fill",
                    iconColor: .yellow,
                    title: "Best Streak",
                    value: "\(bestStreak)",
                    unit: bestStreak == 1 ? "day" : "days"
                )
            }

            HStack(spacing: 12) {
                StatCard(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: Color.aquaPrimary,
                    title: "Daily Average",
                    value: profile.unit.formatAmount(avgDaily),
                    unit: ""
                )
                StatCard(
                    icon: "checkmark.seal.fill",
                    iconColor: .green,
                    title: "Goal Rate",
                    value: "\(Int(achievementRate))%",
                    unit: "of days"
                )
            }

            StatCardWide(
                icon: "drop.fill",
                iconColor: Color.aquaSecondary,
                title: "Total Water Logged",
                value: formatLargeVolume(allTimeTotal),
                subtitle: "All time"
            )
        }
    }

    // MARK: - Week-over-Week Comparison

    private func weekComparisonBanner(weekData _: [(day: String, amount: Double, goal: Double)]) -> some View {
        let comparison = manager.weeklyComparison()
        let diff = comparison.lastWeek > 0
            ? (comparison.thisWeek - comparison.lastWeek) / comparison.lastWeek * 100
            : 0
        let isUp = diff >= 0

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("vs Last Week")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(profile.unit.formatAmount(comparison.thisWeek))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.aquaPrimary)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption.weight(.bold))
                Text("\(abs(Int(diff)))%")
                    .font(.subheadline.weight(.bold))
            }
            .foregroundStyle(isUp ? .green : .orange)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Last Week")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(profile.unit.formatAmount(comparison.lastWeek))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.aquaTextSecondary)
            }
        }
        .aquaCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Week comparison: this week \(profile.unit.formatAmount(comparison.thisWeek)), last week \(profile.unit.formatAmount(comparison.lastWeek)), \(isUp ? "up" : "down") \(abs(Int(diff))) percent")
    }

    // MARK: - Insights Section

    private var insightsSection: some View {
        let items = insights.personalizedInsights(from: manager.allLogs())

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [Color.aquaGradientStart, Color.aquaGradientEnd],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 3, height: 18)
                Image(systemName: "lightbulb.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.aquaPrimary)
                Text("Personal Insights")
                    .font(.headline)
            }
            .accessibilityAddTraits(.isHeader)

            ForEach(items) { item in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: item.icon)
                        .font(.title3)
                        .foregroundStyle(Color.aquaPrimary)
                        .frame(width: 28, height: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(item.value)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.aquaTextPrimary)
                        Text(item.subtitle)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()
                }
                .padding(.vertical, 4)

                if item.id != items.last?.id {
                    Divider()
                }
            }
        }
        .aquaCard()
    }

    // MARK: - Pro Locked Section

    private func proLockedSection(title: String, icon: String, description: String) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [Color.aquaGradientStart, Color.aquaGradientEnd],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 3, height: 18)
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(Color.aquaPrimary)
                Text(title)
                    .font(.headline)
                Spacer()
                Text("PRO")
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange, in: Capsule())
                    .foregroundStyle(.white)
            }

            VStack(spacing: 10) {
                Image(systemName: "lock.fill")
                    .font(.title2)
                    .foregroundStyle(Color(.tertiaryLabel))

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    showPaywall = true
                } label: {
                    Text("Unlock with Pro")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.aquaGradient, in: Capsule())
                        .foregroundStyle(.white)
                }
                .accessibilityLabel("Unlock \(title) with Pro subscription")
                .accessibilityIdentifier("statsUnlockProButton")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
        .aquaCard()
    }

    // MARK: - Helpers

    private func scoreGradientColor(_ score: Int) -> Color {
        switch score {
        case 0 ..< 30: .red
        case 30 ..< 50: .orange
        case 50 ..< 70: .yellow
        case 70 ..< 85: Color.aquaPrimary
        default: .green
        }
    }

    private func scoreLabel(_ score: Int) -> String {
        switch score {
        case 0 ..< 30: "Needs Improvement"
        case 30 ..< 50: "Getting There"
        case 50 ..< 70: "Good"
        case 70 ..< 85: "Great"
        default: "Excellent"
        }
    }

    private func formatLargeVolume(_ ml: Double) -> String {
        if profile.unit == .ml {
            if ml >= 1_000_000 {
                return String(format: "%.1fk L", ml / 1_000_000)
            } else if ml >= 1000 {
                return String(format: "%.1f L", ml / 1000)
            }
            return "\(Int(ml)) ml"
        } else {
            let oz = profile.unit.fromMl(ml)
            if oz >= 1000 {
                return String(format: "%.1fk oz", oz / 1000)
            }
            return String(format: "%.0f fl oz", oz)
        }
    }
}

// MARK: - Reusable Components

private struct StatCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)

            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.aquaTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if !unit.isEmpty {
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.aquaCardBackground, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: iconColor.opacity(0.12), radius: 8, x: 0, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value) \(unit)")
    }
}

private struct StatCardWide: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.aquaTextPrimary)
            }

            Spacer()

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color.aquaCardBackground, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: iconColor.opacity(0.12), radius: 8, x: 0, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value), \(subtitle)")
    }
}

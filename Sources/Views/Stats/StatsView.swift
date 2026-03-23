import SwiftUI
import Charts

struct StatsView: View {
    @Environment(HydrationManager.self) private var manager
    private let profile = UserProfile.shared

    @State private var calendarMonth = Date.now

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    summaryCards
                    weeklyChartSection
                    weeklyComparisonSection
                    calendarHeatmapSection
                    timeOfDaySection
                    drinkBreakdownSection
                    insightsSection
                }
                .padding()
            }
            .navigationTitle("Statistics")
            .background(Color.aquaBackground)
        }
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        let currentStreak = manager.computeCurrentStreak()
        let bestStreak = manager.computeBestStreak()
        let avgDaily = manager.averageDailyIntake()
        let allTimeTotal = manager.allTimeTotalMl()
        let achievementRate = manager.goalAchievementRate()

        return VStack(spacing: 12) {
            // Top row: streaks
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

            // Middle row: averages
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

            // All-time total
            StatCardWide(
                icon: "drop.fill",
                iconColor: Color.aquaSecondary,
                title: "Total Water Logged",
                value: formatLargeVolume(allTimeTotal),
                subtitle: "All time"
            )
        }
    }

    // MARK: - Weekly Chart

    private var weeklyChartSection: some View {
        let weekData = manager.weeklyData()

        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "This Week", icon: "chart.bar.fill")

            Chart(weekData, id: \.date) { item in
                BarMark(
                    x: .value("Day", item.date, unit: .day),
                    y: .value("ml", item.total)
                )
                .foregroundStyle(
                    item.total >= profile.dailyGoal
                        ? Color.aquaPrimary
                        : Color.aquaPrimary.opacity(0.35)
                )
                .cornerRadius(6)

                // Goal line
                RuleMark(y: .value("Goal", profile.dailyGoal))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    .foregroundStyle(Color.aquaTextSecondary.opacity(0.5))
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    if let ml = value.as(Double.self) {
                        AxisValueLabel {
                            Text(profile.unit.formatAmount(ml))
                                .font(.caption2)
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.gray.opacity(0.2))
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(date, format: .dateTime.weekday(.abbreviated))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYScale(domain: 0...(max(profile.dailyGoal * 1.3, weekData.map(\.total).max() ?? 0) * 1.1))
            .frame(height: 200)

            // Legend
            HStack(spacing: 16) {
                LegendDot(color: Color.aquaPrimary, label: "Goal met")
                LegendDot(color: Color.aquaPrimary.opacity(0.35), label: "Under goal")
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.aquaTextSecondary.opacity(0.5))
                        .frame(width: 16, height: 1)
                    Text("Goal")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color.aquaCardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Weekly Comparison

    private var weeklyComparisonSection: some View {
        let comparison = manager.weeklyComparison()
        let diff = comparison.lastWeek > 0
            ? (comparison.thisWeek - comparison.lastWeek) / comparison.lastWeek * 100
            : 0
        let isUp = diff >= 0

        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Weekly Comparison", icon: "arrow.left.arrow.right")

            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("This Week")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(profile.unit.formatAmount(comparison.thisWeek))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.aquaPrimary)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 4) {
                    Text("vs")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    HStack(spacing: 2) {
                        Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption.weight(.bold))
                        Text("\(abs(Int(diff)))%")
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundStyle(isUp ? .green : .orange)
                }

                VStack(spacing: 4) {
                    Text("Last Week")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(profile.unit.formatAmount(comparison.lastWeek))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.aquaTextSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color.aquaCardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Calendar Heatmap

    private var calendarHeatmapSection: some View {
        let calData = manager.monthlyCalendarData(for: calendarMonth)
        let calendar = Calendar.current
        let monthName = calendarMonth.formatted(.dateTime.month(.wide).year())

        // Calculate grid layout
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: calendarMonth))!
        let firstWeekday = (calendar.component(.weekday, from: firstDay) + 5) % 7 // Mon=0

        return VStack(alignment: .leading, spacing: 12) {
            // Month navigation
            HStack {
                Button {
                    calendarMonth = calendar.date(byAdding: .month, value: -1, to: calendarMonth)!
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.aquaPrimary)
                }

                Spacer()

                Text(monthName)
                    .font(.headline)

                Spacer()

                Button {
                    let next = calendar.date(byAdding: .month, value: 1, to: calendarMonth)!
                    if next <= .now {
                        calendarMonth = next
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.aquaPrimary)
                }
            }

            // Day headers
            let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]
            HStack(spacing: 0) {
                ForEach(dayLabels.indices, id: \.self) { i in
                    Text(dayLabels[i])
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
            LazyVGrid(columns: columns, spacing: 4) {
                // Empty cells for offset
                ForEach(0..<firstWeekday, id: \.self) { _ in
                    Color.clear.frame(height: 36)
                }

                // Day cells
                ForEach(calData, id: \.date) { day in
                    let dayNum = calendar.component(.day, from: day.date)
                    let isFuture = day.date > calendar.startOfDay(for: .now)

                    VStack(spacing: 1) {
                        Text("\(dayNum)")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(isFuture ? .tertiary : .primary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(
                        isFuture
                            ? Color.clear
                            : heatmapColor(ratio: day.ratio),
                        in: RoundedRectangle(cornerRadius: 6)
                    )
                }
            }

            // Legend
            HStack(spacing: 4) {
                Text("0%")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { ratio in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(heatmapColor(ratio: ratio))
                        .frame(width: 16, height: 12)
                }
                Text("100%+")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .background(Color.aquaCardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Time of Day

    private var timeOfDaySection: some View {
        let todData = manager.timeOfDayData()
        let maxVal = todData.map(\.total).max() ?? 1

        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "When You Drink", icon: "clock.fill")

            Chart(todData, id: \.hour) { item in
                AreaMark(
                    x: .value("Hour", item.hour),
                    y: .value("Total", item.total)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.aquaGradientStart.opacity(0.4), Color.aquaGradientEnd.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("Hour", item.hour),
                    y: .value("Total", item.total)
                )
                .foregroundStyle(Color.aquaPrimary)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
            .chartXAxis {
                AxisMarks(values: [0, 6, 12, 18, 23]) { value in
                    if let hour = value.as(Int.self) {
                        AxisValueLabel {
                            Text(hourLabel(hour))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    if let ml = value.as(Double.self) {
                        AxisValueLabel {
                            Text(profile.unit.formatAmount(ml))
                                .font(.caption2)
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.gray.opacity(0.2))
                    }
                }
            }
            .chartYScale(domain: 0...(maxVal * 1.15))
            .frame(height: 180)

            // Peak hour callout
            if let peak = todData.max(by: { $0.total < $1.total }), peak.total > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                    Text("Peak: \(hourLabel(peak.hour))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color.aquaCardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Drink Breakdown

    private var drinkBreakdownSection: some View {
        let breakdown = manager.drinkTypeBreakdown()
        let total = breakdown.reduce(0.0) { $0 + $1.total }

        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Drink Breakdown", icon: "chart.pie.fill")

            if breakdown.isEmpty {
                Text("No data yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                // Donut chart
                Chart(breakdown, id: \.type) { item in
                    SectorMark(
                        angle: .value("Amount", item.total),
                        innerRadius: .ratio(0.55),
                        angularInset: 1.5
                    )
                    .foregroundStyle(item.type.color)
                    .cornerRadius(3)
                }
                .frame(height: 180)

                // Breakdown list
                VStack(spacing: 8) {
                    ForEach(breakdown.prefix(6), id: \.type) { item in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(item.type.color)
                                .frame(width: 10, height: 10)

                            Image(systemName: item.type.iconName)
                                .font(.caption)
                                .foregroundStyle(item.type.color)
                                .frame(width: 20)

                            Text(item.type.displayName)
                                .font(.subheadline)

                            Spacer()

                            Text(profile.unit.formatAmount(item.total))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)

                            Text("\(total > 0 ? Int(item.total / total * 100) : 0)%")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.aquaPrimary)
                                .frame(width: 36, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.aquaCardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Insights

    private var insightsSection: some View {
        let insights = manager.generateInsights()

        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Insights", icon: "lightbulb.fill")

            ForEach(insights.indices, id: \.self) { i in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: insightIcon(for: i))
                        .font(.body)
                        .foregroundStyle(insightColor(for: i))
                        .frame(width: 24)

                    Text(insights[i])
                        .font(.subheadline)
                        .foregroundStyle(Color.aquaTextPrimary)
                }
                .padding(.vertical, 4)

                if i < insights.count - 1 {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color.aquaCardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    private func heatmapColor(ratio: Double) -> Color {
        if ratio <= 0 { return Color.gray.opacity(0.1) }
        if ratio < 0.25 { return Color.aquaPrimary.opacity(0.15) }
        if ratio < 0.50 { return Color.aquaPrimary.opacity(0.30) }
        if ratio < 0.75 { return Color.aquaPrimary.opacity(0.50) }
        if ratio < 1.0 { return Color.aquaPrimary.opacity(0.70) }
        return Color.aquaPrimary // 100%+
    }

    private func hourLabel(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let cal = Calendar.current
        let date = cal.date(bySettingHour: hour, minute: 0, second: 0, of: .now) ?? .now
        return formatter.string(from: date).lowercased()
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

    private func insightIcon(for index: Int) -> String {
        let icons = ["calendar", "clock.fill", "drop.fill", "target", "sparkles"]
        return icons[index % icons.count]
    }

    private func insightColor(for index: Int) -> Color {
        let colors: [Color] = [.blue, .orange, .cyan, .green, .purple]
        return colors[index % colors.count]
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
    }
}

private struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Color.aquaPrimary)
            Text(title)
                .font(.headline)
        }
    }
}

private struct LegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

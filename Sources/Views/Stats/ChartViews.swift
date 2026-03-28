import Charts
import SwiftUI

// MARK: - Weekly Bar Chart

struct WeeklyBarChart: View {
    let data: [(day: String, amount: Double, goal: Double)]
    private let profile = UserProfile.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ChartSectionHeader(title: "This Week", icon: "chart.bar.fill")

            Chart {
                ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                    BarMark(
                        x: .value("Day", item.day),
                        y: .value("Amount", item.amount)
                    )
                    .foregroundStyle(
                        item.amount >= item.goal
                            ? Color.aquaPrimary
                            : Color.aquaPrimary.opacity(0.35)
                    )
                    .cornerRadius(6)
                }

                if let goal = data.first?.goal, goal > 0 {
                    RuleMark(y: .value("Goal", goal))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                        .foregroundStyle(Color.aquaTextSecondary.opacity(0.5))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("Goal")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(Color.aquaTextSecondary)
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
                            .foregroundStyle(Color.gray.opacity(0.15))
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let day = value.as(String.self) {
                            Text(day)
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYScale(domain: 0...chartYMax)
            .frame(height: 200)

            // Legend
            HStack(spacing: 16) {
                ChartLegendDot(color: Color.aquaPrimary, label: "Goal met")
                ChartLegendDot(color: Color.aquaPrimary.opacity(0.35), label: "Under goal")
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.aquaTextSecondary.opacity(0.5))
                        .frame(width: 16, height: 1)
                    Text("Goal")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .aquaCard()
    }

    private var chartYMax: Double {
        let maxAmount = data.map(\.amount).max() ?? 0
        let goal = data.first?.goal ?? 0
        return max(goal * 1.3, maxAmount * 1.15)
    }
}

// MARK: - Monthly Heatmap Grid

struct MonthlyHeatmapGrid: View {
    let data: [(date: Date, percentage: Double)]
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ChartSectionHeader(title: "Last 30 Days", icon: "calendar")

            // Day header row
            HStack(spacing: 0) {
                ForEach(dayLabels.indices, id: \.self) { i in
                    Text(dayLabels[i])
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 6) {
                // Leading padding for grid alignment
                ForEach(0..<leadingPadding, id: \.self) { _ in
                    Color.clear
                        .frame(height: 28)
                }

                ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                    let isFuture = item.date > calendar.startOfDay(for: .now)

                    Circle()
                        .fill(isFuture ? Color.gray.opacity(0.08) : heatmapColor(for: item.percentage))
                        .frame(height: 28)
                        .overlay {
                            if !isFuture {
                                Text("\(calendar.component(.day, from: item.date))")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(
                                        item.percentage >= 0.75 ? .white : Color.aquaTextPrimary
                                    )
                            }
                        }
                }
            }

            // Legend
            HStack(spacing: 6) {
                Text("0%")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { pct in
                    Circle()
                        .fill(heatmapColor(for: pct))
                        .frame(width: 14, height: 14)
                }
                Text("100%+")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .aquaCard()
    }

    private var leadingPadding: Int {
        guard let firstDate = data.first?.date else { return 0 }
        let weekday = calendar.component(.weekday, from: firstDate)
        return (weekday + 5) % 7 // Mon=0
    }

    private func heatmapColor(for percentage: Double) -> Color {
        if percentage <= 0 { return Color.red.opacity(0.15) }
        if percentage < 0.25 { return Color.red.opacity(0.35) }
        if percentage < 0.50 { return Color.orange.opacity(0.45) }
        if percentage < 0.75 { return Color.yellow.opacity(0.55) }
        if percentage < 1.0 { return Color.green.opacity(0.55) }
        return Color.green.opacity(0.80) // 100%+
    }
}

// MARK: - Drink Type Donut Chart

struct DrinkTypeDonutChart: View {
    let data: [(type: DrinkType, amount: Double, percentage: Double)]
    private let profile = UserProfile.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ChartSectionHeader(title: "Drink Breakdown", icon: "chart.pie.fill")

            if data.isEmpty {
                Text("No data yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                Chart(Array(data.enumerated()), id: \.offset) { _, item in
                    SectorMark(
                        angle: .value("Amount", item.amount),
                        innerRadius: .ratio(0.55),
                        angularInset: 1.5
                    )
                    .foregroundStyle(item.type.color)
                    .cornerRadius(4)
                }
                .frame(height: 200)

                // Legend list
                VStack(spacing: 8) {
                    ForEach(Array(data.prefix(6).enumerated()), id: \.offset) { _, item in
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

                            Text(profile.unit.formatAmount(item.amount))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)

                            Text("\(Int(item.percentage))%")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.aquaPrimary)
                                .frame(width: 36, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .aquaCard()
    }
}

// MARK: - Time of Day Area Chart

struct TimeOfDayAreaChart: View {
    let data: [(hour: Int, amount: Double)]
    private let profile = UserProfile.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ChartSectionHeader(title: "When You Drink", icon: "clock.fill")

            Chart {
                ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                    AreaMark(
                        x: .value("Hour", item.hour),
                        y: .value("Amount", item.amount)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.aquaGradientStart.opacity(0.4),
                                Color.aquaGradientEnd.opacity(0.08),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Hour", item.hour),
                        y: .value("Amount", item.amount)
                    )
                    .foregroundStyle(Color.aquaPrimary)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
            }
            .chartXAxis {
                AxisMarks(values: [0, 6, 12, 18, 23]) { value in
                    if let hour = value.as(Int.self) {
                        AxisValueLabel {
                            Text(Self.hourLabel(hour))
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
                            .foregroundStyle(Color.gray.opacity(0.15))
                    }
                }
            }
            .chartYScale(domain: 0...(chartYMax * 1.15))
            .frame(height: 180)

            // Peak hour callout
            if let peak = data.max(by: { $0.amount < $1.amount }), peak.amount > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                    Text("Peak: \(Self.hourLabel(peak.hour))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .aquaCard()
    }

    private var chartYMax: Double {
        data.map(\.amount).max() ?? 1
    }

    static func hourLabel(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let date = Calendar.current.date(
            bySettingHour: hour, minute: 0, second: 0, of: .now
        ) ?? .now
        return formatter.string(from: date).lowercased()
    }
}

// MARK: - Caffeine Line Chart

struct CaffeineLineChart: View {
    let data: [(day: String, mg: Double)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ChartSectionHeader(title: "Caffeine Trend", icon: "bolt.fill")

            Chart {
                ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                    LineMark(
                        x: .value("Day", item.day),
                        y: .value("Caffeine", item.mg)
                    )
                    .foregroundStyle(Color.orange)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)
                    .symbol {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 7, height: 7)
                    }

                    AreaMark(
                        x: .value("Day", item.day),
                        y: .value("Caffeine", item.mg)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.25), Color.orange.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }

                // 400mg FDA recommended limit
                RuleMark(y: .value("Limit", 400))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 4]))
                    .foregroundStyle(.red.opacity(0.6))
                    .annotation(position: .top, alignment: .leading) {
                        Text("400mg limit")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.red.opacity(0.7))
                    }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    if let mg = value.as(Double.self) {
                        AxisValueLabel {
                            Text("\(Int(mg))mg")
                                .font(.caption2)
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.gray.opacity(0.15))
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let day = value.as(String.self) {
                            Text(day)
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYScale(domain: 0...chartYMax)
            .frame(height: 180)

            // Average callout
            let avgMg = data.map(\.mg).reduce(0, +) / Double(max(data.count, 1))
            if avgMg > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text("Avg: \(Int(avgMg))mg/day")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .aquaCard()
    }

    private var chartYMax: Double {
        let maxData = data.map(\.mg).max() ?? 0
        return max(450, maxData * 1.2) // at least show 400mg limit
    }
}

// MARK: - Shared Components

private struct ChartSectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
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
        }
        .accessibilityAddTraits(.isHeader)
    }
}

private struct ChartLegendDot: View {
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

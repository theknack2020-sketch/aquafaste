import SwiftUI
import Charts

struct HistoryView: View {
    @Environment(HydrationManager.self) private var manager
    private let profile = UserProfile.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Streak card
                    if profile.currentStreak > 0 {
                        streakCard
                    }

                    // Weekly chart
                    weeklyChart

                    // Today's details
                    todaySection

                    // Yesterday
                    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
                    daySection(for: yesterday, title: "Yesterday")
                }
                .padding()
            }
            .navigationTitle("History")
        }
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(profile.currentStreak) Day Streak")
                        .font(.title3.weight(.bold))
                    Text(streakMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            // Milestone dots
            HStack(spacing: 4) {
                ForEach([3, 7, 14, 30, 60, 100], id: \.self) { milestone in
                    VStack(spacing: 2) {
                        Circle()
                            .fill(profile.currentStreak >= milestone ? Color.orange : Color.gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                        Text("\(milestone)")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                    }
                    if milestone != 100 {
                        Rectangle()
                            .fill(profile.currentStreak >= milestone ? Color.orange.opacity(0.5) : Color.gray.opacity(0.2))
                            .frame(height: 2)
                    }
                }
            }
        }
        .padding()
        .background(Color.aquaCardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    private var streakMessage: String {
        switch profile.currentStreak {
        case 1...2: return "Just getting started!"
        case 3...6: return "Building momentum!"
        case 7...13: return "One week strong!"
        case 14...29: return "Two weeks of hydration!"
        case 30...59: return "A whole month! Amazing!"
        case 60...99: return "Two months! Incredible!"
        default: return "Legendary streak!"
        }
    }

    // MARK: - Weekly Chart

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)

            let weekData = manager.weeklyData()

            Chart(weekData, id: \.date) { item in
                BarMark(
                    x: .value("Day", item.date, unit: .day),
                    y: .value("ml", item.total)
                )
                .foregroundStyle(
                    item.total >= profile.dailyGoal
                        ? Color.aquaPrimary
                        : Color.aquaPrimary.opacity(0.4)
                )
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    if let ml = value.as(Double.self) {
                        AxisValueLabel {
                            Text(profile.unit.formatAmount(ml))
                                .font(.caption2)
                        }
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
            .chartYScale(domain: 0...(profile.dailyGoal * 1.3))
            .frame(height: 180)

            // Goal line label
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.aquaPrimary)
                    .frame(width: 8, height: 8)
                Text("Goal met")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Circle()
                    .fill(Color.aquaPrimary.opacity(0.4))
                    .frame(width: 8, height: 8)
                    .padding(.leading, 8)
                Text("Under goal")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.aquaCardBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Today Section

    private var todaySection: some View {
        daySection(for: .now, title: "Today")
    }

    private func daySection(for date: Date, title: String) -> some View {
        let logs = manager.logsForDate(date)
        let total = logs.reduce(0) { $0 + $1.effectiveAmount }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(profile.unit.formatAmount(total))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.aquaPrimary)
            }

            if logs.isEmpty {
                Text("No drinks logged")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(logs, id: \.id) { log in
                    LogRow(log: log, unit: profile.unit)
                }
            }
        }
        .padding()
        .background(Color.aquaCardBackground, in: RoundedRectangle(cornerRadius: 16))
    }
}

import SwiftUI
import Charts

struct HistoryView: View {
    @Environment(HydrationManager.self) private var manager
    private let profile = UserProfile.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
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

import Foundation
import SwiftUI

// MARK: - Insight Item

struct InsightItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let value: String
    let subtitle: String
}

// MARK: - Insights Engine

@Observable @MainActor
final class InsightsEngine {
    private let profile = UserProfile.shared
    private let calendar = Calendar.current

    // MARK: - Weekly Bar Data

    /// Last 7 days with amount and goal for bar chart
    func weeklyBarData(from logs: [WaterLog]) -> [(day: String, amount: Double, goal: Double)] {
        let today = calendar.startOfDay(for: .now)
        let goal = profile.dailyGoal
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        let grouped = Dictionary(grouping: logs) { calendar.startOfDay(for: $0.timestamp) }

        return (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let dayLogs = grouped[date] ?? []
            let total = dayLogs.reduce(0.0) { $0 + $1.effectiveAmount }
            let label = formatter.string(from: date)
            return (day: label, amount: total, goal: goal)
        }
    }

    // MARK: - Monthly Heatmap Data

    /// Last 30 days with goal completion percentage
    func monthlyHeatmapData(from logs: [WaterLog]) -> [(date: Date, percentage: Double)] {
        let today = calendar.startOfDay(for: .now)
        let goal = profile.dailyGoal
        guard goal > 0 else { return [] }

        let grouped = Dictionary(grouping: logs) { calendar.startOfDay(for: $0.timestamp) }

        return (0..<30).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let dayLogs = grouped[date] ?? []
            let total = dayLogs.reduce(0.0) { $0 + $1.effectiveAmount }
            let pct = min(total / goal, 1.5) // cap at 150%
            return (date: date, percentage: pct)
        }
    }

    // MARK: - Drink Type Breakdown

    /// Breakdown by drink type with percentages
    func drinkTypeBreakdown(from logs: [WaterLog]) -> [(type: DrinkType, amount: Double, percentage: Double)] {
        var totals = [String: Double]()
        for log in logs {
            totals[log.drinkType, default: 0] += log.effectiveAmount
        }

        let grandTotal = totals.values.reduce(0, +)
        guard grandTotal > 0 else { return [] }

        return totals.compactMap { key, value in
            guard let type = DrinkType(rawValue: key) else { return nil }
            let pct = value / grandTotal * 100
            return (type: type, amount: value, percentage: pct)
        }
        .sorted { $0.amount > $1.amount }
    }

    // MARK: - Time of Day Distribution

    /// Hydration distribution across 24 hours
    func timeOfDayDistribution(from logs: [WaterLog]) -> [(hour: Int, amount: Double)] {
        var buckets = [Int: Double]()
        for log in logs {
            let hour = calendar.component(.hour, from: log.timestamp)
            buckets[hour, default: 0] += log.effectiveAmount
        }

        // Average across logged days for a meaningful curve
        let uniqueDays = Set(logs.map { calendar.startOfDay(for: $0.timestamp) }).count
        let divisor = max(Double(uniqueDays), 1)

        return (0..<24).map { hour in
            (hour: hour, amount: (buckets[hour] ?? 0) / divisor)
        }
    }

    // MARK: - Caffeine Weekly Trend

    /// Last 7 days caffeine intake in mg
    func caffeineWeeklyTrend(from logs: [WaterLog]) -> [(day: String, mg: Double)] {
        let today = calendar.startOfDay(for: .now)
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        let grouped = Dictionary(grouping: logs) { calendar.startOfDay(for: $0.timestamp) }

        return (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let dayLogs = grouped[date] ?? []
            let caffeine = dayLogs.reduce(0.0) { $0 + $1.caffeineMg }
            let label = formatter.string(from: date)
            return (day: label, mg: caffeine)
        }
    }

    // MARK: - Hydration Score

    /// 0–100 score based on consistency, goal completion, and variety
    func hydrationScore(from logs: [WaterLog]) -> Int {
        guard !logs.isEmpty else { return 0 }

        let goal = profile.dailyGoal
        guard goal > 0 else { return 0 }

        // Component 1: Goal completion rate (40 points)
        let grouped = Dictionary(grouping: logs) { calendar.startOfDay(for: $0.timestamp) }
        let totalDays = max(grouped.count, 1)
        let metDays = grouped.values.filter { dayLogs in
            dayLogs.reduce(0.0) { $0 + $1.effectiveAmount } >= goal
        }.count
        let completionRate = Double(metDays) / Double(totalDays)
        let completionScore = completionRate * 40

        // Component 2: Consistency — low variance in daily intake (30 points)
        let dailyTotals = grouped.values.map { dayLogs in
            dayLogs.reduce(0.0) { $0 + $1.effectiveAmount }
        }
        let avg = dailyTotals.reduce(0, +) / Double(dailyTotals.count)
        let variance = dailyTotals.reduce(0.0) { $0 + pow($1 - avg, 2) } / Double(dailyTotals.count)
        let stdDev = sqrt(variance)
        let cv = avg > 0 ? stdDev / avg : 1.0 // coefficient of variation
        let consistencyScore = max(0, (1 - cv)) * 30

        // Component 3: Drink variety (15 points)
        let uniqueTypes = Set(logs.map(\.drinkType)).count
        let varietyScore = min(Double(uniqueTypes) / 4.0, 1.0) * 15

        // Component 4: Recent activity — logged in last 3 days (15 points)
        let today = calendar.startOfDay(for: .now)
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!
        let recentDays = grouped.keys.filter { $0 >= threeDaysAgo }.count
        let recencyScore = min(Double(recentDays) / 3.0, 1.0) * 15

        let total = completionScore + consistencyScore + varietyScore + recencyScore
        return min(100, max(0, Int(total.rounded())))
    }

    // MARK: - Personalized Insights

    /// Generate contextual insights from log data
    func personalizedInsights(from logs: [WaterLog]) -> [InsightItem] {
        guard logs.count > 5 else {
            return [InsightItem(
                icon: "info.circle.fill",
                title: "Keep Logging",
                value: "\(logs.count)/5",
                subtitle: "Log a few more days to unlock insights"
            )]
        }

        var items: [InsightItem] = []

        let grouped = Dictionary(grouping: logs) { calendar.startOfDay(for: $0.timestamp) }

        // 1. Weekday vs Weekend comparison
        var weekdayTotals: [Double] = []
        var weekendTotals: [Double] = []
        for (date, dayLogs) in grouped {
            let total = dayLogs.reduce(0.0) { $0 + $1.effectiveAmount }
            let wd = calendar.component(.weekday, from: date)
            if wd == 1 || wd == 7 {
                weekendTotals.append(total)
            } else {
                weekdayTotals.append(total)
            }
        }
        if !weekdayTotals.isEmpty, !weekendTotals.isEmpty {
            let avgWD = weekdayTotals.reduce(0, +) / Double(weekdayTotals.count)
            let avgWE = weekendTotals.reduce(0, +) / Double(weekendTotals.count)
            let diff = abs(avgWD - avgWE) / max(avgWD, avgWE) * 100
            if diff > 10 {
                let higher = avgWD > avgWE ? "weekdays" : "weekends"
                items.append(InsightItem(
                    icon: "calendar",
                    title: "Weekly Pattern",
                    value: "\(Int(diff))% more",
                    subtitle: "You drink more on \(higher)"
                ))
            }
        }

        // 2. Peak hydration hour
        let todData = timeOfDayDistribution(from: logs)
        if let peak = todData.max(by: { $0.amount < $1.amount }), peak.amount > 0 {
            let formatter = DateFormatter()
            formatter.dateFormat = "ha"
            if let date = calendar.date(bySettingHour: peak.hour, minute: 0, second: 0, of: .now) {
                items.append(InsightItem(
                    icon: "clock.fill",
                    title: "Peak Hour",
                    value: formatter.string(from: date).lowercased(),
                    subtitle: "When you hydrate the most"
                ))
            }
        }

        // 3. Best streak
        let goal = profile.dailyGoal
        let sortedDays = grouped.keys.sorted()
        var bestStreak = 0
        var currentStreak = 0
        var previousDate: Date?
        for date in sortedDays {
            let dayTotal = (grouped[date] ?? []).reduce(0.0) { $0 + $1.effectiveAmount }
            if dayTotal >= goal {
                if let prev = previousDate,
                   let expected = calendar.date(byAdding: .day, value: 1, to: prev),
                   calendar.isDate(date, inSameDayAs: expected) {
                    currentStreak += 1
                } else {
                    currentStreak = 1
                }
                bestStreak = max(bestStreak, currentStreak)
                previousDate = date
            } else {
                currentStreak = 0
                previousDate = nil
            }
        }
        if bestStreak > 1 {
            items.append(InsightItem(
                icon: "flame.fill",
                title: "Best Streak",
                value: "\(bestStreak) days",
                subtitle: "Your longest goal-meeting run"
            ))
        }

        // 4. Average daily intake
        let dailyTotals = grouped.values.map { dayLogs in
            dayLogs.reduce(0.0) { $0 + $1.effectiveAmount }
        }
        let avgDaily = dailyTotals.reduce(0, +) / Double(max(dailyTotals.count, 1))
        items.append(InsightItem(
            icon: "drop.fill",
            title: "Daily Average",
            value: profile.unit.formatAmount(avgDaily),
            subtitle: "Across \(dailyTotals.count) logged days"
        ))

        // 5. Caffeine average
        let totalCaffeine = logs.reduce(0.0) { $0 + $1.caffeineMg }
        let avgCaffeine = totalCaffeine / Double(max(grouped.count, 1))
        if avgCaffeine > 0 {
            items.append(InsightItem(
                icon: "bolt.fill",
                title: "Daily Caffeine",
                value: "\(Int(avgCaffeine)) mg",
                subtitle: avgCaffeine > 400 ? "Above recommended 400mg limit" : "Within healthy range"
            ))
        }

        // 6. Goal achievement rate
        let metDays = grouped.values.filter { dayLogs in
            dayLogs.reduce(0.0) { $0 + $1.effectiveAmount } >= goal
        }.count
        let rate = Double(metDays) / Double(max(grouped.count, 1)) * 100
        let rateSubtitle: String
        if rate >= 80 {
            rateSubtitle = "Excellent consistency!"
        } else if rate >= 50 {
            rateSubtitle = "Good progress, keep going"
        } else {
            rateSubtitle = "Try setting more reminders"
        }
        items.append(InsightItem(
            icon: "checkmark.seal.fill",
            title: "Goal Rate",
            value: "\(Int(rate))%",
            subtitle: rateSubtitle
        ))

        return items
    }
}

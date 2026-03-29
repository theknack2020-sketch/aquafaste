import Foundation
import SwiftData
import SwiftUI
import TelemetryDeck

@Observable @MainActor
final class HydrationManager {
    static let shared = HydrationManager()

    private var modelContext: ModelContext?
    let profile = UserProfile.shared

    var todayLogs: [WaterLog] = []
    var todayTotal: Double = 0 // effective ml
    var todayRawTotal: Double = 0 // raw ml
    var progress: Double = 0 // 0.0 - 1.0+
    var todayCaffeine: Double = 0 // mg

    /// Error presentation state
    var showError = false
    var errorTitle = ""
    var errorMessage = ""

    /// Last undone log (for undo support)
    var lastDeletedLog: WaterLog?

    func setup(context: ModelContext) {
        modelContext = context
        handleTimezoneChange()
        refreshToday()
    }

    // MARK: - Error Handling

    private func presentError(title: String, message: String) {
        errorTitle = title
        errorMessage = message
        showError = true
    }

    // MARK: - Logging

    func logWater(amount: Double, drinkType: DrinkType, caffeineMg: Double? = nil) {
        guard let context = modelContext else { return }

        let wasUnderGoal = todayTotal < profile.dailyGoal

        let log = WaterLog(amount: amount, drinkType: drinkType, caffeineMg: caffeineMg)
        context.insert(log)

        TelemetryDeck.signal("water.logged", parameters: [
            "amount": "\(Int(amount))",
            "drinkType": drinkType.rawValue
        ])

        do {
            try context.save()
        } catch {
            print("[AquaFaste] Failed to save water log: \(error)")
            presentError(
                title: "Couldn't Save Drink",
                message: "Couldn't save your drink. Try again?"
            )
        }

        // Write to HealthKit
        Task {
            await HealthKitManager.shared.saveWaterIntake(
                amount: amount,
                date: log.timestamp
            )
        }

        refreshToday()
        checkStreak()

        // Smart timing: record log for notification suppression
        NotificationManager.shared.recordWaterLog()

        // Goal completion notification
        if wasUnderGoal, todayTotal >= profile.dailyGoal {
            NotificationManager.shared.sendGoalCompleteNotification(
                streak: profile.currentStreak
            )
        }

        // Refill reminder check
        checkRefillReminder()

        // Reschedule reminders with updated smart timing
        Task {
            await NotificationManager.shared.scheduleAllNotifications()
        }
    }

    func deleteLog(_ log: WaterLog) {
        guard let context = modelContext else { return }
        lastDeletedLog = nil // can't undo a manual delete
        context.delete(log)
        do {
            try context.save()
        } catch {
            print("[AquaFaste] Failed to delete log: \(error)")
            presentError(
                title: "Couldn't Remove Entry",
                message: "Couldn't remove that entry. Please try once more."
            )
        }
        refreshToday()
    }

    /// Delete all water logs (used by data reset)
    func deleteAllLogs() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<WaterLog>()
        if let all = try? context.fetch(descriptor) {
            for log in all {
                context.delete(log)
            }
            do {
                try context.save()
            } catch {
                print("[AquaFaste] Failed to delete all logs: \(error)")
                presentError(
                    title: "Reset Failed",
                    message: "Something went wrong. Your data is safe — try again in a moment."
                )
            }
        }
        refreshToday()
    }

    /// Edit a past log's amount or drink type
    func editLog(_ log: WaterLog, newAmount: Double? = nil, newDrinkType: DrinkType? = nil) {
        if let amount = newAmount {
            log.amount = amount
        }
        if let type = newDrinkType {
            log.drinkType = type.rawValue
            log.hydrationRatio = type.hydrationRatio
            log.caffeineMg = type.caffeinePer250ml * log.amount / 250.0
        }
        do {
            try modelContext?.save()
        } catch {
            print("[AquaFaste] Failed to edit log: \(error)")
            presentError(
                title: "Couldn't Save Changes",
                message: "Couldn't save your drink. Try again?"
            )
        }
        refreshToday()
    }

    /// Undo the most recent drink log
    func undoLastDrink() -> WaterLog? {
        guard let lastLog = todayLogs.first else { return nil }
        let undone = lastLog
        deleteLog(lastLog)
        lastDeletedLog = undone
        return undone
    }

    /// Redo (re-add) the last undone drink
    func redoLastDrink() {
        guard let log = lastDeletedLog else { return }
        logWater(amount: log.amount, drinkType: log.drink, caffeineMg: log.caffeineMg)
        lastDeletedLog = nil
    }

    // MARK: - Recent Drinks

    /// Returns the last N unique drink configurations (type + amount combos)
    func recentDrinks(limit: Int = 3) -> [(drinkType: DrinkType, amount: Double)] {
        guard let context = modelContext else { return [] }

        let descriptor = FetchDescriptor<WaterLog>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        guard let logs = try? context.fetch(descriptor) else { return [] }

        var seen = Set<String>()
        var result: [(drinkType: DrinkType, amount: Double)] = []

        for log in logs {
            let key = "\(log.drinkType)_\(Int(log.amount))"
            if !seen.contains(key) {
                seen.insert(key)
                result.append((drinkType: log.drink, amount: log.amount))
            }
            if result.count >= limit { break }
        }

        return result
    }

    // MARK: - Favorites

    func fetchFavorites() -> [FavoriteDrink] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<FavoriteDrink>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func addFavorite(name: String, drinkType: DrinkType, amount: Double, caffeineMg: Double = 0) {
        guard let context = modelContext else { return }
        let existing = fetchFavorites()
        let fav = FavoriteDrink(
            name: name,
            drinkType: drinkType,
            amount: amount,
            caffeineAmount: caffeineMg,
            sortOrder: existing.count
        )
        context.insert(fav)
        do {
            try context.save()
        } catch {
            print("[AquaFaste] Failed to save favorite: \(error)")
            presentError(
                title: "Couldn't Save Favorite",
                message: "Couldn't save your drink. Try again?"
            )
        }
    }

    func deleteFavorite(_ fav: FavoriteDrink) {
        guard let context = modelContext else { return }
        context.delete(fav)
        do {
            try context.save()
        } catch {
            print("[AquaFaste] Failed to delete favorite: \(error)")
            presentError(
                title: "Couldn't Remove Favorite",
                message: "Couldn't remove that entry. Please try once more."
            )
        }
    }

    // MARK: - Caffeine

    func todayCaffeineTotal() -> Double {
        todayLogs.reduce(0) { $0 + $1.caffeineMg }
    }

    // MARK: - Refill Reminder

    private func checkRefillReminder() {
        guard profile.refillReminderEnabled else { return }
        let bottleSize = profile.bottleSize

        // Check how much was logged since last "bottle boundary"
        let totalRaw = todayRawTotal
        let bottlesFilled = Int(totalRaw / bottleSize)
        let previousBottles = Int((totalRaw - (todayLogs.first?.amount ?? 0)) / bottleSize)

        if bottlesFilled > previousBottles {
            // Crossed a bottle boundary — send refill reminder
            NotificationManager.shared.sendRefillReminder(bottleNumber: bottlesFilled)
        }
    }

    // MARK: - Timezone Handling

    private func handleTimezoneChange() {
        let current = TimeZone.current.identifier
        let saved = profile.lastTimezoneIdentifier

        if current != saved {
            print("[AquaFaste] Timezone changed: \(saved) → \(current)")
            profile.lastTimezoneIdentifier = current
            // Force refresh — Calendar.current uses the new timezone automatically
            // so startOfDay calculations will be correct for the new timezone
        }
    }

    // MARK: - Queries

    func refreshToday() {
        guard let context = modelContext else { return }

        // Use current calendar which respects the device's timezone
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let descriptor = FetchDescriptor<WaterLog>(
            predicate: #Predicate<WaterLog> { log in
                log.timestamp >= startOfDay && log.timestamp < endOfDay
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        do {
            todayLogs = try context.fetch(descriptor)
            todayTotal = todayLogs.reduce(0) { $0 + $1.effectiveAmount }
            todayRawTotal = todayLogs.reduce(0) { $0 + $1.amount }
            todayCaffeine = todayLogs.reduce(0) { $0 + $1.caffeineMg }
            progress = profile.dailyGoal > 0 ? todayTotal / profile.dailyGoal : 0

            // Update widget data (when widget extension is configured)
            #if canImport(WidgetKit)
            if let defaults = UserDefaults(suiteName: "group.com.theknack.aquafaste") {
                defaults.set(todayTotal, forKey: "todayTotal")
                defaults.set(profile.dailyGoal, forKey: "dailyGoal")
                defaults.set(todayLogs.count, forKey: "drinkCount")
                defaults.set(Date().timeIntervalSince1970, forKey: "lastUpdate")
            }
            #endif
        } catch {
            print("[AquaFaste] Failed to fetch today's logs: \(error)")
        }
    }

    func logsForDate(_ date: Date) -> [WaterLog] {
        guard let context = modelContext else { return [] }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let descriptor = FetchDescriptor<WaterLog>(
            predicate: #Predicate<WaterLog> { log in
                log.timestamp >= startOfDay && log.timestamp < endOfDay
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    func totalForDate(_ date: Date) -> Double {
        logsForDate(date).reduce(0) { $0 + $1.effectiveAmount }
    }

    /// Last 7 days totals for weekly chart
    func weeklyData() -> [(date: Date, total: Double)] {
        let calendar = Calendar.current
        return (0 ..< 7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: .now)!
            let start = calendar.startOfDay(for: date)
            return (date: start, total: totalForDate(start))
        }
    }

    // MARK: - Stats Queries

    /// Fetch all logs (optionally limited to a date range)
    func allLogs(from startDate: Date? = nil, to endDate: Date? = nil) -> [WaterLog] {
        guard let context = modelContext else { return [] }

        let descriptor = if let start = startDate, let end = endDate {
            FetchDescriptor<WaterLog>(
                predicate: #Predicate<WaterLog> { log in
                    log.timestamp >= start && log.timestamp < end
                },
                sortBy: [SortDescriptor(\.timestamp, order: .forward)]
            )
        } else {
            FetchDescriptor<WaterLog>(
                sortBy: [SortDescriptor(\.timestamp, order: .forward)]
            )
        }

        return (try? context.fetch(descriptor)) ?? []
    }

    /// All-time total effective hydration
    func allTimeTotalMl() -> Double {
        allLogs().reduce(0) { $0 + $1.effectiveAmount }
    }

    /// Average daily intake over all logged days
    func averageDailyIntake() -> Double {
        let logs = allLogs()
        guard !logs.isEmpty else { return 0 }

        let calendar = Calendar.current
        let grouped = Dictionary(grouping: logs) { calendar.startOfDay(for: $0.timestamp) }
        let dailyTotals = grouped.values.map { dayLogs in
            dayLogs.reduce(0.0) { $0 + $1.effectiveAmount }
        }
        return dailyTotals.reduce(0, +) / Double(dailyTotals.count)
    }

    /// Current streak — consecutive days meeting goal ending today or yesterday
    func computeCurrentStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        var streak = 0
        var checkDate = today

        // If today hasn't met goal yet, start checking from yesterday
        if totalForDate(today) < profile.dailyGoal {
            checkDate = calendar.date(byAdding: .day, value: -1, to: today)!
        }

        while true {
            let dayTotal = totalForDate(checkDate)
            if dayTotal >= profile.dailyGoal {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        return streak
    }

    /// Best streak ever
    func computeBestStreak() -> Int {
        let logs = allLogs()
        guard !logs.isEmpty else { return 0 }

        let calendar = Calendar.current
        let grouped = Dictionary(grouping: logs) { calendar.startOfDay(for: $0.timestamp) }

        guard let earliest = grouped.keys.min() else { return 0 }
        let today = calendar.startOfDay(for: .now)
        let totalDays = calendar.dateComponents([.day], from: earliest, to: today).day ?? 0

        var bestStreak = 0
        var currentStreak = 0

        for dayOffset in 0 ... totalDays {
            let date = calendar.date(byAdding: .day, value: dayOffset, to: earliest)!
            let dayLogs = grouped[calendar.startOfDay(for: date)] ?? []
            let dayTotal = dayLogs.reduce(0.0) { $0 + $1.effectiveAmount }

            if dayTotal >= profile.dailyGoal {
                currentStreak += 1
                bestStreak = max(bestStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }
        return bestStreak
    }

    /// Goal achievement rate — % of logged days where goal was met
    func goalAchievementRate() -> Double {
        let logs = allLogs()
        guard !logs.isEmpty else { return 0 }

        let calendar = Calendar.current
        let grouped = Dictionary(grouping: logs) { calendar.startOfDay(for: $0.timestamp) }
        let metDays = grouped.values.count(where: { dayLogs in
            dayLogs.reduce(0.0) { $0 + $1.effectiveAmount } >= profile.dailyGoal
        })
        return Double(metDays) / Double(grouped.count) * 100
    }

    /// Time-of-day breakdown — total ml per hour bucket
    func timeOfDayData() -> [(hour: Int, total: Double)] {
        let logs = allLogs()
        let calendar = Calendar.current
        var buckets = [Int: Double]()

        for log in logs {
            let hour = calendar.component(.hour, from: log.timestamp)
            buckets[hour, default: 0] += log.effectiveAmount
        }

        return (0 ..< 24).map { hour in
            (hour: hour, total: buckets[hour] ?? 0)
        }
    }

    /// Drink type breakdown — total effective ml per type
    func drinkTypeBreakdown() -> [(type: DrinkType, total: Double)] {
        let logs = allLogs()
        var totals = [String: Double]()

        for log in logs {
            totals[log.drinkType, default: 0] += log.effectiveAmount
        }

        return totals.compactMap { key, value in
            guard let type = DrinkType(rawValue: key) else { return nil }
            return (type: type, total: value)
        }
        .sorted { $0.total > $1.total }
    }

    /// Weekly comparison data — this week vs last week totals
    func weeklyComparison() -> (thisWeek: Double, lastWeek: Double) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let weekday = calendar.component(.weekday, from: today)
        // Days since Monday (weekday 2 in gregorian)
        let daysSinceMonday = (weekday + 5) % 7
        let thisMonday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: today)!
        let lastMonday = calendar.date(byAdding: .day, value: -7, to: thisMonday)!

        var thisWeekTotal = 0.0
        var lastWeekTotal = 0.0

        for i in 0 ..< 7 {
            let thisDay = calendar.date(byAdding: .day, value: i, to: thisMonday)!
            let lastDay = calendar.date(byAdding: .day, value: i, to: lastMonday)!

            // Only count days up to today for this week
            if thisDay <= today {
                thisWeekTotal += totalForDate(thisDay)
            }
            lastWeekTotal += totalForDate(lastDay)
        }

        return (thisWeek: thisWeekTotal, lastWeek: lastWeekTotal)
    }

    /// Monthly calendar data — daily totals for the given month
    func monthlyCalendarData(for month: Date) -> [(date: Date, total: Double, ratio: Double)] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month))
        else { return [] }

        return range.map { day in
            let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart)!
            let total = totalForDate(date)
            let ratio = profile.dailyGoal > 0 ? total / profile.dailyGoal : 0
            return (date: date, total: total, ratio: ratio)
        }
    }

    /// Generate insights text based on log data
    func generateInsights() -> [String] {
        let logs = allLogs()
        guard logs.count > 7 else { return ["Log more data to unlock insights!"] }

        var insights: [String] = []
        let calendar = Calendar.current

        // Weekday vs weekend comparison
        let grouped = Dictionary(grouping: logs) { calendar.startOfDay(for: $0.timestamp) }
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
            let avgWeekday = weekdayTotals.reduce(0, +) / Double(weekdayTotals.count)
            let avgWeekend = weekendTotals.reduce(0, +) / Double(weekendTotals.count)
            let diff = abs(avgWeekday - avgWeekend) / max(avgWeekday, avgWeekend) * 100

            if diff > 10 {
                if avgWeekday > avgWeekend {
                    insights.append("You drink \(Int(diff))% more on weekdays than weekends")
                } else {
                    insights.append("You drink \(Int(diff))% more on weekends than weekdays")
                }
            }
        }

        // Peak hour
        let todData = timeOfDayData()
        if let peakHour = todData.max(by: { $0.total < $1.total }), peakHour.total > 0 {
            let formatter = DateFormatter()
            formatter.dateFormat = "ha"
            let cal = Calendar.current
            if let date = cal.date(bySettingHour: peakHour.hour, minute: 0, second: 0, of: .now) {
                let timeStr = formatter.string(from: date).lowercased()
                insights.append("Your peak hydration hour is \(timeStr)")
            }
        }

        // Most popular drink
        let breakdown = drinkTypeBreakdown()
        if let topDrink = breakdown.first, breakdown.count > 1 {
            let totalAll = breakdown.reduce(0.0) { $0 + $1.total }
            let pct = Int(topDrink.total / totalAll * 100)
            insights.append("\(topDrink.type.displayName) makes up \(pct)% of your hydration")
        }

        // Goal consistency
        let rate = goalAchievementRate()
        if rate >= 80 {
            insights.append("You hit your goal \(Int(rate))% of days — excellent consistency!")
        } else if rate >= 50 {
            insights.append("You meet your goal \(Int(rate))% of days — room to improve")
        } else if rate > 0 {
            insights.append("Goal met \(Int(rate))% of days — try setting reminders closer together")
        }

        // Caffeine insight
        let totalCaffeine = logs.reduce(0.0) { $0 + $1.caffeineMg }
        let logDays = max(1, grouped.count)
        let avgCaffeine = totalCaffeine / Double(logDays)
        if avgCaffeine > 0 {
            insights.append("Average daily caffeine: \(Int(avgCaffeine)) mg")
        }

        return insights
    }

    // MARK: - Streak

    private func checkStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        guard todayTotal >= profile.dailyGoal else { return }

        if let lastDate = profile.lastGoalMetDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            if lastDay == today {
                return // already counted today
            }
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            if lastDay == yesterday {
                profile.currentStreak += 1
            } else {
                profile.currentStreak = 1 // streak broken
            }
        } else {
            profile.currentStreak = 1
        }
        profile.lastGoalMetDate = today
    }
}

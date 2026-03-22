import Foundation
import SwiftData
import SwiftUI

@Observable @MainActor
final class HydrationManager {
    private var modelContext: ModelContext?
    let profile = UserProfile.shared

    var todayLogs: [WaterLog] = []
    var todayTotal: Double = 0     // effective ml
    var todayRawTotal: Double = 0  // raw ml
    var progress: Double = 0       // 0.0 - 1.0+

    func setup(context: ModelContext) {
        self.modelContext = context
        refreshToday()
    }

    // MARK: - Logging

    func logWater(amount: Double, drinkType: DrinkType) {
        guard let context = modelContext else { return }

        let log = WaterLog(amount: amount, drinkType: drinkType)
        context.insert(log)

        do {
            try context.save()
        } catch {
            print("[AquaFaste] Failed to save water log: \(error)")
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
    }

    func deleteLog(_ log: WaterLog) {
        guard let context = modelContext else { return }
        context.delete(log)
        try? context.save()
        refreshToday()
    }

    // MARK: - Queries

    func refreshToday() {
        guard let context = modelContext else { return }

        let startOfDay = Calendar.current.startOfDay(for: .now)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

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
            progress = profile.dailyGoal > 0 ? todayTotal / profile.dailyGoal : 0
        } catch {
            print("[AquaFaste] Failed to fetch today's logs: \(error)")
        }
    }

    func logsForDate(_ date: Date) -> [WaterLog] {
        guard let context = modelContext else { return [] }

        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

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
        return (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: .now)!
            let start = calendar.startOfDay(for: date)
            return (date: start, total: totalForDate(start))
        }
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

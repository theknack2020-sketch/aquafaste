import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Shared data between app and widget via App Group
enum WidgetDataManager {
    static let suiteName = "group.com.theknack.aquafaste"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    // MARK: - Write (from main app)

    static func updateWidgetData(
        todayTotal: Double,
        dailyGoal: Double,
        streak: Int,
        lastDrinkTime: Date?,
        drinkCount: Int
    ) {
        let d = defaults
        d?.set(todayTotal, forKey: "todayTotal")
        d?.set(dailyGoal, forKey: "dailyGoal")
        d?.set(streak, forKey: "streak")
        d?.set(lastDrinkTime?.timeIntervalSince1970 ?? 0, forKey: "lastDrinkTime")
        d?.set(drinkCount, forKey: "drinkCount")
        d?.set(Date().timeIntervalSince1970, forKey: "lastUpdate")

        // Trigger widget refresh
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    // MARK: - Read (from widget)

    static var todayTotal: Double {
        defaults?.double(forKey: "todayTotal") ?? 0
    }

    static var dailyGoal: Double {
        let goal = defaults?.double(forKey: "dailyGoal") ?? 0
        return goal > 0 ? goal : 2500
    }

    static var streak: Int {
        defaults?.integer(forKey: "streak") ?? 0
    }

    static var drinkCount: Int {
        defaults?.integer(forKey: "drinkCount") ?? 0
    }

    static var lastDrinkTime: Date? {
        let ts = defaults?.double(forKey: "lastDrinkTime") ?? 0
        return ts > 0 ? Date(timeIntervalSince1970: ts) : nil
    }

    static var progress: Double {
        let goal = dailyGoal
        guard goal > 0 else { return 0 }
        return min(1.0, todayTotal / goal)
    }
}

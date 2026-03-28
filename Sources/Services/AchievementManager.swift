import Foundation
import SwiftData
import SwiftUI

/// Manages achievement definitions, progress checking, and unlock celebrations.
@Observable @MainActor
final class AchievementManager {
    static let shared = AchievementManager()

    private(set) var achievements: [Achievement] = []

    /// Recently unlocked achievements waiting to be celebrated
    private(set) var pendingCelebration: Achievement?

    private let haptics = HapticManager.shared

    private init() {}

    // MARK: - Achievement Definitions

    /// All achievement definitions — id, title, subtitle, icon, category, tier
    static let definitions: [(
        id: String, title: String, subtitle: String,
        iconName: String, category: AchievementCategory, tier: AchievementTier
    )] = [
        // Streak
        ("streak_3", "Hydration Starter", "Maintain a 3-day streak", "flame.fill", .streak, .bronze),
        ("streak_7", "Week Warrior", "Maintain a 7-day streak", "flame.fill", .streak, .silver),
        ("streak_30", "Monthly Master", "Maintain a 30-day streak", "flame.fill", .streak, .gold),
        ("streak_100", "Century Club", "Maintain a 100-day streak", "flame.fill", .streak, .platinum),

        // Volume
        ("volume_1000", "First Liter", "Drink 1,000 ml in a single day", "drop.fill", .volume, .bronze),
        ("volume_3000", "Hydration Hero", "Drink 3,000 ml in a single day", "drop.fill", .volume, .gold),

        // Variety
        ("variety_5", "Drink Explorer", "Log 5 different drink types", "square.grid.3x3.fill", .variety, .bronze),
        ("variety_10", "Mixologist", "Log all drink types", "square.grid.3x3.fill", .variety, .silver),

        // Consistency
        ("consistency_7", "Perfect Week", "Hit 100% goal for 7 consecutive days", "checkmark.seal.fill", .consistency, .gold),

        // Caffeine
        ("caffeine_0", "Caffeine Free Day", "Log only caffeine-free drinks in a day", "leaf.fill", .caffeine, .bronze),

        // Timing
        ("early_bird", "Early Bird", "Log a drink before 7:00 AM", "sunrise.fill", .timing, .bronze),
        ("night_owl", "Night Hydrator", "Log a drink after 10:00 PM", "moon.fill", .timing, .bronze),
    ]

    // MARK: - Setup

    /// Seed default achievements on first launch. Idempotent — skips existing IDs.
    func setupAchievements(context: ModelContext) {
        let existing = fetchAll(context: context)
        let existingIDs = Set(existing.map(\.id))

        for def in Self.definitions where !existingIDs.contains(def.id) {
            let achievement = Achievement(
                id: def.id,
                title: def.title,
                subtitle: def.subtitle,
                iconName: def.iconName,
                category: def.category,
                tier: def.tier
            )
            context.insert(achievement)
        }

        do {
            try context.save()
        } catch {
            print("[AquaFaste] Failed to seed achievements: \(error)")
        }

        achievements = fetchAll(context: context)
    }

    // MARK: - Check & Unlock

    /// Evaluate all achievement conditions and unlock any newly earned ones.
    func checkAndUnlock(logs: [WaterLog], streak: Int, context: ModelContext) {
        achievements = fetchAll(context: context)

        var newlyUnlocked: [Achievement] = []

        for achievement in achievements where !achievement.isUnlocked {
            if shouldUnlock(achievement: achievement, logs: logs, streak: streak) {
                achievement.unlockedAt = .now
                newlyUnlocked.append(achievement)
            }
        }

        guard !newlyUnlocked.isEmpty else { return }

        do {
            try context.save()
        } catch {
            print("[AquaFaste] Failed to save unlocked achievements: \(error)")
        }

        // Refresh local copy
        achievements = fetchAll(context: context)

        // Celebrate the highest-tier newly unlocked achievement
        if let best = newlyUnlocked.sorted(by: { $0.tier.sortOrder > $1.tier.sortOrder }).first {
            celebrate(best)
        }
    }

    /// Clear pending celebration after UI has displayed it
    func clearCelebration() {
        pendingCelebration = nil
    }

    // MARK: - Progress Info

    var unlockedCount: Int {
        achievements.filter(\.isUnlocked).count
    }

    var totalCount: Int {
        achievements.count
    }

    /// Grouped achievements by category for display
    var groupedByCategory: [(category: AchievementCategory, items: [Achievement])] {
        let grouped = Dictionary(grouping: achievements) { $0.category }
        return AchievementCategory.allCases.compactMap { cat in
            guard let items = grouped[cat], !items.isEmpty else { return nil }
            let sorted = items.sorted { a, b in
                if a.isUnlocked != b.isUnlocked { return a.isUnlocked }
                return a.tier.sortOrder < b.tier.sortOrder
            }
            return (category: cat, items: sorted)
        }
    }

    // MARK: - Private

    private func fetchAll(context: ModelContext) -> [Achievement] {
        let descriptor = FetchDescriptor<Achievement>(
            sortBy: [SortDescriptor(\.categoryRaw), SortDescriptor(\.tierRaw)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    private func shouldUnlock(achievement: Achievement, logs: [WaterLog], streak: Int) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        switch achievement.id {
        // MARK: Streak achievements
        case "streak_3":
            return streak >= 3
        case "streak_7":
            return streak >= 7
        case "streak_30":
            return streak >= 30
        case "streak_100":
            return streak >= 100

        // MARK: Volume achievements — today's total raw ml
        case "volume_1000":
            let todayTotal = todayRawTotal(logs: logs, calendar: calendar, today: today)
            return todayTotal >= 1000
        case "volume_3000":
            let todayTotal = todayRawTotal(logs: logs, calendar: calendar, today: today)
            return todayTotal >= 3000

        // MARK: Variety achievements — unique drink types ever logged
        case "variety_5":
            let uniqueTypes = Set(logs.map(\.drinkType))
            return uniqueTypes.count >= 5
        case "variety_10":
            let uniqueTypes = Set(logs.map(\.drinkType))
            return uniqueTypes.count >= 10

        // MARK: Consistency — 7 consecutive days at 100% goal
        case "consistency_7":
            // Already checked by streak ≥ 7 (streak = consecutive goal-met days)
            return streak >= 7

        // MARK: Caffeine — no caffeine today
        case "caffeine_0":
            let todayLogs = logs.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
            guard !todayLogs.isEmpty else { return false }
            return todayLogs.allSatisfy { $0.caffeineMg <= 0 }

        // MARK: Timing
        case "early_bird":
            return logs.contains { log in
                let hour = calendar.component(.hour, from: log.timestamp)
                return hour < 7
            }
        case "night_owl":
            return logs.contains { log in
                let hour = calendar.component(.hour, from: log.timestamp)
                return hour >= 22
            }

        default:
            return false
        }
    }

    private func todayRawTotal(logs: [WaterLog], calendar: Calendar, today: Date) -> Double {
        logs
            .filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
            .reduce(0) { $0 + $1.amount }
    }

    private func celebrate(_ achievement: Achievement) {
        pendingCelebration = achievement

        // Haptic feedback
        haptics.streakMilestone()

        // Send local notification for the unlock
        sendAchievementNotification(achievement)
    }

    private func sendAchievementNotification(_ achievement: Achievement) {
        let content = UNMutableNotificationContent()
        content.title = "Achievement Unlocked! 🏆"
        content.body = "\(achievement.title) — \(achievement.subtitle)"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "achievement_\(achievement.id)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
}

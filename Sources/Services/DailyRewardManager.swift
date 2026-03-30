import SwiftUI

@Observable @MainActor
final class DailyRewardManager {
    static let shared = DailyRewardManager()

    private let defaults = UserDefaults.standard
    private let rewardsKey = "af_daily_rewards"
    private let lastClaimKey = "af_last_reward_claim"

    var todayReward: DailyReward?
    var showRewardPopup = false

    struct DailyReward: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let message: String
        let color: Color
        let xpBonus: Int
    }

    private let rewardPool: [DailyReward] = [
        DailyReward(icon: "star.fill", title: "Hydration Star", message: "You're building a healthy habit!", color: .yellow, xpBonus: 10),
        DailyReward(icon: "bolt.fill", title: "Energy Boost", message: "Staying hydrated = more energy!", color: .orange, xpBonus: 15),
        DailyReward(icon: "heart.fill", title: "Heart Helper", message: "Your heart thanks you for hydrating!", color: .red, xpBonus: 12),
        DailyReward(icon: "brain.fill", title: "Brain Fuel", message: "Hydration improves focus by 14%!", color: .purple, xpBonus: 20),
        DailyReward(icon: "sparkles", title: "Glow Up", message: "Hydrated skin is happy skin!", color: .pink, xpBonus: 10),
        DailyReward(icon: "leaf.fill", title: "Wellness Warrior", message: "Consistency is your superpower!", color: .green, xpBonus: 15),
        DailyReward(icon: "trophy.fill", title: "Champion", message: "You showed up today. That matters!", color: .cyan, xpBonus: 25),
    ]

    func checkDailyReward() {
        let lastClaim = defaults.double(forKey: lastClaimKey)
        let lastDate = Date(timeIntervalSince1970: lastClaim)

        if !Calendar.current.isDateInToday(lastDate) {
            // New day — pick random reward
            todayReward = rewardPool.randomElement()
        }
    }

    func claimReward() {
        defaults.set(Date().timeIntervalSince1970, forKey: lastClaimKey)
        let total = defaults.integer(forKey: "af_total_xp") + (todayReward?.xpBonus ?? 0)
        defaults.set(total, forKey: "af_total_xp")
        showRewardPopup = false
    }

    var totalXP: Int {
        defaults.integer(forKey: "af_total_xp")
    }
}

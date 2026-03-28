import Foundation
import SwiftData
import SwiftUI

// MARK: - Achievement Category

enum AchievementCategory: String, Codable, CaseIterable, Identifiable {
    case streak
    case volume
    case variety
    case consistency
    case caffeine
    case timing

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .streak: "Streak"
        case .volume: "Volume"
        case .variety: "Variety"
        case .consistency: "Consistency"
        case .caffeine: "Caffeine"
        case .timing: "Timing"
        }
    }

    var iconName: String {
        switch self {
        case .streak: "flame.fill"
        case .volume: "drop.fill"
        case .variety: "square.grid.3x3.fill"
        case .consistency: "checkmark.seal.fill"
        case .caffeine: "cup.and.saucer.fill"
        case .timing: "clock.fill"
        }
    }
}

// MARK: - Achievement Tier

enum AchievementTier: String, Codable, CaseIterable {
    case bronze
    case silver
    case gold
    case platinum

    var color: Color {
        switch self {
        case .bronze: .achievementBronze
        case .silver: .achievementSilver
        case .gold: .achievementGold
        case .platinum: .achievementPlatinum
        }
    }

    var displayName: String {
        switch self {
        case .bronze: "Bronze"
        case .silver: "Silver"
        case .gold: "Gold"
        case .platinum: "Platinum"
        }
    }

    /// Sort order — lower is easier
    var sortOrder: Int {
        switch self {
        case .bronze: 0
        case .silver: 1
        case .gold: 2
        case .platinum: 3
        }
    }
}

// MARK: - Achievement Model

@Model
final class Achievement {
    @Attribute(.unique) var id: String
    var title: String
    var subtitle: String
    var iconName: String
    var unlockedAt: Date?
    var categoryRaw: String
    var tierRaw: String

    var isUnlocked: Bool { unlockedAt != nil }

    var category: AchievementCategory {
        get { AchievementCategory(rawValue: categoryRaw) ?? .streak }
        set { categoryRaw = newValue.rawValue }
    }

    var tier: AchievementTier {
        get { AchievementTier(rawValue: tierRaw) ?? .bronze }
        set { tierRaw = newValue.rawValue }
    }

    init(
        id: String,
        title: String,
        subtitle: String,
        iconName: String,
        category: AchievementCategory,
        tier: AchievementTier,
        unlockedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.categoryRaw = category.rawValue
        self.tierRaw = tier.rawValue
        self.unlockedAt = unlockedAt
    }
}

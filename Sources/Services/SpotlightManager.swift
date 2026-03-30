import CoreSpotlight
import Foundation
import UIKit

enum SpotlightManager {
    static let domainID = "com.theknack.aquafaste"

    /// Index the app's main actions for Spotlight search
    static func indexAppActions() {
        var items: [CSSearchableItem] = []

        // Log Water action
        let logWater = CSSearchableItemAttributeSet(contentType: .item)
        logWater.title = "Log Water"
        logWater.contentDescription = "Track your water intake with AquaFaste"
        logWater.thumbnailData = UIImage(systemName: "drop.fill")?.pngData()
        items.append(CSSearchableItem(
            uniqueIdentifier: "\(domainID).logWater",
            domainIdentifier: domainID,
            attributeSet: logWater
        ))

        // Check Hydration
        let check = CSSearchableItemAttributeSet(contentType: .item)
        check.title = "Check Hydration Progress"
        check.contentDescription = "See how much water you've had today"
        check.thumbnailData = UIImage(systemName: "chart.bar.fill")?.pngData()
        items.append(CSSearchableItem(
            uniqueIdentifier: "\(domainID).checkProgress",
            domainIdentifier: domainID,
            attributeSet: check
        ))

        // Hydration Stats
        let stats = CSSearchableItemAttributeSet(contentType: .item)
        stats.title = "Hydration Statistics"
        stats.contentDescription = "View your hydration score, streaks, and weekly trends"
        stats.thumbnailData = UIImage(systemName: "chart.line.uptrend.xyaxis")?.pngData()
        items.append(CSSearchableItem(
            uniqueIdentifier: "\(domainID).stats",
            domainIdentifier: domainID,
            attributeSet: stats
        ))

        // Achievements
        let achievements = CSSearchableItemAttributeSet(contentType: .item)
        achievements.title = "Hydration Achievements"
        achievements.contentDescription = "See your hydration trophies and streak records"
        achievements.thumbnailData = UIImage(systemName: "trophy.fill")?.pngData()
        items.append(CSSearchableItem(
            uniqueIdentifier: "\(domainID).achievements",
            domainIdentifier: domainID,
            attributeSet: achievements
        ))

        CSSearchableIndex.default().indexSearchableItems(items) { error in
            if let error {
                print("[AquaFaste] Spotlight indexing failed: \(error)")
            }
        }
    }

    /// Remove all indexed items
    static func deindexAll() {
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [domainID])
    }
}

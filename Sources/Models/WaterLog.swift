import Foundation
import SwiftData

@Model
final class WaterLog {
    var id: UUID
    var timestamp: Date
    var amount: Double          // in milliliters
    var drinkType: String       // DrinkType.rawValue
    var hydrationRatio: Double  // cached at log time
    var healthKitUUID: String?  // reference to HK sample

    /// Effective hydration in ml (amount × ratio)
    var effectiveAmount: Double {
        amount * hydrationRatio
    }

    var drink: DrinkType {
        DrinkType(rawValue: drinkType) ?? .water
    }

    init(amount: Double, drinkType: DrinkType, timestamp: Date = .now) {
        self.id = UUID()
        self.timestamp = timestamp
        self.amount = amount
        self.drinkType = drinkType.rawValue
        self.hydrationRatio = drinkType.hydrationRatio
    }
}

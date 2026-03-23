import Foundation
import SwiftData

/// A saved favorite drink preset — user-defined name + type + amount
@Model
final class FavoriteDrink {
    var id: UUID
    var name: String
    var drinkType: String        // DrinkType.rawValue
    var amount: Double           // in ml
    var caffeineAmount: Double   // mg — may differ from default
    var sortOrder: Int
    var createdAt: Date

    var drink: DrinkType {
        DrinkType(rawValue: drinkType) ?? .water
    }

    init(name: String, drinkType: DrinkType, amount: Double, caffeineAmount: Double = 0, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.drinkType = drinkType.rawValue
        self.amount = amount
        self.caffeineAmount = caffeineAmount
        self.sortOrder = sortOrder
        self.createdAt = .now
    }
}

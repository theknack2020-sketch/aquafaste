import SwiftUI

extension Color {
    // Primary cyan-blue palette
    static let aquaPrimary = Color(red: 0.04, green: 0.52, blue: 1.0)        // #0A84FF
    static let aquaSecondary = Color(red: 0.20, green: 0.83, blue: 0.87)     // #32D4DE
    static let aquaAccent = Color(red: 0.0, green: 0.79, blue: 0.86)         // #00C9DB

    // Gradient stops
    static let aquaGradientStart = Color(red: 0.0, green: 0.79, blue: 0.86)  // cyan
    static let aquaGradientEnd = Color(red: 0.0, green: 0.40, blue: 1.0)     // deep blue

    // Semantic
    static let aquaBackground = Color(.systemBackground)
    static let aquaCardBackground = Color(.secondarySystemBackground)
    static let aquaTextPrimary = Color(.label)
    static let aquaTextSecondary = Color(.secondaryLabel)

    // Drink type colors
    static let drinkWater = Color(red: 0.20, green: 0.67, blue: 1.0)
    static let drinkCoffee = Color(red: 0.55, green: 0.35, blue: 0.17)
    static let drinkTea = Color(red: 0.60, green: 0.78, blue: 0.35)
    static let drinkJuice = Color(red: 1.0, green: 0.65, blue: 0.0)
    static let drinkMilk = Color(red: 0.95, green: 0.95, blue: 0.90)
    static let drinkSoda = Color(red: 0.85, green: 0.20, blue: 0.20)
    static let drinkSparkling = Color(red: 0.70, green: 0.88, blue: 1.0)
    static let drinkSmoothie = Color(red: 0.80, green: 0.40, blue: 0.70)
    static let drinkSoup = Color(red: 0.90, green: 0.55, blue: 0.20)
    static let drinkCoconut = Color(red: 0.95, green: 0.95, blue: 0.95)
    static let drinkBeer = Color(red: 0.85, green: 0.65, blue: 0.13)
    static let drinkWine = Color(red: 0.50, green: 0.10, blue: 0.20)

    // Aqua gradient
    static var aquaGradient: LinearGradient {
        LinearGradient(
            colors: [.aquaGradientStart, .aquaGradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

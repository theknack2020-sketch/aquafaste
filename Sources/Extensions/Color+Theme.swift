import SwiftUI

// MARK: - App Theme

enum AppTheme: String, CaseIterable, Identifiable {
    case ocean
    case forest
    case berry
    case mono

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ocean: "Ocean"
        case .forest: "Forest"
        case .berry: "Berry"
        case .mono: "Mono"
        }
    }

    var iconName: String {
        switch self {
        case .ocean: "drop.fill"
        case .forest: "leaf.fill"
        case .berry: "heart.fill"
        case .mono: "circle.lefthalf.filled"
        }
    }

    // MARK: - Primary Colors

    var primary: Color {
        switch self {
        case .ocean: Color(red: 0.04, green: 0.52, blue: 1.0)          // #0A84FF
        case .forest: Color(red: 0.20, green: 0.70, blue: 0.35)         // #33B359
        case .berry: Color(red: 0.70, green: 0.22, blue: 0.55)          // #B33A8D
        case .mono: Color(red: 0.40, green: 0.40, blue: 0.42)           // #666666
        }
    }

    var secondary: Color {
        switch self {
        case .ocean: Color(red: 0.20, green: 0.83, blue: 0.87)          // #32D4DE
        case .forest: Color(red: 0.40, green: 0.82, blue: 0.50)         // #66D180
        case .berry: Color(red: 0.90, green: 0.40, blue: 0.65)          // #E666A6
        case .mono: Color(red: 0.60, green: 0.60, blue: 0.62)           // #999999
        }
    }

    var accent: Color {
        switch self {
        case .ocean: Color(red: 0.0, green: 0.79, blue: 0.86)           // #00C9DB
        case .forest: Color(red: 0.55, green: 0.85, blue: 0.25)         // #8CD940
        case .berry: Color(red: 0.95, green: 0.30, blue: 0.50)          // #F24D80
        case .mono: Color(red: 0.50, green: 0.50, blue: 0.52)           // #808080
        }
    }

    // MARK: - Gradient Stops

    var gradientStart: Color {
        switch self {
        case .ocean: Color(red: 0.0, green: 0.79, blue: 0.86)
        case .forest: Color(red: 0.30, green: 0.80, blue: 0.40)
        case .berry: Color(red: 0.85, green: 0.30, blue: 0.55)
        case .mono: Color(red: 0.50, green: 0.50, blue: 0.52)
        }
    }

    var gradientEnd: Color {
        switch self {
        case .ocean: Color(red: 0.0, green: 0.40, blue: 1.0)
        case .forest: Color(red: 0.10, green: 0.50, blue: 0.30)
        case .berry: Color(red: 0.55, green: 0.10, blue: 0.40)
        case .mono: Color(red: 0.25, green: 0.25, blue: 0.27)
        }
    }

    var gradient: LinearGradient {
        LinearGradient(
            colors: [gradientStart, gradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Preview swatch colors for theme picker
    var swatchColors: [Color] {
        [primary, secondary, accent]
    }
}

// MARK: - Theme Manager

@MainActor
final class ThemeManager {
    static let shared = ThemeManager()

    var current: AppTheme {
        guard let raw = UserDefaults.standard.string(forKey: "af_app_theme"),
              let theme = AppTheme(rawValue: raw) else {
            return .ocean
        }
        return theme
    }

    func setTheme(_ theme: AppTheme) {
        UserDefaults.standard.set(theme.rawValue, forKey: "af_app_theme")
    }

    private init() {}
}

// MARK: - Dynamic Theme Colors (resolve via current theme)

@MainActor
extension Color {
    // Primary palette — resolves to active theme
    static var aquaPrimary: Color { ThemeManager.shared.current.primary }
    static var aquaSecondary: Color { ThemeManager.shared.current.secondary }
    static var aquaAccent: Color { ThemeManager.shared.current.accent }

    // Gradient stops
    static var aquaGradientStart: Color { ThemeManager.shared.current.gradientStart }
    static var aquaGradientEnd: Color { ThemeManager.shared.current.gradientEnd }

    // Aqua gradient (dynamic)
    static var aquaGradient: LinearGradient {
        ThemeManager.shared.current.gradient
    }
}

// MARK: - Static Theme Colors (no actor isolation needed)

extension Color {
    // Semantic
    static let aquaBackground = Color(.systemBackground)
    static let aquaCardBackground = Color(.secondarySystemBackground)
    static let aquaTextPrimary = Color(.label)
    static let aquaTextSecondary = Color(.secondaryLabel)

    // Drink type colors (theme-independent)
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
}

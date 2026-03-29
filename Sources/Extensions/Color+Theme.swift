import SwiftUI

// MARK: - App Theme

enum AppTheme: String, CaseIterable, Identifiable {
    case ocean
    case forest
    case berry
    case sunset
    case aurora // Premium
    case midnight // Premium

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .ocean: "Ocean"
        case .forest: "Forest"
        case .berry: "Berry"
        case .sunset: "Sunset"
        case .aurora: "Aurora"
        case .midnight: "Midnight"
        }
    }

    var iconName: String {
        switch self {
        case .ocean: "drop.fill"
        case .forest: "leaf.fill"
        case .berry: "heart.fill"
        case .sunset: "sun.max.fill"
        case .aurora: "sparkles"
        case .midnight: "moon.stars.fill"
        }
    }

    /// Whether this theme requires Pro subscription
    var isPremium: Bool {
        switch self {
        case .aurora, .midnight: true
        default: false
        }
    }

    /// Free themes only
    static var freeThemes: [AppTheme] {
        allCases.filter { !$0.isPremium }
    }

    /// Premium-only themes
    static var premiumThemes: [AppTheme] {
        allCases.filter(\.isPremium)
    }

    // MARK: - Primary Colors

    var primary: Color {
        switch self {
        case .ocean: Color(red: 0.04, green: 0.52, blue: 1.0) // #0A84FF
        case .forest: Color(red: 0.20, green: 0.70, blue: 0.35) // #33B359
        case .berry: Color(red: 0.70, green: 0.22, blue: 0.55) // #B33A8D
        case .sunset: Color(red: 0.95, green: 0.45, blue: 0.20) // #F27333
        case .aurora: Color(red: 0.30, green: 0.85, blue: 0.75) // #4DD9BF
        case .midnight: Color(red: 0.40, green: 0.35, blue: 0.90) // #6659E6
        }
    }

    var secondary: Color {
        switch self {
        case .ocean: Color(red: 0.20, green: 0.83, blue: 0.87) // #32D4DE
        case .forest: Color(red: 0.40, green: 0.82, blue: 0.50) // #66D180
        case .berry: Color(red: 0.90, green: 0.40, blue: 0.65) // #E666A6
        case .sunset: Color(red: 1.0, green: 0.72, blue: 0.30) // #FFB84D
        case .aurora: Color(red: 0.55, green: 0.50, blue: 0.95) // #8C80F2
        case .midnight: Color(red: 0.65, green: 0.55, blue: 1.0) // #A68CFF
        }
    }

    var accent: Color {
        switch self {
        case .ocean: Color(red: 0.0, green: 0.79, blue: 0.86) // #00C9DB
        case .forest: Color(red: 0.55, green: 0.85, blue: 0.25) // #8CD940
        case .berry: Color(red: 0.95, green: 0.30, blue: 0.50) // #F24D80
        case .sunset: Color(red: 0.98, green: 0.35, blue: 0.45) // #FA5973
        case .aurora: Color(red: 0.20, green: 0.95, blue: 0.60) // #33F299
        case .midnight: Color(red: 0.85, green: 0.70, blue: 1.0) // #D9B3FF
        }
    }

    /// Tertiary color for subtle backgrounds and pill badges
    var tertiary: Color {
        switch self {
        case .ocean: Color(red: 0.85, green: 0.94, blue: 1.0)
        case .forest: Color(red: 0.88, green: 0.96, blue: 0.88)
        case .berry: Color(red: 0.96, green: 0.88, blue: 0.93)
        case .sunset: Color(red: 1.0, green: 0.93, blue: 0.88)
        case .aurora: Color(red: 0.88, green: 0.98, blue: 0.95)
        case .midnight: Color(red: 0.92, green: 0.90, blue: 1.0)
        }
    }

    // MARK: - Gradient Stops

    var gradientStart: Color {
        switch self {
        case .ocean: Color(red: 0.0, green: 0.79, blue: 0.86)
        case .forest: Color(red: 0.30, green: 0.80, blue: 0.40)
        case .berry: Color(red: 0.85, green: 0.30, blue: 0.55)
        case .sunset: Color(red: 1.0, green: 0.60, blue: 0.20)
        case .aurora: Color(red: 0.20, green: 0.90, blue: 0.70)
        case .midnight: Color(red: 0.30, green: 0.25, blue: 0.80)
        }
    }

    var gradientMid: Color {
        switch self {
        case .ocean: Color(red: 0.04, green: 0.52, blue: 1.0)
        case .forest: Color(red: 0.20, green: 0.65, blue: 0.35)
        case .berry: Color(red: 0.70, green: 0.20, blue: 0.50)
        case .sunset: Color(red: 0.95, green: 0.40, blue: 0.30)
        case .aurora: Color(red: 0.40, green: 0.70, blue: 0.90)
        case .midnight: Color(red: 0.50, green: 0.40, blue: 0.95)
        }
    }

    var gradientEnd: Color {
        switch self {
        case .ocean: Color(red: 0.0, green: 0.40, blue: 1.0)
        case .forest: Color(red: 0.10, green: 0.50, blue: 0.30)
        case .berry: Color(red: 0.55, green: 0.10, blue: 0.40)
        case .sunset: Color(red: 0.85, green: 0.15, blue: 0.30)
        case .aurora: Color(red: 0.50, green: 0.30, blue: 0.95)
        case .midnight: Color(red: 0.15, green: 0.10, blue: 0.55)
        }
    }

    // MARK: - Gradient Presets

    /// Primary diagonal gradient
    var gradient: LinearGradient {
        LinearGradient(
            colors: [gradientStart, gradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Rich 3-stop gradient for hero sections
    var heroGradient: LinearGradient {
        LinearGradient(
            colors: [gradientStart, gradientMid, gradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Vertical gradient for full-screen backgrounds (onboarding, paywall)
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [gradientStart.opacity(0.35), gradientMid.opacity(0.20), gradientEnd.opacity(0.15)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Subtle card overlay gradient
    var cardGradient: LinearGradient {
        LinearGradient(
            colors: [primary.opacity(0.12), secondary.opacity(0.06)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Radial glow for depth behind progress ring / hero elements
    var glowGradient: RadialGradient {
        RadialGradient(
            colors: [primary.opacity(0.45), primary.opacity(0.15), primary.opacity(0.0)],
            center: .center,
            startRadius: 20,
            endRadius: 220
        )
    }

    /// Onboarding page gradient — each page gets a distinct feel
    func onboardingGradient(page: Int) -> LinearGradient {
        let colors: [Color] = switch page % 3 {
        case 0: [gradientStart, gradientMid]
        case 1: [gradientMid, gradientEnd]
        default: [gradientEnd, gradientStart]
        }
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Surface & Card Colors

    /// Elevated card background (light mode: white, dark mode: elevated surface)
    var cardBackground: Color {
        Color(.secondarySystemBackground)
    }

    /// Primary surface background
    var surfaceBackground: Color {
        Color(.systemBackground)
    }

    /// Glass effect background
    var glassBackground: Color {
        switch self {
        case .midnight: Color.white.opacity(0.06)
        default: Color.white.opacity(0.80)
        }
    }

    /// Glass border color
    var glassBorder: Color {
        switch self {
        case .midnight: Color.white.opacity(0.12)
        default: Color.white.opacity(0.50)
        }
    }

    // MARK: - Shadow

    var shadowColor: Color {
        primary.opacity(0.15)
    }

    var cardShadow: Color {
        Color.black.opacity(0.06)
    }

    // MARK: - Text Colors (theme-tinted)

    var headingColor: Color {
        primary
    }

    var subtitleColor: Color {
        secondary.opacity(0.80)
    }

    // MARK: - Progress Ring

    var ringGradient: AngularGradient {
        AngularGradient(
            colors: [gradientStart, gradientMid, gradientEnd, gradientStart],
            center: .center
        )
    }

    var ringTrackColor: Color {
        primary.opacity(0.12)
    }

    // MARK: - Preview Swatch

    var swatchColors: [Color] {
        [primary, secondary, accent]
    }
}

// MARK: - Theme Manager

@Observable @MainActor
final class ThemeManager {
    static let shared = ThemeManager()

    private(set) var current: AppTheme

    var isPro: Bool {
        SubscriptionManager.shared.isPremium
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: "af_app_theme"),
           let theme = AppTheme(rawValue: raw)
        {
            current = theme
        } else {
            current = .ocean
        }
    }

    func setTheme(_ theme: AppTheme) {
        // Premium themes require Pro subscription
        guard !theme.isPremium || isPro else { return }
        current = theme
        UserDefaults.standard.set(theme.rawValue, forKey: "af_app_theme")
    }

    /// Returns the effective theme (falls back to ocean if premium expired)
    var effectiveTheme: AppTheme {
        if current.isPremium, !isPro {
            return .ocean
        }
        return current
    }
}

// MARK: - Dynamic Theme Colors (resolve via current theme)

@MainActor
extension Color {
    /// Primary palette — resolves to active theme
    static var aquaPrimary: Color {
        ThemeManager.shared.effectiveTheme.primary
    }

    static var aquaSecondary: Color {
        ThemeManager.shared.effectiveTheme.secondary
    }

    static var aquaAccent: Color {
        ThemeManager.shared.effectiveTheme.accent
    }

    static var aquaTertiary: Color {
        ThemeManager.shared.effectiveTheme.tertiary
    }

    /// Gradient stops
    static var aquaGradientStart: Color {
        ThemeManager.shared.effectiveTheme.gradientStart
    }

    static var aquaGradientEnd: Color {
        ThemeManager.shared.effectiveTheme.gradientEnd
    }

    /// Aqua gradient (dynamic)
    static var aquaGradient: LinearGradient {
        ThemeManager.shared.effectiveTheme.gradient
    }

    /// Hero gradient (3-stop)
    static var aquaHeroGradient: LinearGradient {
        ThemeManager.shared.effectiveTheme.heroGradient
    }
}

// MARK: - Static Theme Colors (no actor isolation needed)

extension Color {
    // Semantic system colors
    static let aquaBackground = Color(.systemBackground)
    static let aquaCardBackground = Color(.secondarySystemBackground)
    static let aquaGroupedBackground = Color(.systemGroupedBackground)
    static let aquaTextPrimary = Color(.label)
    static let aquaTextSecondary = Color(.secondaryLabel)
    static let aquaTextTertiary = Color(.tertiaryLabel)
    static let aquaSeparator = Color(.separator)

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

    // Achievement / streak colors
    static let streakGold = Color(red: 1.0, green: 0.78, blue: 0.20)
    static let achievementBronze = Color(red: 0.80, green: 0.52, blue: 0.25)
    static let achievementSilver = Color(red: 0.75, green: 0.75, blue: 0.78)
    static let achievementGold = Color(red: 1.0, green: 0.84, blue: 0.0)
    static let achievementPlatinum = Color(red: 0.70, green: 0.85, blue: 0.95)
}

// MARK: - View Modifiers

extension View {
    /// Applies the standard card style: rounded corners, shadow, background
    func aquaCard(theme: AppTheme = ThemeManager.shared.effectiveTheme) -> some View {
        padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(theme.cardBackground)
                    .shadow(color: theme.cardShadow, radius: 8, x: 0, y: 4)
            )
    }

    /// Applies glass morphism card style
    func aquaGlassCard(theme: AppTheme = ThemeManager.shared.effectiveTheme) -> some View {
        padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(theme.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(theme.glassBorder, lineWidth: 0.5)
                    )
                    .shadow(color: theme.cardShadow, radius: 12, x: 0, y: 6)
            )
    }

    /// Standard section header style
    func aquaSectionHeader(theme: AppTheme = ThemeManager.shared.effectiveTheme) -> some View {
        font(.system(size: 13, weight: .semibold, design: .rounded))
            .textCase(.uppercase)
            .tracking(1.2)
            .foregroundStyle(theme.primary.opacity(0.70))
    }

    /// Eyebrow pill badge (above headings)
    func aquaEyebrow(theme: AppTheme = ThemeManager.shared.effectiveTheme) -> some View {
        font(.system(size: 11, weight: .semibold, design: .rounded))
            .textCase(.uppercase)
            .tracking(1.5)
            .foregroundStyle(theme.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(theme.primary.opacity(0.10))
            )
    }

    /// Hero title style
    func aquaHeroTitle() -> some View {
        font(.system(size: 34, weight: .bold, design: .rounded))
            .foregroundStyle(.primary)
    }

    /// Gradient background for full-screen views
    func aquaBackgroundGradient(theme: AppTheme = ThemeManager.shared.effectiveTheme) -> some View {
        background(
            theme.backgroundGradient
                .ignoresSafeArea()
        )
    }

    /// Subtle gradient header area
    func aquaHeaderGradient(theme: AppTheme = ThemeManager.shared.effectiveTheme) -> some View {
        background(
            LinearGradient(
                colors: [theme.gradientStart.opacity(0.12), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

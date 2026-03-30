import AppIntents
import SwiftUI

// MARK: - Log Water Intent

struct LogWaterIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Water"
    static let description = IntentDescription("Log a drink to your hydration tracker.")
    static let openAppWhenRun = false

    @Parameter(title: "Amount (ml)", default: 250, inclusiveRange: (50, 2000))
    var amount: Int?

    @Parameter(title: "Drink Type", default: .water)
    var drinkType: DrinkTypeEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$amount) ml of \(\.$drinkType)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let actualAmount = amount ?? 250
        let manager = HydrationManager.shared
        manager.logWater(amount: Double(actualAmount), drinkType: drinkType.toDrinkType)

        let total = Int(manager.todayTotal)
        let goal = Int(UserProfile.shared.dailyGoal)
        let pct = min(100, total * 100 / max(goal, 1))

        return .result(dialog: "Logged \(actualAmount) ml \(drinkType.name). Today: \(total) ml (\(pct)%)")
    }
}

// MARK: - Check Hydration Intent

struct CheckHydrationIntent: AppIntent {
    static let title: LocalizedStringResource = "Check Hydration"
    static let description = IntentDescription("See your hydration progress for today.")
    static let openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = HydrationManager.shared
        let total = Int(manager.todayTotal)
        let goal = Int(UserProfile.shared.dailyGoal)
        let remaining = max(0, goal - total)
        let pct = min(100, total * 100 / max(goal, 1))

        if remaining == 0 {
            return .result(dialog: "You've reached your goal! \(total) ml today. 🎉")
        } else {
            return .result(dialog: "\(total) ml of \(goal) ml (\(pct)%). \(remaining) ml remaining.")
        }
    }
}

// MARK: - Drink Type Entity

enum DrinkTypeEntity: String, AppEnum {
    case water, coffee, tea, juice, milk, soda, sparklingWater, smoothie, soup

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Drink Type"

    static let caseDisplayRepresentations: [DrinkTypeEntity: DisplayRepresentation] = [
        .water: "Water",
        .coffee: "Coffee",
        .tea: "Tea",
        .juice: "Juice",
        .milk: "Milk",
        .soda: "Soda",
        .sparklingWater: "Sparkling Water",
        .smoothie: "Smoothie",
        .soup: "Soup",
    ]

    var name: String {
        switch self {
        case .water: "Water"
        case .coffee: "Coffee"
        case .tea: "Tea"
        case .juice: "Juice"
        case .milk: "Milk"
        case .soda: "Soda"
        case .sparklingWater: "Sparkling Water"
        case .smoothie: "Smoothie"
        case .soup: "Soup"
        }
    }

    var toDrinkType: DrinkType {
        DrinkType(rawValue: rawValue) ?? .water
    }
}

// MARK: - App Shortcuts Provider

struct AquaFasteShortcuts: AppShortcutsProvider {
    nonisolated(unsafe) static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogWaterIntent(),
            phrases: [
                "Log water in \(.applicationName)",
                "Drink water with \(.applicationName)",
                "Add water to \(.applicationName)"
            ],
            shortTitle: "Log Water",
            systemImageName: "drop.fill"
        )

        AppShortcut(
            intent: CheckHydrationIntent(),
            phrases: [
                "Check hydration in \(.applicationName)",
                "How much water in \(.applicationName)",
                "My water progress in \(.applicationName)",
            ],
            shortTitle: "Check Hydration",
            systemImageName: "chart.bar.fill"
        )
    }

    static let shortcutTileColor: ShortcutTileColor = .blue
}

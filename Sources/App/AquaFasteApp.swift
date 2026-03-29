import SwiftData
import SwiftUI
import TelemetryDeck
import TipKit

@main
struct AquaFasteApp: App {
    init() {
        // Register notification categories and delegate on launch
        NotificationManager.shared.registerCategories()

        // TelemetryDeck — privacy-first analytics
        let appID = ProcessInfo.processInfo.environment["TELEMETRYDECK_APP_ID"] ?? "aquafaste-default"
        TelemetryDeck.initialize(config: .init(appID: appID))

        // TipKit
        try? Tips.configure([
            .displayFrequency(.daily),
        ])
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [WaterLog.self, FavoriteDrink.self, Achievement.self])
    }
}

import SwiftUI
import SwiftData
// TODO: Add TelemetryDeck SPM package — then uncomment the import below
// import TelemetryDeck

@main
struct AquaFasteApp: App {
    init() {
        // Register notification categories and delegate on launch
        NotificationManager.shared.registerCategories()

        // TelemetryDeck — uncomment after adding SPM package
        // TelemetryDeck.initialize(config: .init(appID: ProcessInfo.processInfo.environment["TELEMETRYDECK_APP_ID"] ?? ""))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [WaterLog.self, FavoriteDrink.self, Achievement.self])
    }
}

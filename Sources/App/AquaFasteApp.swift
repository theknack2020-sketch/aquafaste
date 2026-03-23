import SwiftUI
import SwiftData

@main
struct AquaFasteApp: App {
    init() {
        // Register notification categories and delegate on launch
        NotificationManager.shared.registerCategories()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [WaterLog.self, FavoriteDrink.self])
    }
}

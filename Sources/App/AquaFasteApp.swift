import SwiftUI
import SwiftData

@main
struct AquaFasteApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [WaterLog.self])
    }
}

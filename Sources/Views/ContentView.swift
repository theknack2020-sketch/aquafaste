import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var hydrationManager = HydrationManager()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            TimerView()
                .tabItem {
                    Label("Hydrate", systemImage: "drop.fill")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "chart.bar.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(Color.aquaPrimary)
        .environment(hydrationManager)
        .onAppear {
            hydrationManager.setup(context: modelContext)
        }
    }
}

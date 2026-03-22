import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var hydrationManager = HydrationManager()
    @State private var showOnboarding = !UserProfile.shared.onboardingComplete
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView(isComplete: $showOnboarding)
                    .onChange(of: showOnboarding) { _, complete in
                        if complete {
                            showOnboarding = false
                            Task {
                                await NotificationManager.shared.scheduleReminders()
                            }
                        }
                    }
            } else {
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
            }
        }
        .environment(hydrationManager)
        .onAppear {
            hydrationManager.setup(context: modelContext)
        }
    }
}

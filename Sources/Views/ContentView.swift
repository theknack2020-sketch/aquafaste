import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var hydrationManager = HydrationManager()
    @State private var onboardingDone = UserProfile.shared.onboardingComplete
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if !onboardingDone {
                OnboardingView(isComplete: $onboardingDone)
                    .onChange(of: onboardingDone) { _, done in
                        if done {
                            Task {
                                await NotificationManager.shared.scheduleReminders()
                            }
                        }
                    }
            } else {
                mainApp
            }
        }
        .environment(hydrationManager)
        .onAppear {
            hydrationManager.setup(context: modelContext)
            // Refresh reminders on every launch
            if onboardingDone {
                Task {
                    await NotificationManager.shared.scheduleReminders()
                }
            }
        }
    }

    private var mainApp: some View {
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

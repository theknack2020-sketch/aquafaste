import SwiftUI
import SwiftData
import StoreKit

struct ContentView: View {
    @State private var hydrationManager = HydrationManager()
    @State private var onboardingDone = UserProfile.shared.onboardingComplete
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.requestReview) private var requestReview

    private let subscription = SubscriptionManager.shared

    /// Track theme changes to force view refresh
    @AppStorage("af_app_theme") private var currentTheme: String = AppTheme.ocean.rawValue

    var body: some View {
        Group {
            if !onboardingDone {
                OnboardingView(isComplete: $onboardingDone)
                    .onChange(of: onboardingDone) { _, done in
                        if done {
                            Task {
                                await NotificationManager.shared.scheduleAllNotifications()
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
            // Record first launch date (no-op if already set)
            _ = subscription.firstLaunchDate
            if onboardingDone {
                Task {
                    await NotificationManager.shared.scheduleAllNotifications()
                }
                // Rate Us prompt after 7 days of use (one-time)
                checkRatePrompt()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                // Refresh data and reschedule on foreground return
                // This also handles timezone changes — Calendar.current picks up new timezone
                hydrationManager.refreshToday()
                Task {
                    await NotificationManager.shared.checkAuthorizationStatus()
                }
            case .background:
                // Send evening summary if it's near bedtime
                checkAndSendEveningSummary()
            default:
                break
            }
        }
        // Handle "Log Water" action from notification
        .onReceive(NotificationCenter.default.publisher(for: .didTapLogWaterNotificationAction)) { _ in
            hydrationManager.logWater(amount: 250, drinkType: .water)
        }
        // Force re-render when theme changes via id
        .id(currentTheme)
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

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.xyaxis.line")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(Color.aquaPrimary)
    }

    /// Send evening summary when going to background near bedtime
    private func checkAndSendEveningSummary() {
        let profile = UserProfile.shared
        guard profile.eveningSummaryEnabled else { return }

        let hour = Calendar.current.component(.hour, from: .now)
        let summaryHour = max(0, profile.sleepStart - 1)

        // Send summary if within 1 hour of bedtime
        if hour >= summaryHour && hour <= profile.sleepStart {
            NotificationManager.shared.sendEveningSummaryNow(
                todayTotal: hydrationManager.todayTotal,
                goalAmount: profile.dailyGoal
            )
        }
    }

    /// Show rate prompt once after 7 days of use
    private func checkRatePrompt() {
        let defaults = UserDefaults.standard
        let key = "af_rate_prompted"
        guard !defaults.bool(forKey: key) else { return }

        let daysSinceInstall = Calendar.current.dateComponents(
            [.day], from: subscription.firstLaunchDate, to: .now
        ).day ?? 0

        if daysSinceInstall >= 7 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                requestReview()
                defaults.set(true, forKey: key)
            }
        }
    }
}

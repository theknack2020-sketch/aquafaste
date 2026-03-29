import SwiftUI

struct OnboardingView: View {
    @Binding var isComplete: Bool
    @State private var currentPage = 0
    @State private var weight: String = "70"
    @State private var selectedActivity: ActivityLevel = .moderate
    @State private var enableReminders = true
    @State private var showPaywall = false
    @State private var notificationGranted = false
    @State private var notificationDenied = false

    private let profile = UserProfile.shared
    private let haptics = HapticManager.shared
    private let sounds = SoundManager.shared

    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                welcomePage.tag(0)
                weightPage.tag(1)
                activityPage.tag(2)
                notificationPage.tag(3)
                readyPage.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private let totalPages = 5

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        ZStack {
            // Deep ocean gradient
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.12, blue: 0.35).opacity(0.35),
                    Color.aquaGradientStart.opacity(0.22),
                    Color.aquaBackground
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()
                    .frame(height: 20)

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.aquaGradientStart.opacity(0.2), .clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 140, height: 140)
                    Image(systemName: "drop.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.aquaGradient)
                        .shadow(color: Color.aquaGradientStart.opacity(0.4), radius: 16, x: 0, y: 4)
                }

                Text("Welcome to AquaFaste")
                    .font(.title.weight(.bold))

                Text("Your honest hydration companion.\nNo ads. No tricks. Just water.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                // Benefit highlights
                VStack(alignment: .leading, spacing: 10) {
                    benefitRow(icon: "brain.head.profile.fill", text: "Boost focus & energy by staying hydrated")
                    benefitRow(icon: "heart.fill", text: "Support heart health with consistent water intake")
                    benefitRow(icon: "sparkles", text: "Better skin, digestion & mood — backed by science")
                }
                .padding()
                .background(Color.aquaCardBackground, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)

                Spacer()

                Button("Get Started") {
                    haptics.buttonPress()
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { currentPage = 1 }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.aquaPrimary)
                .controlSize(.large)
                .accessibilityIdentifier("getStartedButton")

                pageIndicator(current: 0)
            }
            .padding()
        }
    }

    // MARK: - Page 2: Weight

    private var weightPage: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.aquaGradientStart.opacity(0.18),
                    Color.aquaGradientEnd.opacity(0.12),
                    Color.aquaBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "scalemass.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.aquaPrimary)

                Text("What's your weight?")
                    .font(.title2.weight(.bold))

                Text("Based on EFSA guidelines: ~30 ml per kg body weight")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    TextField("70", text: $weight)
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 140)

                    Text("kg")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                if let w = Double(weight), w > 0 {
                    let goal = Int(w * 35.0 * selectedActivity.multiplier)
                    VStack(spacing: 4) {
                        Text("Recommended: \(goal) ml/day")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.aquaPrimary)
                        Text("Based on \(Int(w)) kg × 30 ml/kg (EFSA)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button("Next") {
                    if let w = Double(weight), w > 0 {
                        profile.weight = w
                    }
                    haptics.buttonPress()
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { currentPage = 2 }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.aquaPrimary)
                .controlSize(.large)

                pageIndicator(current: 1)
            }
            .padding()
        }
    }

    // MARK: - Page 3: Activity

    private var activityPage: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.aquaPrimary.opacity(0.18),
                    Color.aquaGradientStart.opacity(0.12),
                    Color.aquaBackground
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "figure.run")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.aquaPrimary)

                Text("How active are you?")
                    .font(.title2.weight(.bold))

                Text("Active people lose more water through sweat\nand need up to 50% more hydration")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(spacing: 8) {
                    ForEach(ActivityLevel.allCases) { level in
                        Button {
                            haptics.selectionChanged()
                            selectedActivity = level
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(level.displayName)
                                        .font(.subheadline.weight(.medium))
                                    Text(level.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if selectedActivity == level {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.aquaPrimary)
                                }
                            }
                            .padding()
                            .background(
                                selectedActivity == level
                                    ? Color.aquaPrimary.opacity(0.1)
                                    : Color.aquaCardBackground,
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                            .foregroundStyle(Color.aquaTextPrimary)
                        }
                    }
                }

                Spacer()

                Button("Next") {
                    profile.activityLevel = selectedActivity
                    haptics.buttonPress()
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { currentPage = 3 }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.aquaPrimary)
                .controlSize(.large)

                pageIndicator(current: 2)
            }
            .padding()
        }
    }

    // MARK: - Page 4: Notifications

    private var notificationPage: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.aquaGradientEnd.opacity(0.18),
                    Color.aquaGradientStart.opacity(0.10),
                    Color.aquaBackground
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.aquaPrimary)
                    .symbolRenderingMode(.hierarchical)

                Text("Stay on Track")
                    .font(.title.weight(.bold))

                Text("People who use reminders drink 40% more water on average. Smart reminders during waking hours — never at night.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                // Benefits list
                VStack(alignment: .leading, spacing: 12) {
                    notificationBenefit(
                        icon: "clock.fill",
                        title: "Smart Timing",
                        description: "Reminders every 1-2 hours, only during waking hours"
                    )
                    notificationBenefit(
                        icon: "moon.fill",
                        title: "Quiet Hours",
                        description: "No notifications while you sleep"
                    )
                    notificationBenefit(
                        icon: "trophy.fill",
                        title: "Celebrations",
                        description: "Get notified when you hit your daily goal"
                    )
                    notificationBenefit(
                        icon: "flame.fill",
                        title: "Streak Protection",
                        description: "Reminders to keep your streak alive"
                    )
                }
                .padding()
                .background(Color.aquaCardBackground, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.aquaPrimary.opacity(0.08), radius: 8, x: 0, y: 3)

                Spacer()

                if notificationDenied {
                    // Graceful denial handling with inline guidance
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "bell.slash")
                                .foregroundStyle(.orange)
                            Text("Notifications Blocked")
                                .font(.subheadline.weight(.semibold))
                        }

                        Text("No worries! You can enable reminders anytime in\nSettings → AquaFaste → Notifications")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 12) {
                            Button("Open Settings") {
                                NotificationManager.shared.openNotificationSettings()
                            }
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.aquaPrimary)

                            Button("Continue Without") {
                                haptics.buttonPress()
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { currentPage = 4 }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.aquaCardBackground)
                            .foregroundStyle(Color.aquaTextPrimary)
                            .controlSize(.regular)
                        }
                    }
                } else if notificationGranted {
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                        Text("Reminders enabled!")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.green)
                    }

                    Button("Continue") {
                        haptics.buttonPress()
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { currentPage = 4 }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.aquaPrimary)
                    .controlSize(.large)
                } else {
                    Button("Enable Reminders") {
                        Task {
                            let granted = await NotificationManager.shared.requestAuthorization()
                            notificationGranted = granted
                            notificationDenied = !granted
                            if granted {
                                NotificationManager.shared.registerCategories()
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.aquaPrimary)
                    .controlSize(.large)
                    .accessibilityLabel("Enable hydration reminders")
                    .accessibilityIdentifier("enableRemindersButton")

                    Button("Skip for Now") {
                        haptics.buttonPress()
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { currentPage = 4 }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                pageIndicator(current: 3)
            }
            .padding()
        }
    }

    private func notificationBenefit(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.aquaPrimary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Page 5: Ready

    private var readyPage: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.aquaPrimary.opacity(0.18),
                    Color.aquaGradientStart.opacity(0.12),
                    Color.aquaBackground
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.aquaPrimary)

                Text("You're All Set!")
                    .font(.title.weight(.bold))

                let goal = profile.dailyGoal
                Text("Your daily goal: \(profile.unit.formatAmount(goal))")
                    .font(.title3)
                    .foregroundStyle(Color.aquaPrimary)

                VStack(alignment: .leading, spacing: 8) {
                    summaryRow(icon: "scalemass.fill", text: "\(Int(profile.weight)) kg")
                    summaryRow(icon: "figure.run", text: profile.activityLevel.displayName)
                    summaryRow(
                        icon: "bell.fill",
                        text: notificationGranted
                            ? "Reminders every \(profile.reminderInterval / 60) hours"
                            : "Reminders off"
                    )
                }
                .padding()
                .background(Color.aquaCardBackground, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)

                Spacer()

                Button("Start Tracking") {
                    haptics.goalComplete()
                    sounds.playCelebration()
                    profile.onboardingComplete = true
                    Task {
                        let hkAuthorized = await HealthKitManager.shared.requestAuthorization()
                        if !hkAuthorized {
                            print("[AquaFaste] HealthKit not authorized — continuing without sync")
                        }
                        await NotificationManager.shared.scheduleAllNotifications()
                    }
                    isComplete = true
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.aquaPrimary)
                .controlSize(.large)
                .accessibilityLabel("Start tracking your daily hydration")
                .accessibilityIdentifier("startTrackingButton")

                Button("Try Premium Free") {
                    showPaywall = true
                }
                .font(.subheadline)
                .foregroundStyle(Color.aquaPrimary)
                .accessibilityLabel("Try premium features free")
                .accessibilityHint("Opens premium subscription options")
                .accessibilityIdentifier("onboardingTryPremiumButton")

                pageIndicator(current: 4)
            }
            .padding()
        }
    }

    // MARK: - Helpers

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.aquaPrimary)
                .frame(width: 28)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.aquaTextPrimary)
        }
    }

    private func summaryRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.aquaPrimary)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }

    private func pageIndicator(current: Int) -> some View {
        HStack(spacing: 6) {
            ForEach(0 ..< totalPages, id: \.self) { i in
                Circle()
                    .fill(i == current ? Color.aquaPrimary : Color.aquaPrimary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.bottom, 8)
        .accessibilityLabel("Page \(current + 1) of \(totalPages)")
    }
}

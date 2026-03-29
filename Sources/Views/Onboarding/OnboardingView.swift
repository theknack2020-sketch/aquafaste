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
            // Rich ambient background
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.02, green: 0.10, blue: 0.30),
                        Color(red: 0.04, green: 0.20, blue: 0.45),
                        Color(red: 0.08, green: 0.30, blue: 0.55)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Glow orbs
                Circle()
                    .fill(RadialGradient(colors: [Color.cyan.opacity(0.3), .clear], center: .center, startRadius: 10, endRadius: 160))
                    .frame(width: 320, height: 320)
                    .offset(x: -80, y: -180)
                    .blur(radius: 50)

                Circle()
                    .fill(RadialGradient(colors: [Color.blue.opacity(0.25), .clear], center: .center, startRadius: 10, endRadius: 140))
                    .frame(width: 280, height: 280)
                    .offset(x: 100, y: 200)
                    .blur(radius: 60)
            }

            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 20)

                // Premium glow icon
                ZStack {
                    ForEach(0..<3, id: \.self) { ring in
                        Circle()
                            .stroke(Color.cyan.opacity(0.12 - Double(ring) * 0.03), lineWidth: 1.5)
                            .frame(width: CGFloat(90 + ring * 30), height: CGFloat(90 + ring * 30))
                    }

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.cyan.opacity(0.2), Color.blue.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)

                    Image(systemName: "drop.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(
                            LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom)
                        )
                        .shadow(color: .cyan.opacity(0.5), radius: 16, y: 4)
                }

                Text("Welcome to AquaFaste")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Your honest hydration companion.\nNo ads. No tricks. Just water.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)

                // Benefit highlights
                VStack(alignment: .leading, spacing: 10) {
                    benefitRow(icon: "brain.head.profile.fill", text: "Boost focus & energy by staying hydrated")
                    benefitRow(icon: "heart.fill", text: "Support heart health with consistent water intake")
                    benefitRow(icon: "sparkles", text: "Better skin, digestion & mood — backed by science")
                }
                .padding()
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.white.opacity(0.1), lineWidth: 0.5)
                )

                Spacer()

                // Premium CTA button
                Button {
                    haptics.buttonPress()
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { currentPage = 1 }
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: [.cyan, .blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                }
                .shadow(color: .cyan.opacity(0.4), radius: 12, y: 6)
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
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.08), lineWidth: 0.5))
                .shadow(color: Color.aquaPrimary.opacity(0.1), radius: 10, y: 4)

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
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.08), lineWidth: 0.5))
                .shadow(color: Color.black.opacity(0.08), radius: 10, y: 4)

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

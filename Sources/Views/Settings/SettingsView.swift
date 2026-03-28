import SwiftUI

struct SettingsView: View {
    private let profile = UserProfile.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @Environment(HydrationManager.self) private var manager
    @State private var selectedUnit: MeasurementUnit = UserProfile.shared.unit
    @State private var customGoal: String = ""
    @State private var showGoalEditor = false
    @State private var showCupEditor = false

    // Cup editing
    @State private var editingCups: [(name: String, size: Double)] = []

    private let haptics = HapticManager.shared
    private let sounds = SoundManager.shared

    // Theme
    @AppStorage("af_app_theme") private var selectedThemeRaw: String = AppTheme.ocean.rawValue
    private var selectedTheme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .ocean
    }

    // Pro gate
    @State private var showPaywall = false
    private let subscription = SubscriptionManager.shared

    // Notification setting states (synced from profile)
    @State private var remindersEnabled: Bool = UserProfile.shared.remindersEnabled
    @State private var morningReminderEnabled: Bool = UserProfile.shared.morningReminderEnabled
    @State private var eveningSummaryEnabled: Bool = UserProfile.shared.eveningSummaryEnabled
    @State private var goalCelebrationEnabled: Bool = UserProfile.shared.goalCelebrationEnabled
    @State private var streakReminderEnabled: Bool = UserProfile.shared.streakReminderEnabled
    @State private var reminderInterval: Int = UserProfile.shared.reminderInterval
    @State private var sleepStart: Int = UserProfile.shared.sleepStart
    @State private var sleepEnd: Int = UserProfile.shared.sleepEnd

    // Refill reminder
    @State private var refillReminderEnabled: Bool = UserProfile.shared.refillReminderEnabled
    @State private var bottleSize: Double = UserProfile.shared.bottleSize

    // Export
    @State private var showExportSheet = false
    @State private var exportURL: URL?
    @State private var showShareApp = false

    // Reset
    @State private var showResetConfirmation = false
    @State private var showResetSuccess = false

    // Email
    @State private var showMailError = false

    var body: some View {
        NavigationStack {
            List {
                appHeaderSection
                themeSection
                profileSection
                hydrationSection
                cupSizeSection
                refillReminderSection
                notificationSection
                exportSection
                moreAppsSection
                aboutSection
                dangerZoneSection
            }
            .navigationTitle("Settings")
            .scrollContentBackground(.hidden)
            .background(
                LinearGradient(
                    colors: [
                        Color.aquaGradientStart.opacity(0.25),
                        Color.aquaBackground,
                        Color.aquaBackground
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()
            )
            .alert("Custom Goal", isPresented: $showGoalEditor) {
                TextField(profile.unit == .ml ? "ml" : "fl oz", text: $customGoal)
                    .keyboardType(.numberPad)
                Button("Set") {
                    if let value = Double(customGoal), value > 0 {
                        profile.dailyGoalOverride = profile.unit.toMl(value)
                    }
                    customGoal = ""
                }
                Button("Reset to Auto", role: .destructive) {
                    profile.dailyGoalOverride = nil
                }
                Button("Cancel", role: .cancel) { customGoal = "" }
            } message: {
                Text("Auto: \(profile.unit.formatAmount(profile.weight * 35.0 * profile.activityLevel.multiplier))")
            }
            .sheet(isPresented: $showCupEditor) {
                CupSizeEditor(
                    cups: $editingCups,
                    unit: profile.unit,
                    onSave: {
                        profile.cupPresets = editingCups.map(\.size)
                        profile.cupPresetNames = editingCups.map(\.name)
                        showCupEditor = false
                    }
                )
            }
            .task {
                await notificationManager.checkAuthorizationStatus()
            }
            .alert("Cannot Send Email", isPresented: $showMailError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("No email account is configured on this device. Please email support@theknack.app from your email client.")
            }
            .alert("Data Reset Complete", isPresented: $showResetSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("All hydration data and settings have been reset to defaults.")
            }
            .alert(manager.errorTitle, isPresented: .init(
                get: { manager.showError },
                set: { manager.showError = $0 }
            )) {
                Button("OK") { }
            } message: {
                Text(manager.errorMessage)
            }
            .confirmationDialog(
                "Reset All Data?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete All Data", role: .destructive) {
                    performDataReset()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all your hydration logs, streak data, and settings. This action cannot be undone.")
            }
            .sheet(isPresented: $showExportSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    // MARK: - App Header

    private var appHeaderSection: some View {
        Section {
            HStack(spacing: 14) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.aquaGradient)
                    .frame(width: 60, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [Color.aquaGradientStart.opacity(0.15), Color.aquaGradientEnd.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(color: Color.aquaPrimary.opacity(0.15), radius: 8, x: 0, y: 3)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("AquaFaste")
                        .font(.title3.weight(.bold))
                    Text("Hydration Tracker")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Version \(appVersionString)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("AquaFaste Hydration Tracker, Version \(appVersionString)")
            }
            .padding(.vertical, 4)
            .listRowBackground(Color.clear)
        }
    }

    // MARK: - Theme Section

    private var themeSection: some View {
        Section {
            ForEach(AppTheme.allCases) { theme in
                let isLocked = theme.isPremium && !subscription.isPro
                Button {
                    if isLocked {
                        haptics.light()
                        showPaywall = true
                    } else {
                        haptics.selectionChanged()
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedThemeRaw = theme.rawValue
                            ThemeManager.shared.setTheme(theme)
                        }
                    }
                } label: {
                    HStack(spacing: 12) {
                        HStack(spacing: 0) {
                            ForEach(theme.swatchColors.indices, id: \.self) { i in
                                Rectangle()
                                    .fill(theme.swatchColors[i])
                                    .frame(width: 12, height: 28)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(color: theme.primary.opacity(0.2), radius: 3, x: 0, y: 1)
                        .overlay {
                            if isLocked {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.black.opacity(0.3))
                                Image(systemName: "lock.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.white)
                            }
                        }
                        .accessibilityHidden(true)

                        Image(systemName: theme.iconName)
                            .foregroundStyle(isLocked ? Color(.tertiaryLabel) : theme.primary)
                            .frame(width: 20)
                            .accessibilityHidden(true)

                        Text(theme.displayName)
                            .foregroundStyle(isLocked ? Color(.tertiaryLabel) : Color.aquaTextPrimary)

                        if isLocked {
                            Text("PRO")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange, in: Capsule())
                                .foregroundStyle(.white)
                        }

                        Spacer()

                        if selectedTheme == theme && !isLocked {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(theme.primary)
                                .accessibilityLabel("Selected")
                        } else if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(Color(.tertiaryLabel))
                        }
                    }
                }
                .accessibilityLabel("\(theme.displayName) theme\(isLocked ? ", requires Pro" : "")")
                .accessibilityAddTraits(selectedTheme == theme && !isLocked ? [.isSelected] : [])
                .accessibilityHint(isLocked ? "Double tap to see Pro plans" : (selectedTheme == theme ? "Currently active" : "Double tap to activate"))
            }
        } header: {
            Label("Theme", systemImage: "paintpalette.fill")
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        Section("Profile") {
            HStack {
                Label("Weight", systemImage: "scalemass.fill")
                Spacer()
                Text("\(Int(profile.weight)) kg")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label("Activity", systemImage: "figure.run")
                Spacer()
                Text(profile.activityLevel.displayName)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Hydration Section

    private var hydrationSection: some View {
        Section("Hydration") {
            HStack {
                Label("Daily Goal", systemImage: "target")
                Spacer()
                Button(profile.unit.formatAmount(profile.dailyGoal)) {
                    showGoalEditor = true
                }
                .foregroundStyle(Color.aquaPrimary)
            }

            Picker(selection: $selectedUnit) {
                ForEach(MeasurementUnit.allCases, id: \.self) { unit in
                    Text(unit.displayName).tag(unit)
                }
            } label: {
                Label("Units", systemImage: "ruler")
            }
            .onChange(of: selectedUnit) { _, newValue in
                profile.unit = newValue
            }

            HStack {
                Label("Streak", systemImage: "flame.fill")
                Spacer()
                Text("\(profile.currentStreak) days")
                    .foregroundStyle(.orange)
            }
        }
    }

    // MARK: - Cup Size Section

    private var cupSizeSection: some View {
        Section {
            ForEach(Array(zip(profile.cupPresets.indices, profile.cupPresets)), id: \.0) { index, size in
                let name = index < profile.cupPresetNames.count ? profile.cupPresetNames[index] : "Cup \(index + 1)"
                HStack {
                    Image(systemName: "cup.and.saucer.fill")
                        .foregroundStyle(Color.aquaPrimary)
                    Text(name)
                    Spacer()
                    Text(profile.unit.formatAmount(size))
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                haptics.buttonPress()
                editingCups = zip(profile.cupPresetNames, profile.cupPresets).map { (name: $0.0, size: $0.1) }
                // Pad if needed
                while editingCups.count < profile.cupPresets.count {
                    let idx = editingCups.count
                    editingCups.append((name: "Cup \(idx + 1)", size: profile.cupPresets[idx]))
                }
                showCupEditor = true
            } label: {
                Label("Customize Cup Sizes", systemImage: "pencil")
                    .foregroundStyle(Color.aquaPrimary)
            }
        } header: {
            Text("Cup Sizes")
        } footer: {
            Text("These are your quick-add buttons on the main screen.")
        }
    }

    // MARK: - Refill Reminder Section

    private var refillReminderSection: some View {
        Section {
            Toggle(isOn: $refillReminderEnabled) {
                Label("Refill Reminder", systemImage: "arrow.triangle.2.circlepath")
            }
            .tint(Color.aquaPrimary)
            .accessibilityLabel("Refill reminder")
            .accessibilityValue(refillReminderEnabled ? "On" : "Off")
            .accessibilityHint("Reminds you when your bottle is empty")
            .accessibilityIdentifier("refillReminderToggle")
            .onChange(of: refillReminderEnabled) { _, newValue in
                haptics.toggleChanged()
                profile.refillReminderEnabled = newValue
            }

            if refillReminderEnabled {
                HStack {
                    Label("Bottle Size", systemImage: "waterbottle.fill")
                    Spacer()
                    Picker("", selection: $bottleSize) {
                        Text("350 ml").tag(350.0)
                        Text("500 ml").tag(500.0)
                        Text("750 ml").tag(750.0)
                        Text("1000 ml").tag(1000.0)
                    }
                    .onChange(of: bottleSize) { _, newValue in
                        haptics.sliderChanged()
                        profile.bottleSize = newValue
                    }
                }
            }
        } header: {
            Text("Refill Reminder")
        } footer: {
            if refillReminderEnabled {
                Text("You'll get a reminder to refill every time you finish a bottle's worth of water.")
            }
        }
    }

    // MARK: - Notification Section

    private var notificationSection: some View {
        Section {
            // Permission status banner
            if notificationManager.authStatus == .denied {
                notificationDeniedBanner
            }

            // Master toggle
            Toggle(isOn: $remindersEnabled) {
                Label("Drink Reminders", systemImage: "bell.fill")
            }
            .tint(Color.aquaPrimary)
            .accessibilityLabel("Drink reminders")
            .accessibilityValue(remindersEnabled ? "On" : "Off")
            .accessibilityHint("Sends periodic reminders to drink water")
            .accessibilityIdentifier("drinkRemindersToggle")
            .onChange(of: remindersEnabled) { _, newValue in
                haptics.toggleChanged()
                profile.remindersEnabled = newValue
                rescheduleNotifications()
            }

            if remindersEnabled {
                // Interval picker
                Picker(selection: $reminderInterval) {
                    Text("Every 1 hour").tag(60)
                    Text("Every 1.5 hours").tag(90)
                    Text("Every 2 hours").tag(120)
                    Text("Every 3 hours").tag(180)
                } label: {
                    Label("Reminder Interval", systemImage: "clock.fill")
                }
                .onChange(of: reminderInterval) { _, newValue in
                    profile.reminderInterval = newValue
                    rescheduleNotifications()
                }
            }

            // Quiet hours
            HStack {
                Label("Quiet Hours", systemImage: "moon.fill")
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(formatHour(sleepStart)) – \(formatHour(sleepEnd))")
                    .foregroundStyle(.secondary)
            }

            // Sleep start picker
            Picker(selection: $sleepStart) {
                ForEach(19..<25, id: \.self) { hour in
                    Text(formatHour(hour % 24)).tag(hour % 24)
                }
            } label: {
                HStack {
                    Text("Bedtime")
                    Text("(no reminders after)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .onChange(of: sleepStart) { _, newValue in
                profile.sleepStart = newValue
                rescheduleNotifications()
            }

            // Sleep end picker
            Picker(selection: $sleepEnd) {
                ForEach(5..<11, id: \.self) { hour in
                    Text(formatHour(hour)).tag(hour)
                }
            } label: {
                HStack {
                    Text("Wake Up")
                    Text("(reminders start)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .onChange(of: sleepEnd) { _, newValue in
                profile.sleepEnd = newValue
                rescheduleNotifications()
            }

            // Individual notification type toggles
            Toggle(isOn: $morningReminderEnabled) {
                Label("Morning Reminder", systemImage: "sunrise.fill")
            }
            .tint(Color.aquaPrimary)
            .accessibilityLabel("Morning reminder")
            .accessibilityValue(morningReminderEnabled ? "On" : "Off")
            .accessibilityIdentifier("morningReminderToggle")
            .onChange(of: morningReminderEnabled) { _, newValue in
                haptics.toggleChanged()
                profile.morningReminderEnabled = newValue
                rescheduleNotifications()
            }

            Toggle(isOn: $eveningSummaryEnabled) {
                Label("Evening Summary", systemImage: "moon.stars.fill")
            }
            .tint(Color.aquaPrimary)
            .accessibilityLabel("Evening summary notification")
            .accessibilityValue(eveningSummaryEnabled ? "On" : "Off")
            .accessibilityIdentifier("eveningSummaryToggle")
            .onChange(of: eveningSummaryEnabled) { _, newValue in
                haptics.toggleChanged()
                profile.eveningSummaryEnabled = newValue
                rescheduleNotifications()
            }

            Toggle(isOn: $goalCelebrationEnabled) {
                Label("Goal Celebration", systemImage: "party.popper.fill")
            }
            .tint(Color.aquaPrimary)
            .accessibilityLabel("Goal celebration notification")
            .accessibilityValue(goalCelebrationEnabled ? "On" : "Off")
            .accessibilityIdentifier("goalCelebrationToggle")
            .onChange(of: goalCelebrationEnabled) { _, newValue in
                haptics.toggleChanged()
                profile.goalCelebrationEnabled = newValue
            }

            Toggle(isOn: $streakReminderEnabled) {
                Label("Streak Reminder", systemImage: "flame.fill")
            }
            .tint(Color.aquaPrimary)
            .accessibilityLabel("Streak reminder notification")
            .accessibilityValue(streakReminderEnabled ? "On" : "Off")
            .accessibilityIdentifier("streakReminderToggle")
            .onChange(of: streakReminderEnabled) { _, newValue in
                haptics.toggleChanged()
                profile.streakReminderEnabled = newValue
                rescheduleNotifications()
            }

            Toggle(isOn: Binding(
                get: { sounds.soundEnabled },
                set: { sounds.soundEnabled = $0 }
            )) {
                Label("Sound Effects", systemImage: "speaker.wave.2.fill")
            }
            .tint(Color.aquaPrimary)
            .accessibilityLabel("Sound effects")
            .accessibilityValue(sounds.soundEnabled ? "On" : "Off")
            .accessibilityIdentifier("soundEffectsToggle")
            .onChange(of: sounds.soundEnabled) { _, _ in
                haptics.toggleChanged()
            }
        } header: {
            Text("Notifications")
        } footer: {
            if remindersEnabled && notificationManager.authStatus == .authorized {
                Text("Smart timing: reminders are suppressed for 30 minutes after you log a drink.")
            }
        }
    }

    // MARK: - Notification Denied Banner

    private var notificationDeniedBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Notifications Disabled")
                    .font(.subheadline.weight(.semibold))
            }

            Text("Hydration reminders need notification permission. Open Settings to enable them.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                notificationManager.openNotificationSettings()
            } label: {
                HStack(spacing: 4) {
                    Text("Open Settings")
                        .font(.caption.weight(.medium))
                    Image(systemName: "arrow.up.forward.app.fill")
                        .font(.caption2)
                }
            }
            .foregroundStyle(Color.aquaPrimary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Export Section

    private var exportSection: some View {
        Section {
            Button {
                haptics.buttonPress()
                if subscription.isPro {
                    exportCSV()
                } else {
                    haptics.light()
                    showPaywall = true
                }
            } label: {
                HStack {
                    Label("Export History as CSV", systemImage: "square.and.arrow.up")
                    Spacer()
                    if !subscription.isPro {
                        Text("PRO")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange, in: Capsule())
                            .foregroundStyle(.white)
                    }
                }
            }
            .accessibilityLabel("Export hydration history as CSV file\(subscription.isPro ? "" : ", requires Pro")")
            .accessibilityHint(subscription.isPro ? "Creates a CSV file of all your hydration logs for sharing or backup" : "Double tap to see Pro plans")
            .accessibilityIdentifier("exportCSVButton")
        } header: {
            Text("Data")
        }
    }

    // MARK: - More Apps Section

    private var moreAppsSection: some View {
        Section("More Apps") {
            Button {
                if let url = URL(string: "https://apps.apple.com/app/lumifaste/id6760971357") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "leaf.fill")
                        .font(.title3)
                        .foregroundStyle(.purple)
                        .frame(width: 32)

                    VStack(alignment: .leading) {
                        Text("Lumifaste")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        Text("Intermittent Fasting Tracker")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "arrow.up.forward.app.fill")
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityLabel("Lumifaste, Intermittent Fasting Tracker. Opens App Store.")
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section("About") {
            // Share App
            Button {
                haptics.buttonPress()
                showShareApp = true
            } label: {
                Label("Share AquaFaste", systemImage: "square.and.arrow.up")
            }
            .accessibilityLabel("Share AquaFaste with friends")
            .accessibilityHint("Opens share sheet with app link")

            // Rate App
            Button {
                haptics.buttonPress()
                if let url = URL(string: "https://apps.apple.com/app/aquafaste/id6743434938?action=write-review") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Rate AquaFaste", systemImage: "star.fill")
            }
            .accessibilityLabel("Rate AquaFaste on the App Store")
            .accessibilityHint("Opens App Store review page")

            // Contact Support
            Button {
                haptics.buttonPress()
                sendSupportEmail()
            } label: {
                Label("Contact Support", systemImage: "envelope.fill")
            }
            .accessibilityLabel("Contact support via email")
            .accessibilityHint("Opens email to support@theknack.app")

            Link(destination: URL(string: "https://theknack2020-sketch.github.io/aquafaste/privacy/")!) {
                Label("Privacy Policy", systemImage: "hand.raised.fill")
            }
            .accessibilityLabel("Privacy Policy")
            .accessibilityHint("Opens privacy policy in browser")

            Link(destination: URL(string: "https://theknack2020-sketch.github.io/aquafaste/terms/")!) {
                Label("Terms of Use", systemImage: "doc.text.fill")
            }
            .accessibilityLabel("Terms of Use")
            .accessibilityHint("Opens terms of use in browser")

            // Version info
            HStack {
                Label("Version", systemImage: "info.circle")
                Spacer()
                Text(appVersionString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Version \(appVersionString)")

            // Health Disclaimer
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "heart.text.square.fill")
                        .foregroundStyle(.red)
                    Text("Health Disclaimer")
                        .font(.subheadline.weight(.medium))
                }

                Text("AquaFaste provides general hydration guidance and is not a substitute for professional medical advice. Consult your healthcare provider for personalized hydration recommendations, especially if you have kidney, heart, or other medical conditions.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 4)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Health Disclaimer. AquaFaste provides general hydration guidance and is not a substitute for professional medical advice.")
        }
        .sheet(isPresented: $showShareApp) {
            let shareText = "Stay hydrated with AquaFaste! 💧 Track your daily water intake and build healthy habits."
            let appURL = URL(string: "https://apps.apple.com/app/aquafaste/id6743434938")!
            ShareSheet(items: [shareText, appURL])
        }
    }

    // MARK: - Danger Zone

    private var dangerZoneSection: some View {
        Section {
            Button(role: .destructive) {
                haptics.buttonPress()
                showResetConfirmation = true
            } label: {
                Label("Reset All Data", systemImage: "trash.fill")
                    .foregroundStyle(.red)
            }
            .accessibilityLabel("Reset all data")
            .accessibilityHint("Permanently deletes all hydration logs, streak data, and settings. Requires confirmation.")
        } header: {
            Text("Danger Zone")
        } footer: {
            Text("This will permanently delete all your hydration data and reset settings to defaults.")
        }
    }

    // MARK: - Helpers

    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func rescheduleNotifications() {
        Task {
            await notificationManager.scheduleAllNotifications()
        }
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let calendar = Calendar.current
        let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: .now) ?? .now
        return formatter.string(from: date)
    }

    private func exportCSV() {
        let logs = manager.allLogs()
        guard !logs.isEmpty else { return }

        let csv = CSVExporter.generateCSV(from: logs, unit: profile.unit)
        if let url = CSVExporter.createTempFile(csv: csv) {
            exportURL = url
            showExportSheet = true
        }
    }

    private func sendSupportEmail() {
        let email = "support@theknack.app"
        let subject = "AquaFaste Support"
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        let body = "App Version: \(version) (\(build))\niOS Version: \(UIDevice.current.systemVersion)\nDevice: \(UIDevice.current.model)"

        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? subject
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? body

        if let url = URL(string: "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                showMailError = true
            }
        }
    }

    private func performDataReset() {
        let keys = [
            "af_weight", "af_activity", "af_unit", "af_onboarding_complete",
            "af_reminder_interval", "af_sleep_start", "af_sleep_end",
            "af_goal_override", "af_streak", "af_last_goal_date", "af_cups",
            "af_reminders_enabled", "af_morning_reminder", "af_evening_summary",
            "af_goal_celebration", "af_streak_reminder", "af_app_theme",
            "af_first_launch", "af_cup_names", "af_refill_reminder", "af_bottle_size"
        ]
        let defaults = UserDefaults.standard
        for key in keys {
            defaults.removeObject(forKey: key)
        }

        manager.deleteAllLogs()
        NotificationManager.shared.cancelAll()

        selectedUnit = .ml
        remindersEnabled = true
        morningReminderEnabled = true
        eveningSummaryEnabled = true
        goalCelebrationEnabled = true
        streakReminderEnabled = true
        reminderInterval = 120
        sleepStart = 22
        sleepEnd = 7
        selectedThemeRaw = AppTheme.ocean.rawValue
        refillReminderEnabled = false

        showResetSuccess = true
    }
}

// MARK: - Cup Size Editor

struct CupSizeEditor: View {
    @Binding var cups: [(name: String, size: Double)]
    let unit: MeasurementUnit
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(cups.indices, id: \.self) { index in
                    HStack(spacing: 12) {
                        Image(systemName: "cup.and.saucer.fill")
                            .foregroundStyle(Color.aquaPrimary)

                        TextField("Name", text: Binding(
                            get: { cups[index].name },
                            set: { cups[index].name = $0 }
                        ))

                        TextField(unit == .ml ? "ml" : "fl oz", value: Binding(
                            get: { unit.fromMl(cups[index].size) },
                            set: { cups[index].size = unit.toMl($0) }
                        ), format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 70)

                        Text(unit.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete { indexSet in
                    cups.remove(atOffsets: indexSet)
                }

                Button {
                    cups.append((name: "New", size: 250))
                } label: {
                    Label("Add Cup Size", systemImage: "plus")
                }
            }
            .navigationTitle("Cup Sizes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { onSave() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Share Sheet (UIKit bridge)

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

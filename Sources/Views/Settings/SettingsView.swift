import SwiftUI

struct SettingsView: View {
    private let profile = UserProfile.shared
    @State private var selectedUnit: MeasurementUnit = UserProfile.shared.unit
    @State private var customGoal: String = ""
    @State private var showGoalEditor = false

    var body: some View {
        NavigationStack {
            List {
                // Profile
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

                // Hydration
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

                // Reminders (stub for S04)
                Section("Reminders") {
                    HStack {
                        Label("Interval", systemImage: "bell.fill")
                        Spacer()
                        Text("Every \(profile.reminderInterval / 60)h")
                            .foregroundStyle(.secondary)
                    }
                }

                // Ecosystem
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
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    Link("Privacy Policy", destination: URL(string: "https://theknack2020-sketch.github.io/aquafaste/privacy/")!)
                    Link("Support", destination: URL(string: "https://theknack2020-sketch.github.io/aquafaste/support/")!)
                    Link("Terms of Use", destination: URL(string: "https://theknack2020-sketch.github.io/aquafaste/terms/")!)
                }
            }
            .navigationTitle("Settings")
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
        }
    }
}

import SwiftUI

struct TimerView: View {
    @Environment(HydrationManager.self) private var manager
    @State private var selectedDrink: DrinkType = .water
    @State private var showDrinkPicker = false
    @State private var showCustomAmount = false
    @State private var customAmount: String = ""
    @State private var animateProgress = false
    @State private var showGoalComplete = false
    @State private var showPaywall = false

    private let profile = UserProfile.shared
    private let subscription = SubscriptionManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Progress circle
                    CircularProgressView(
                        progress: manager.progress,
                        currentAmount: manager.todayTotal,
                        goalAmount: profile.dailyGoal,
                        unit: profile.unit
                    )
                    .frame(height: 300)
                    .padding(.top, 8)

                    // Selected drink indicator
                    Button {
                        showDrinkPicker = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: selectedDrink.iconName)
                                .foregroundStyle(selectedDrink.color)
                            Text(selectedDrink.displayName)
                                .foregroundStyle(Color.aquaTextPrimary)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundStyle(Color.aquaTextSecondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.aquaCardBackground, in: Capsule())
                    }

                    // Quick add buttons
                    HStack(spacing: 12) {
                        ForEach(profile.cupPresets, id: \.self) { amount in
                            QuickAddButton(amount: amount, unit: profile.unit) {
                                logDrink(amount: amount)
                            }
                        }

                        // Custom amount button
                        Button {
                            showCustomAmount = true
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.title2)
                                Text("Custom")
                                    .font(.caption2)
                            }
                            .frame(width: 72, height: 72)
                            .foregroundStyle(Color.aquaPrimary)
                            .background(Color.aquaCardBackground, in: RoundedRectangle(cornerRadius: 16))
                        }
                    }

                    // Streak
                    if profile.currentStreak > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                            Text("\(profile.currentStreak) day streak")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.aquaTextSecondary)
                        }
                        .padding(.top, 4)
                    }

                    // Today's log
                    if !manager.todayLogs.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Today's Log")
                                .font(.headline)
                                .foregroundStyle(Color.aquaTextPrimary)
                                .padding(.horizontal)

                            ForEach(manager.todayLogs, id: \.id) { log in
                                LogRow(log: log, unit: profile.unit)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            manager.deleteLog(log)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                .padding()
            }
            .navigationTitle("AquaFaste")
            .sheet(isPresented: $showDrinkPicker) {
                DrinkPickerView(selectedDrink: $selectedDrink)
                    .presentationDetents([.medium])
            }
            .alert("Custom Amount", isPresented: $showCustomAmount) {
                TextField(profile.unit == .ml ? "ml" : "fl oz", text: $customAmount)
                    .keyboardType(.numberPad)
                Button("Add") {
                    if let value = Double(customAmount), value > 0 {
                        let ml = profile.unit.toMl(value)
                        logDrink(amount: ml)
                    }
                    customAmount = ""
                }
                Button("Cancel", role: .cancel) { customAmount = "" }
            }
            .overlay {
                if showGoalComplete {
                    GoalCompleteOverlay {
                        withAnimation { showGoalComplete = false }
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private func logDrink(amount: Double) {
        let wasUnderGoal = manager.todayTotal < profile.dailyGoal
        manager.logWater(amount: amount, drinkType: selectedDrink)

        // Haptic
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Goal complete celebration
        if wasUnderGoal && manager.todayTotal >= profile.dailyGoal {
            let notif = UINotificationFeedbackGenerator()
            notif.notificationOccurred(.success)
            withAnimation(.spring(response: 0.5)) {
                showGoalComplete = true
            }
        }
    }
}

// MARK: - Quick Add Button

struct QuickAddButton: View {
    let amount: Double
    let unit: MeasurementUnit
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: "drop.fill")
                    .font(.title2)
                Text(unit.formatAmount(amount))
                    .font(.caption2.weight(.medium))
            }
            .frame(width: 72, height: 72)
            .foregroundStyle(.white)
            .background(Color.aquaGradient, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Log Row

struct LogRow: View {
    let log: WaterLog
    let unit: MeasurementUnit

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: log.drink.iconName)
                .font(.title3)
                .foregroundStyle(log.drink.color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(log.drink.displayName)
                    .font(.subheadline.weight(.medium))
                Text(log.timestamp, format: .dateTime.hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(unit.formatAmount(log.amount))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.aquaPrimary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Goal Complete Overlay

struct GoalCompleteOverlay: View {
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.green)

                Text("Goal Complete! 💧")
                    .font(.title2.weight(.bold))

                Text("You've reached your daily hydration goal.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button("Great!", action: onDismiss)
                    .buttonStyle(.borderedProminent)
                    .tint(Color.aquaPrimary)
                    .padding(.top, 8)
            }
            .padding(32)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
            .padding(40)
        }
    }
}

import SwiftUI
import Charts

struct HistoryView: View {
    @Environment(HydrationManager.self) private var manager
    @Environment(\.modelContext) private var modelContext
    private let profile = UserProfile.shared

    private let haptics = HapticManager.shared

    @State private var editingLog: WaterLog?
    @State private var editAmount: String = ""
    @State private var editDrinkType: DrinkType = .water
    @State private var showEditSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if manager.todayLogs.isEmpty && manager.logsForDate(Calendar.current.date(byAdding: .day, value: -1, to: .now)!).isEmpty && manager.logsForDate(Calendar.current.date(byAdding: .day, value: -2, to: .now)!).isEmpty && profile.currentStreak == 0 {
                    // Empty state
                    VStack(spacing: 20) {
                        Spacer()

                        ZStack {
                            Circle()
                                .fill(Color.aquaPrimary.opacity(0.08))
                                .frame(width: 120, height: 120)
                            Image(systemName: "drop.circle")
                                .font(.system(size: 56))
                                .foregroundStyle(Color.aquaPrimary.opacity(0.4))
                                .symbolRenderingMode(.hierarchical)
                        }

                        VStack(spacing: 8) {
                            Text("No History Yet")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(Color.aquaTextPrimary)
                            Text("Log your first drink to see history")
                                .font(.subheadline)
                                .foregroundStyle(Color.aquaTextSecondary)
                            Text("Your daily logs, streaks, and weekly charts\nwill appear here.")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .multilineTextAlignment(.center)
                                .padding(.top, 2)
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("No history yet. Log your first drink to see history.")
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Streak card
                            if profile.currentStreak > 0 {
                                streakCard
                            }

                            // Weekly chart
                            weeklyChart

                            // Today's details with timeline
                            todaySection

                            // Yesterday
                            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
                            daySection(for: yesterday, title: "Yesterday")

                            // Day before yesterday
                            let dayBefore = Calendar.current.date(byAdding: .day, value: -2, to: .now)!
                            daySection(for: dayBefore, title: dayBefore.formatted(.dateTime.weekday(.wide)))
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("History")
            .sheet(isPresented: $showEditSheet) {
                if let log = editingLog {
                    EditLogSheet(
                        log: log,
                        unit: profile.unit,
                        onSave: { newAmount, newType in
                            manager.editLog(log, newAmount: newAmount, newDrinkType: newType)
                            showEditSheet = false
                        },
                        onDelete: {
                            haptics.error()
                            manager.deleteLog(log)
                            showEditSheet = false
                        }
                    )
                    .presentationDetents([.medium])
                }
            }
        }
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(profile.currentStreak) Day Streak")
                        .font(.title3.weight(.bold))
                    Text(streakMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(profile.currentStreak) day streak. \(streakMessage)")

            // Milestone dots
            HStack(spacing: 4) {
                ForEach([3, 7, 14, 30, 60, 100], id: \.self) { milestone in
                    VStack(spacing: 2) {
                        Circle()
                            .fill(profile.currentStreak >= milestone ? Color.orange : Color.gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                        Text("\(milestone)")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                    }
                    if milestone != 100 {
                        Rectangle()
                            .fill(profile.currentStreak >= milestone ? Color.orange.opacity(0.5) : Color.gray.opacity(0.2))
                            .frame(height: 2)
                    }
                }
            }
        }
        .padding()
        .background(Color.aquaCardBackground, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.orange.opacity(0.1), radius: 8, x: 0, y: 3)
    }

    private var streakMessage: String {
        switch profile.currentStreak {
        case 1...2: return "Just getting started!"
        case 3...6: return "Building momentum!"
        case 7...13: return "One week strong!"
        case 14...29: return "Two weeks of hydration!"
        case 30...59: return "A whole month! Amazing!"
        case 60...99: return "Two months! Incredible!"
        default: return "Legendary streak!"
        }
    }

    // MARK: - Weekly Chart

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            let weekData = manager.weeklyData()

            Chart(weekData, id: \.date) { item in
                BarMark(
                    x: .value("Day", item.date, unit: .day),
                    y: .value("ml", item.total)
                )
                .foregroundStyle(
                    item.total >= profile.dailyGoal
                        ? Color.aquaPrimary
                        : Color.aquaPrimary.opacity(0.4)
                )
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    if let ml = value.as(Double.self) {
                        AxisValueLabel {
                            Text(profile.unit.formatAmount(ml))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(date, format: .dateTime.weekday(.abbreviated))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYScale(domain: 0...(profile.dailyGoal * 1.3))
            .frame(height: 180)

            // Goal line label
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.aquaPrimary)
                    .frame(width: 8, height: 8)
                Text("Goal met")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Circle()
                    .fill(Color.aquaPrimary.opacity(0.4))
                    .frame(width: 8, height: 8)
                    .padding(.leading, 8)
                Text("Under goal")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.aquaCardBackground, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.aquaPrimary.opacity(0.08), radius: 8, x: 0, y: 3)
    }

    // MARK: - Today Section

    private var todaySection: some View {
        daySection(for: .now, title: "Today")
    }

    private func daySection(for date: Date, title: String) -> some View {
        let logs = manager.logsForDate(date)
        let total = logs.reduce(0) { $0 + $1.effectiveAmount }
        let caffeine = logs.reduce(0) { $0 + $1.caffeineMg }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [Color.aquaGradientStart, Color.aquaGradientEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 3, height: 18)
                    Text(title)
                        .font(.headline)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(profile.unit.formatAmount(total))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.aquaPrimary)
                    if caffeine > 0 {
                        Text("\(Int(caffeine))mg ☕")
                            .font(.caption2)
                            .foregroundStyle(.brown)
                    }
                }
            }

            if logs.isEmpty {
                Text("No drinks logged")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                // Timeline view
                ForEach(Array(logs.enumerated()), id: \.element.id) { index, log in
                    HStack(spacing: 12) {
                        // Timeline connector
                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(index == 0 ? Color.clear : Color.aquaPrimary.opacity(0.2))
                                .frame(width: 2)
                            Circle()
                                .fill(log.drink.color)
                                .frame(width: 8, height: 8)
                            Rectangle()
                                .fill(index == logs.count - 1 ? Color.clear : Color.aquaPrimary.opacity(0.2))
                                .frame(width: 2)
                        }
                        .frame(width: 10, height: 40)

                        Image(systemName: log.drink.iconName)
                            .font(.body)
                            .foregroundStyle(log.drink.color)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(log.drink.displayName)
                                .font(.subheadline.weight(.medium))
                            HStack(spacing: 4) {
                                Text(log.timestamp, format: .dateTime.hour().minute())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if log.caffeineMg > 0 {
                                    Text("• \(Int(log.caffeineMg))mg")
                                        .font(.caption)
                                        .foregroundStyle(.brown)
                                }
                            }
                        }

                        Spacer()

                        Text(profile.unit.formatAmount(log.amount))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.aquaPrimary)
                    }
                    .contentShape(Rectangle())
                    .contextMenu {
                        Button {
                            editingLog = log
                            editAmount = "\(Int(profile.unit.fromMl(log.amount)))"
                            editDrinkType = log.drink
                            showEditSheet = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            haptics.error()
                            withAnimation(.spring(response: 0.4)) {
                                manager.deleteLog(log)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.aquaCardBackground, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Log Row (simple list row for history)

struct LogRow: View {
    let log: WaterLog
    let unit: MeasurementUnit

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: log.drink.iconName)
                .font(.title3)
                .foregroundStyle(log.drink.color)
                .frame(width: 32)
                .accessibilityHidden(true)

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
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(log.drink.displayName), \(unit.formatAmount(log.amount)), at \(log.timestamp.formatted(.dateTime.hour().minute()))")
    }
}

// MARK: - Edit Log Sheet

struct EditLogSheet: View {
    let log: WaterLog
    let unit: MeasurementUnit
    let onSave: (Double?, DrinkType?) -> Void
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var amount: String
    @State private var selectedDrink: DrinkType

    init(log: WaterLog, unit: MeasurementUnit,
         onSave: @escaping (Double?, DrinkType?) -> Void,
         onDelete: @escaping () -> Void) {
        self.log = log
        self.unit = unit
        self.onSave = onSave
        self.onDelete = onDelete
        _amount = State(initialValue: "\(Int(unit.fromMl(log.amount)))")
        _selectedDrink = State(initialValue: log.drink)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Drink Details") {
                    HStack {
                        Text("Type")
                        Spacer()
                        Picker("", selection: $selectedDrink) {
                            ForEach(DrinkType.allCases) { drink in
                                HStack {
                                    Image(systemName: drink.iconName)
                                    Text(drink.displayName)
                                }
                                .tag(drink)
                            }
                        }
                    }

                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField(unit == .ml ? "ml" : "fl oz", text: $amount)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(unit.displayName)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Logged at")
                        Spacer()
                        Text(log.timestamp, format: .dateTime.hour().minute())
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button("Save Changes") {
                        var newAmount: Double?
                        var newType: DrinkType?

                        if let val = Double(amount), val > 0 {
                            let ml = unit.toMl(val)
                            if ml != log.amount { newAmount = ml }
                        }
                        if selectedDrink != log.drink { newType = selectedDrink }

                        onSave(newAmount, newType)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)

                    Button("Delete Log", role: .destructive) {
                        onDelete()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Edit Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

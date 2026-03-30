import SwiftUI
import TipKit

struct TimerView: View {
    @Environment(HydrationManager.self) private var manager
    @State private var selectedDrink: DrinkType = .water
    @State private var showDrinkPicker = false
    @State private var showCustomAmount = false
    @State private var customAmount: String = ""
    @State private var showGoalComplete = false
    @State private var showPaywall = false
    @State private var showConfetti = false
    @State private var splashTrigger = false
    @State private var showFavoritesSheet = false
    @State private var showAddFavorite = false
    @State private var favoriteName: String = ""

    // Water fill animation
    @State private var showWaterFillAnimation = false
    @State private var fillAnimationDrink: DrinkType = .water
    @State private var fillAnimationAmount: Double = 0

    // Undo state
    @State private var showUndoToast = false
    @State private var undoneAmount: Double = 0
    @State private var undoneDrinkName: String = ""

    // Staggered fade-in states
    @State private var buttonsAppeared = false
    @State private var customButtonBounce = false
    @State private var showSoftPaywallSheet = false
    @State private var sessionLogCount = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let profile = UserProfile.shared
    private let subscription = SubscriptionManager.shared
    private let haptics = HapticManager.shared
    private let sounds = SoundManager.shared

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Water-themed gradient background
                LinearGradient(
                    colors: [
                        Color.aquaGradientStart.opacity(0.30),
                        Color.aquaGradientEnd.opacity(0.15),
                        Color.aquaBackground
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Progress circle with water fill overlay
                        ZStack {
                            // Radial glow behind progress ring
                            Circle()
                                .fill(ThemeManager.shared.effectiveTheme.glowGradient)
                                .frame(width: 340, height: 340)
                                .blur(radius: 30)

                            CircularProgressView(
                                progress: manager.progress,
                                currentAmount: manager.todayTotal,
                                goalAmount: profile.dailyGoal,
                                unit: profile.unit,
                                showSplash: $splashTrigger
                            )
                            .frame(height: 300)
                            .accessibilityIdentifier("progressRing")

                            // Water fill animation overlay
                            if showWaterFillAnimation {
                                WaterFillAnimationView(
                                    drinkType: fillAnimationDrink,
                                    amount: fillAnimationAmount,
                                    unit: profile.unit
                                )
                                .transition(.opacity)
                            }
                        }
                        .padding(.top, 8)

                        // Motivational micro-copy based on progress
                        Text(motivationalMessage)
                            .font(.subheadline)
                            .foregroundStyle(Color.aquaTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .accessibilityLabel("Progress motivation: \(motivationalMessage)")

                        // Empty state for first use of the day
                        if manager.todayLogs.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "drop.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(Color.aquaPrimary)
                                    .symbolEffect(.pulse)

                                Text("Start Your Day Hydrated")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(Color.aquaTextPrimary)

                                Text("Tap a drink below to log your first sip. Every drop counts!")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(40)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Start your day hydrated. Tap a drink below to log your first sip.")
                        }

                        // Selected drink indicator with context menu for quick log
                        drinkSelector

                        // Recent drinks quick access
                        recentDrinksSection

                        // Quick add buttons with staggered fade-in
                        quickAddButtons

                        // Caffeine counter (if any caffeinated drinks today)
                        if manager.todayCaffeine > 0 {
                            caffeineCounter
                        }

                        // Encouragement when close to goal
                        if !goalReached, remainingToGoal > 0, remainingToGoal <= profile.dailyGoal * 0.2 {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(.yellow)
                                Text("Almost there! Just \(profile.unit.formatAmount(remainingToGoal)) to go!")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Color.aquaPrimary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.aquaPrimary.opacity(0.08), in: Capsule())
                            .transition(.scale.combined(with: .opacity))
                            .accessibilityLabel("Almost at your goal. \(profile.unit.formatAmount(remainingToGoal)) remaining")
                        }

                        // Streak with motivational text
                        if profile.currentStreak > 0 {
                            HStack(spacing: 6) {
                                Image(systemName: "flame.fill")
                                    .foregroundStyle(.orange)
                                Text(streakMotivationText)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Color.aquaTextSecondary)
                            }
                            .padding(.top, 4)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(profile.currentStreak) day hydration streak. \(streakMotivationText)")
                        }

                        // Favorites section
                        favoritesSection

                        // Soft paywall — non-blocking nudge after 7 days
                        if subscription.shouldShowSoftPaywall, !subscription.softPaywallDismissedThisSession {
                            SoftPaywallBanner {
                                withAnimation {
                                    subscription.softPaywallDismissedThisSession = true
                                }
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // Today's log timeline
                        if !manager.todayLogs.isEmpty {
                            todayTimeline
                        }

                        // Daily summary card
                        dailySummaryCard

                        // Bottom spacer for undo toast
                        Spacer().frame(height: 60)
                    }
                    .padding()
                }
                .navigationTitle(timeBasedGreeting)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            performUndo()
                        } label: {
                            Label("Undo last drink", systemImage: "arrow.uturn.backward")
                                .labelStyle(.iconOnly)
                                .font(.body)
                        }
                        .disabled(manager.todayLogs.isEmpty)
                        .foregroundStyle(manager.todayLogs.isEmpty ? Color.aquaTextSecondary.opacity(0.3) : Color.aquaPrimary)
                        .accessibilityHint(manager.todayLogs.isEmpty ? "No drinks to undo" : "Double tap to undo the last logged drink")
                        .accessibilityIdentifier("undoButton")
                    }
                }

                // Undo toast overlay
                if showUndoToast {
                    UndoToastView(
                        amount: undoneAmount,
                        drinkName: undoneDrinkName,
                        unit: profile.unit
                    ) {
                        manager.redoLastDrink()
                        withAnimation { showUndoToast = false }
                    } onDismiss: {
                        withAnimation { showUndoToast = false }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 16)
                }
            }
            .onAppear {
                // Trigger staggered button reveal
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    buttonsAppeared = true
                }
            }
            .sheet(isPresented: $showDrinkPicker) {
                DrinkPickerView(selectedDrink: $selectedDrink)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showFavoritesSheet) {
                FavoriteDrinksSheet()
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
            .alert("Save as Favorite", isPresented: $showAddFavorite) {
                TextField("Name (e.g. Morning Coffee)", text: $favoriteName)
                Button("Save") {
                    if !favoriteName.isEmpty {
                        let amount = profile.cupPresets.first ?? 250
                        manager.addFavorite(
                            name: favoriteName,
                            drinkType: selectedDrink,
                            amount: amount,
                            caffeineMg: selectedDrink.caffeinePer250ml * amount / 250.0
                        )
                    }
                    favoriteName = ""
                }
                Button("Cancel", role: .cancel) { favoriteName = "" }
            }
            .overlay {
                if showGoalComplete {
                    GoalCompleteOverlay {
                        withAnimation(.spring(response: 0.4)) {
                            showGoalComplete = false
                            showConfetti = false
                        }
                    }
                }

                if showConfetti, !reduceMotion {
                    ConfettiView()
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showSoftPaywallSheet) {
                PaywallView()
                    .onDisappear {
                        subscription.softPaywallDismissedThisSession = true
                    }
            }
            .alert(manager.errorTitle, isPresented: .init(
                get: { manager.showError },
                set: { manager.showError = $0 }
            )) {
                Button("OK") {}
            } message: {
                Text(manager.errorMessage)
            }
        }
    }

    // MARK: - Drink Selector

    private var drinkSelector: some View {
        Button {
            haptics.tabChange()
            haptics.sheetPresented()
            showDrinkPicker = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: selectedDrink.iconName)
                    .foregroundStyle(selectedDrink.color)
                Text(selectedDrink.displayName)
                    .foregroundStyle(Color.aquaTextPrimary)
                if selectedDrink.hasCaffeine {
                    Text("☕")
                        .font(.caption)
                }
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundStyle(Color.aquaTextSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.aquaCardBackground, in: Capsule())
        }
        .contextMenu {
            Button {
                showAddFavorite = true
            } label: {
                Label("Save as Favorite", systemImage: "star")
            }

            ForEach(profile.cupPresets.indices, id: \.self) { i in
                let amount = profile.cupPresets[i]
                Button {
                    logDrink(amount: amount)
                } label: {
                    Label(
                        "Quick Log \(profile.unit.formatAmount(amount))",
                        systemImage: "bolt.fill"
                    )
                }
            }
        }
        .accessibilityLabel("Selected drink: \(selectedDrink.displayName)")
        .accessibilityHint("Double tap to change drink type. Long press for quick actions.")
        .accessibilityIdentifier("drinkSelector")
    }

    // MARK: - Recent Drinks

    private var recentDrinksSection: some View {
        let recents = manager.recentDrinks(limit: 3)
        return Group {
            if !recents.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.aquaTextSecondary)
                        .padding(.horizontal, 4)

                    HStack(spacing: 8) {
                        ForEach(Array(recents.enumerated()), id: \.offset) { _, recent in
                            Button {
                                haptics.buttonPress()
                                selectedDrink = recent.drinkType
                                logDrink(amount: recent.amount)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: recent.drinkType.iconName)
                                        .font(.caption)
                                        .foregroundStyle(recent.drinkType.color)
                                    Text(profile.unit.formatAmount(recent.amount))
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(Color.aquaTextPrimary)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    recent.drinkType.color.opacity(0.1),
                                    in: Capsule()
                                )
                            }
                            .accessibilityLabel("Log \(profile.unit.formatAmount(recent.amount)) of \(recent.drinkType.displayName)")
                            .accessibilityHint("Double tap to log this recent drink")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Quick Add Buttons

    private var quickAddButtons: some View {
        HStack(spacing: 12) {
            ForEach(Array(zip(profile.cupPresets.indices, profile.cupPresets)), id: \.0) { index, amount in
                let name = index < profile.cupPresetNames.count ? profile.cupPresetNames[index] : ""
                QuickAddButton(amount: amount, name: name, unit: profile.unit) {
                    logDrink(amount: amount)
                }
                .opacity(buttonsAppeared ? 1 : 0)
                .offset(y: buttonsAppeared ? 0 : 20)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.7)
                        .delay(Double(index) * 0.08),
                    value: buttonsAppeared
                )
            }

            // Custom amount button with bounce
            Button {
                haptics.buttonPress()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                    customButtonBounce = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    customButtonBounce = false
                }
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
                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
            }
            .scaleEffect(customButtonBounce ? 1.2 : 1.0)
            .accessibilityLabel("Log custom amount of \(selectedDrink.displayName)")
            .accessibilityHint("Double tap to enter a custom drink amount")
            .accessibilityIdentifier("customAmountButton")
            .opacity(buttonsAppeared ? 1 : 0)
            .offset(y: buttonsAppeared ? 0 : 20)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.7)
                    .delay(Double(profile.cupPresets.count) * 0.08),
                value: buttonsAppeared
            )
        }
    }

    // MARK: - Caffeine Counter

    private var caffeineCounter: some View {
        HStack(spacing: 8) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.subheadline)
                .foregroundStyle(.brown)

            Text("\(Int(manager.todayCaffeine)) mg caffeine today")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.aquaTextSecondary)

            if manager.todayCaffeine > 400 {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.brown.opacity(0.08), in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Int(manager.todayCaffeine)) milligrams caffeine consumed today\(manager.todayCaffeine > 400 ? ", exceeds recommended daily limit" : "")")
    }

    // MARK: - Favorites Section

    private var favoritesSection: some View {
        let favorites = manager.fetchFavorites()
        return Group {
            if !favorites.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Favorites")
                            .font(.headline)
                            .foregroundStyle(Color.aquaTextPrimary)
                        Spacer()
                        Button {
                            haptics.buttonPress()
                            showFavoritesSheet = true
                        } label: {
                            Text("Manage")
                                .font(.caption)
                                .foregroundStyle(Color.aquaPrimary)
                        }
                    }
                    .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(favorites, id: \.id) { fav in
                                Button {
                                    haptics.buttonPress()
                                    selectedDrink = fav.drink
                                    logDrink(amount: fav.amount, caffeineMg: fav.caffeineAmount)
                                } label: {
                                    VStack(spacing: 6) {
                                        ZStack {
                                            Circle()
                                                .fill(fav.drink.color.opacity(0.15))
                                                .frame(width: 40, height: 40)
                                            Image(systemName: fav.drink.iconName)
                                                .font(.body)
                                                .foregroundStyle(fav.drink.color)
                                        }
                                        Text(fav.name)
                                            .font(.caption2.weight(.medium))
                                            .foregroundStyle(Color.aquaTextPrimary)
                                            .lineLimit(1)
                                        Text(profile.unit.formatAmount(fav.amount))
                                            .font(.system(size: 9))
                                            .foregroundStyle(Color.aquaTextSecondary)
                                    }
                                    .frame(width: 70)
                                    .padding(.vertical, 8)
                                    .background(Color.aquaCardBackground, in: RoundedRectangle(cornerRadius: 12))
                                    .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                                }
                                .accessibilityLabel("Log \(profile.unit.formatAmount(fav.amount)) of \(fav.drink.displayName), \(fav.name)")
                                .accessibilityHint("Double tap to log this favorite drink")
                            }

                            // Add favorite button
                            Button {
                                haptics.buttonPress()
                                showAddFavorite = true
                            } label: {
                                VStack(spacing: 6) {
                                    ZStack {
                                        Circle()
                                            .strokeBorder(Color.aquaPrimary.opacity(0.3), lineWidth: 1.5)
                                            .frame(width: 40, height: 40)
                                        Image(systemName: "plus")
                                            .font(.body)
                                            .foregroundStyle(Color.aquaPrimary)
                                    }
                                    Text("Add")
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(Color.aquaTextSecondary)
                                    Text(" ")
                                        .font(.system(size: 9))
                                }
                                .frame(width: 70)
                                .padding(.vertical, 8)
                                .background(Color.aquaCardBackground, in: RoundedRectangle(cornerRadius: 12))
                                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                            }
                            .accessibilityLabel("Add new favorite drink")
                            .accessibilityHint("Double tap to save a drink as a favorite")
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Today Timeline

    private var todayTimeline: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Today's Timeline")
                    .font(.headline)
                    .foregroundStyle(Color.aquaTextPrimary)
                Spacer()
                Text("\(manager.todayLogs.count) drinks")
                    .font(.caption)
                    .foregroundStyle(Color.aquaTextSecondary)
            }
            .padding(.horizontal)

            ForEach(Array(manager.todayLogs.enumerated()), id: \.element.id) { index, log in
                TimelineLogRow(
                    log: log,
                    unit: profile.unit,
                    isFirst: index == 0,
                    isLast: index == manager.todayLogs.count - 1
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
                .contextMenu {
                    Button(role: .destructive) {
                        haptics.deleteDrink()
                        sounds.playDeleteSound()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            manager.deleteLog(log)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Daily Summary Card

    private var dailySummaryCard: some View {
        let remaining = max(0, profile.dailyGoal - manager.todayTotal)
        let drinkCount = manager.todayLogs.count
        let avgPerDrink = drinkCount > 0 ? manager.todayTotal / Double(drinkCount) : 0
        let goalMet = manager.todayTotal >= profile.dailyGoal

        return VStack(spacing: 16) {
            HStack {
                Image(systemName: goalMet ? "checkmark.seal.fill" : "chart.bar.doc.horizontal.fill")
                    .font(.title3)
                    .foregroundStyle(goalMet ? .green : Color.aquaPrimary)
                Text("Daily Summary")
                    .font(.headline)
                Spacer()
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                SummaryItem(
                    icon: "drop.fill",
                    label: "Total",
                    value: profile.unit.formatAmount(manager.todayTotal),
                    color: Color.aquaPrimary
                )

                SummaryItem(
                    icon: goalMet ? "checkmark.circle.fill" : "target",
                    label: goalMet ? "Goal Met!" : "Remaining",
                    value: goalMet ? "✓" : profile.unit.formatAmount(remaining),
                    color: goalMet ? .green : .orange
                )

                SummaryItem(
                    icon: "number",
                    label: "Drinks",
                    value: "\(drinkCount)",
                    color: .purple
                )

                SummaryItem(
                    icon: "chart.line.uptrend.xyaxis",
                    label: "Avg / Drink",
                    value: drinkCount > 0 ? profile.unit.formatAmount(avgPerDrink) : "—",
                    color: .blue
                )

                if manager.todayCaffeine > 0 {
                    SummaryItem(
                        icon: "cup.and.saucer.fill",
                        label: "Caffeine",
                        value: "\(Int(manager.todayCaffeine)) mg",
                        color: .brown
                    )

                    SummaryItem(
                        icon: "drop.degreesign.fill",
                        label: "Hydration",
                        value: "\(Int(manager.progress * 100))%",
                        color: Color.aquaSecondary
                    )
                }
            }
        }
        .padding()
        .background(Color.aquaCardBackground, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.aquaPrimary.opacity(0.08), radius: 12, x: 0, y: 4)
        .padding(.top, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Daily summary: \(profile.unit.formatAmount(manager.todayTotal)) total, \(drinkCount) drinks, \(goalMet ? "goal met" : "\(profile.unit.formatAmount(remaining)) remaining")")
        .accessibilityIdentifier("dailySummaryCard")
    }

    // MARK: - Actions

    private var goalReached: Bool {
        manager.todayTotal >= profile.dailyGoal
    }

    private var remainingToGoal: Double {
        max(0, profile.dailyGoal - manager.todayTotal)
    }

    /// Context-aware greeting that replaces the static "AquaFaste" title
    private var timeBasedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let progress = manager.progress
        if progress >= 1.0 {
            return "Goal Reached! 🏆"
        }
        switch hour {
        case 5 ..< 12: return "Good Morning 💧"
        case 12 ..< 17: return "Stay Hydrated ☀️"
        case 17 ..< 21: return "Evening Sip 🌙"
        default: return "Night Hydration 🌊"
        }
    }

    private var motivationalMessage: String {
        let pct = manager.progress
        switch pct {
        case ...0:
            return "A fresh start! Your first drink makes all the difference."
        case 0 ..< 0.25:
            return "Nice start! Keep the momentum going. 💧"
        case 0.25 ..< 0.50:
            return "You're getting there! Halfway to your goal. 💪"
        case 0.50 ..< 0.75:
            return "Over halfway! Your body is thanking you. ✨"
        case 0.75 ..< 1.0:
            return "Almost there! Just a bit more to crush your goal! 🎯"
        default:
            return "Goal complete! You're a hydration champion! 🏆"
        }
    }

    private var streakMotivationText: String {
        let streak = profile.currentStreak
        switch streak {
        case 1: return "Day 1! Every journey starts here 💧"
        case 2: return "Day 2! Building momentum 💪"
        case 3 ... 6: return "\(streak)-day streak! Keep it going 🔥"
        case 7: return "Hydration hero! Day 7 🏆"
        case 8 ... 13: return "\(streak) days strong! 🌟"
        case 14 ... 29: return "\(streak) days! You're unstoppable 💎"
        case 30: return "Legendary! Day 30 👑"
        case 31 ... 59: return "\(streak)-day streak! Over a month! 👑"
        case 60 ... 99: return "\(streak) days! Incredible discipline 🎯"
        default: return "\(streak)-day legendary streak! 🌊"
        }
    }

    private func logDrink(amount: Double, caffeineMg: Double? = nil) {
        let wasUnderGoal = manager.todayTotal < profile.dailyGoal
        manager.logWater(amount: amount, drinkType: selectedDrink, caffeineMg: caffeineMg)

        // Track session log count for soft paywall
        sessionLogCount += 1
        subscription.incrementActionCount()

        // Haptic + sound for water logging
        haptics.logDrink()
        sounds.playLogSound()

        // Splash animation
        splashTrigger = true

        // Water fill animation
        fillAnimationDrink = selectedDrink
        fillAnimationAmount = amount
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showWaterFillAnimation = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                showWaterFillAnimation = false
            }
        }

        // Goal complete celebration
        if wasUnderGoal, manager.todayTotal >= profile.dailyGoal {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                haptics.goalComplete()
                sounds.playGoalComplete()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showGoalComplete = true
                    showConfetti = true
                }
            }
        }

        // Soft paywall after 3rd log action for free users (non-blocking)
        if subscription.shouldShowSoftPaywallForAction(actionCount: sessionLogCount) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showSoftPaywallSheet = true
            }
        }
    }

    private func performUndo() {
        guard let undone = manager.undoLastDrink() else { return }
        haptics.buttonPress()
        sounds.playDeleteSound()
        undoneAmount = undone.amount
        undoneDrinkName = undone.drink.displayName
        withAnimation(.spring(response: 0.4)) {
            showUndoToast = true
        }
    }
}

// MARK: - Quick Add Button

struct QuickAddButton: View {
    let amount: Double
    let name: String
    let unit: MeasurementUnit
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            action()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "drop.fill")
                    .font(.title2)
                Text(unit.formatAmount(amount))
                    .font(.caption2.weight(.medium))
                if !name.isEmpty {
                    Text(name)
                        .font(.system(size: 8, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .frame(width: 72, height: 72)
            .foregroundStyle(.white)
            .background(Color.aquaGradient, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.aquaGradientEnd.opacity(0.35), radius: 8, x: 0, y: 4)
            .shadow(color: Color.aquaGradientStart.opacity(0.15), radius: 3, x: 0, y: 1)
        }
        .scaleEffect(isPressed ? 0.88 : 1.0)
        .accessibilityLabel("Log \(unit.formatAmount(amount))\(name.isEmpty ? "" : ", \(name)")")
        .accessibilityHint("Double tap to add to today's hydration")
        .accessibilityIdentifier("quickAdd\(Int(amount))")
    }
}

// MARK: - Undo Toast

struct UndoToastView: View {
    let amount: Double
    let drinkName: String
    let unit: MeasurementUnit
    let onUndo: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.uturn.backward.circle.fill")
                .font(.title3)
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 2) {
                Text("Drink Removed")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text("\(unit.formatAmount(amount)) \(drinkName)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()

            Button("Undo") {
                onUndo()
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(Color.aquaPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.white, in: Capsule())
            .accessibilityLabel("Undo removal of \(unit.formatAmount(amount)) \(drinkName)")
            .accessibilityIdentifier("undoToastButton")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.darkGray), in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                onDismiss()
            }
        }
    }
}

// MARK: - Timeline Log Row

struct TimelineLogRow: View {
    let log: WaterLog
    let unit: MeasurementUnit
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Timeline connector
            VStack(spacing: 0) {
                Rectangle()
                    .fill(isFirst ? Color.clear : Color.aquaPrimary.opacity(0.3))
                    .frame(width: 2)

                Circle()
                    .fill(log.drink.color)
                    .frame(width: 10, height: 10)

                Rectangle()
                    .fill(isLast ? Color.clear : Color.aquaPrimary.opacity(0.3))
                    .frame(width: 2)
            }
            .frame(width: 12, height: 44)

            Image(systemName: log.drink.iconName)
                .font(.body)
                .foregroundStyle(log.drink.color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(log.drink.displayName)
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 4) {
                    Text(log.timestamp, format: .dateTime.hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if log.caffeineMg > 0 {
                        Text("• \(Int(log.caffeineMg)) mg ☕")
                            .font(.caption)
                            .foregroundStyle(.brown)
                    }
                }
            }

            Spacer()

            Text(unit.formatAmount(log.amount))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.aquaPrimary)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(log.drink.displayName), \(unit.formatAmount(log.amount)), at \(log.timestamp.formatted(.dateTime.hour().minute()))\(log.caffeineMg > 0 ? ", \(Int(log.caffeineMg)) milligrams caffeine" : "")")
    }
}

// MARK: - Summary Item

struct SummaryItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.aquaTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

struct WaterFillAnimationView: View {
    let drinkType: DrinkType
    let amount: Double
    let unit: MeasurementUnit

    @State private var opacity: Double = 0
    @State private var iconScale: CGFloat = 0.5

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: drinkType.iconName)
                .font(.system(size: 32))
                .foregroundStyle(drinkType.color)
                .scaleEffect(iconScale)

            Text("+\(unit.formatAmount(amount))")
                .font(.title3.weight(.bold))
                .foregroundStyle(drinkType.color)
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                iconScale = 1.2
                opacity = 1.0
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7).delay(0.2)) {
                iconScale = 1.0
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.9).delay(0.8)) {
                opacity = 0
            }
        }
    }
}

// MARK: - Goal Complete Overlay

struct GoalCompleteOverlay: View {
    let onDismiss: () -> Void

    @State private var iconScale: CGFloat = 0.3
    @State private var iconOpacity: Double = 0
    @State private var contentOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)
                .accessibilityHidden(true)

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.green)
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)

                Text("Goal Complete! 💧")
                    .font(.title2.weight(.bold))
                    .opacity(contentOpacity)

                Text("You've reached your daily hydration goal.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(contentOpacity)

                Button("Great!", action: onDismiss)
                    .buttonStyle(.borderedProminent)
                    .tint(Color.aquaPrimary)
                    .padding(.top, 8)
                    .opacity(contentOpacity)
                    .accessibilityLabel("Dismiss goal complete celebration")
            }
            .padding(32)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
            .padding(40)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Congratulations! You've reached your daily hydration goal.")
            .accessibilityAddTraits(.isModal)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.3)) {
                contentOpacity = 1.0
            }
            UIAccessibility.post(notification: .announcement,
                                 argument: "Goal complete! You've reached your daily hydration goal.")
        }
    }
}

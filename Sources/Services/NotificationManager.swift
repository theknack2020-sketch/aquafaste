import Foundation
import SwiftUI
import UserNotifications

// MARK: - Notification Categories & Identifiers

enum NotificationCategory: String {
    case hydrationReminder = "HYDRATION_REMINDER"
    case morningReminder = "MORNING_REMINDER"
    case eveningSummary = "EVENING_SUMMARY"
    case goalComplete = "GOAL_COMPLETE"
    case streakReminder = "STREAK_REMINDER"
    case weeklySummary = "WEEKLY_SUMMARY"
    case streakProtection = "STREAK_PROTECTION"
    case inactivityNudge = "INACTIVITY_NUDGE"
    case achievementUnlocked = "ACHIEVEMENT_UNLOCKED"
}

enum NotificationID {
    static let morningReminder = "morning_reminder"
    static let eveningSummary = "evening_summary"
    static let goalComplete = "goal_complete"
    static let streakReminder = "streak_reminder"
    static let weeklySummary = "weekly_summary"
    static let streakProtection = "streak_protection"
    static let inactivityNudge = "inactivity_nudge"

    static func hydrationReminder(day: Int, hour: Int) -> String {
        "hydration_\(day)_\(hour)"
    }
}

// MARK: - Authorization Status

enum NotificationAuthStatus: Equatable {
    case notDetermined
    case authorized
    case denied
    case provisional
}

// MARK: - NotificationManager

@MainActor
final class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let profile = UserProfile.shared

    @Published var authStatus: NotificationAuthStatus = .notDetermined
    @Published var pendingCount: Int = 0

    /// Timestamp of the last water log — used for smart timing suppression
    private(set) var lastLogTimestamp: Date?

    override private init() {
        super.init()
        center.delegate = self
    }

    // MARK: - Authorization

    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized: authStatus = .authorized
        case .denied: authStatus = .denied
        case .provisional: authStatus = .provisional
        case .notDetermined: authStatus = .notDetermined
        default: authStatus = .notDetermined
        }
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            authStatus = granted ? .authorized : .denied
            return granted
        } catch {
            print("[AquaFaste] Notification auth failed: \(error)")
            authStatus = .denied
            return false
        }
    }

    // MARK: - Category Registration

    func registerCategories() {
        let logAction = UNNotificationAction(
            identifier: "LOG_WATER",
            title: "Log 250ml 💧",
            options: .foreground
        )

        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: .destructive
        )

        let reminderCategory = UNNotificationCategory(
            identifier: NotificationCategory.hydrationReminder.rawValue,
            actions: [logAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        let morningCategory = UNNotificationCategory(
            identifier: NotificationCategory.morningReminder.rawValue,
            actions: [logAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        let eveningCategory = UNNotificationCategory(
            identifier: NotificationCategory.eveningSummary.rawValue,
            actions: [dismissAction],
            intentIdentifiers: [],
            options: []
        )

        let goalCategory = UNNotificationCategory(
            identifier: NotificationCategory.goalComplete.rawValue,
            actions: [dismissAction],
            intentIdentifiers: [],
            options: []
        )

        let streakCategory = UNNotificationCategory(
            identifier: NotificationCategory.streakReminder.rawValue,
            actions: [logAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([
            reminderCategory,
            morningCategory,
            eveningCategory,
            goalCategory,
            streakCategory
        ])
    }

    // MARK: - Message Variants

    /// Morning motivation messages — random selection
    private static let morningMessages: [(title: String, body: String)] = [
        ("Rise and Hydrate! 🌅", "Start your day with a glass of water — your body dehydrates overnight."),
        ("Good Morning! ☀️", "Your body needs water after sleep. A glass now kickstarts your metabolism."),
        ("Start Strong 💧", "A glass of water first thing sets the tone for a great day."),
        ("Morning Energy ☕", "Morning hydration = morning energy. Let's go!"),
        ("Wake Up, Drink Up! 💧", "Your cells are thirsty after 8 hours. Hydrate to feel sharp and focused.")
    ]

    /// Streak protection messages — with {streak} placeholder
    private static let streakProtectionMessages: [String] = [
        "Don't break your {streak}-day streak! 🔥",
        "Your streak is at risk! One glass keeps it alive.",
        "{streak} days strong. Keep it going! 💪",
        "Almost lost it! Quick — log a drink to save your streak.",
        "Streak alert: Log water now to stay on track. 🏆"
    ]

    /// Evening summary messages — dynamic based on progress
    private static let eveningGoalMetMessages: [String] = [
        "Great day! You drank {amount} today. 🌟",
        "Hydration champion! {percentage}% of your goal — crushed it! 💧",
        "Day complete. You logged {count} drinks today. Nice! ✅",
        "Goal smashed! {amount} logged. Your body thanks you. 🎯",
        "Another perfect day — {percentage}% hydrated. Keep it up! 🏆"
    ]

    private static let eveningGoalNotMetMessages: [String] = [
        "You're {remaining} away from your goal. One more glass?",
        "Hydration recap: {percentage}% of your goal today. Almost there!",
        "So close! Just {remaining} more to hit 100%. 🎯",
        "You drank {amount} today ({percentage}%). A bit more before bed?",
        "Evening check: {remaining} left to reach your target. 💧"
    ]

    /// Inactivity nudge messages — for 3+ days absence
    private static let inactivityMessages: [String] = [
        "We miss you! 💧 Your hydration tracking is waiting.",
        "It's been a while. A fresh glass of water awaits.",
        "Ready to restart? Your body will thank you. 🙏",
        "Let's build that streak back! One glass to begin. 💪",
        "Water break — your hydration journey doesn't end here. 🌊"
    ]

    /// Get a random message for a type, with variable substitution
    func randomMessage(
        for type: NotificationCategory,
        streak: Int = 0,
        amount: Double = 0,
        goal: Double = 0,
        count: Int = 0
    ) -> (title: String, body: String) {
        let unit = profile.unit

        switch type {
        case .morningReminder:
            return Self.morningMessages.randomElement()!

        case .streakProtection:
            let template = Self.streakProtectionMessages.randomElement()!
            let body = template.replacingOccurrences(of: "{streak}", with: "\(streak)")
            return ("Keep Your Streak! 🔥", body)

        case .eveningSummary:
            let percentage = goal > 0 ? Int(amount / goal * 100) : 0
            let remaining = unit.formatAmount(max(0, goal - amount))
            let formattedAmount = unit.formatAmount(amount)
            let emoji = percentage >= 100 ? "🎉" : (percentage >= 75 ? "👍" : "💧")

            let templates = amount >= goal ? Self.eveningGoalMetMessages : Self.eveningGoalNotMetMessages
            let template = templates.randomElement()!

            let body = template
                .replacingOccurrences(of: "{amount}", with: formattedAmount)
                .replacingOccurrences(of: "{remaining}", with: remaining)
                .replacingOccurrences(of: "{percentage}", with: "\(percentage)")
                .replacingOccurrences(of: "{count}", with: "\(count)")
                .replacingOccurrences(of: "{emoji}", with: emoji)

            return ("Daily Hydration Summary 🌙", body)

        case .inactivityNudge:
            let body = Self.inactivityMessages.randomElement()!
            return ("Time to Hydrate Again 💧", body)

        default:
            return ("Time to hydrate! 💧", "A glass of water keeps you sharp and energized.")
        }
    }

    // MARK: - Smart Timing

    /// Record that the user just logged water — suppresses imminent reminders
    func recordWaterLog() {
        lastLogTimestamp = Date.now
    }

    /// Whether a notification should be suppressed because user recently logged
    private var shouldSuppressReminder: Bool {
        guard let last = lastLogTimestamp else { return false }
        return Date.now.timeIntervalSince(last) < 30 * 60 // 30 min cooldown
    }

    // MARK: - Schedule All Notifications

    /// Master scheduling function — call on launch and after any setting change
    func scheduleAllNotifications() async {
        center.removeAllPendingNotificationRequests()

        let authorized = await requestAuthorization()
        guard authorized else { return }

        if profile.remindersEnabled {
            await scheduleHydrationReminders()
        }

        if profile.morningReminderEnabled {
            await scheduleMorningReminder()
        }

        if profile.eveningSummaryEnabled {
            await scheduleEveningSummary()
        }

        if profile.streakReminderEnabled {
            await scheduleStreakReminder()
        }

        // Weekly summary every Sunday at 8 PM
        await scheduleWeeklySummary()

        // Streak protection — fires 2 hours before bedtime if streak > 0
        await scheduleStreakProtection()

        await updatePendingCount()
    }

    // MARK: - Hydration Reminders (every 1-2 hours during waking hours)

    private func scheduleHydrationReminders() async {
        let intervalMinutes = profile.reminderInterval
        let sleepStart = profile.sleepStart
        let sleepEnd = profile.sleepEnd

        let calendar = Calendar.current
        let now = Date.now
        let hourIncrement = max(1, intervalMinutes / 60)

        // Schedule for today and tomorrow (iOS limits to 64 pending notifications)
        for dayOffset in 0 ... 1 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            let startOfDay = calendar.startOfDay(for: day)

            var hour = sleepEnd
            // Start reminders 1 hour after wake to avoid overlapping with morning reminder
            if profile.morningReminderEnabled {
                hour = sleepEnd + 1
            }

            while hour < sleepStart {
                guard let reminderDate = calendar.date(
                    bySettingHour: hour, minute: 0, second: 0, of: startOfDay
                ) else {
                    hour += hourIncrement
                    continue
                }

                // Skip past times
                if reminderDate <= now {
                    hour += hourIncrement
                    continue
                }

                // Smart timing: skip if user logged recently and reminder is within 30 min
                if shouldSuppressReminder, reminderDate.timeIntervalSince(now) < 30 * 60 {
                    hour += hourIncrement
                    continue
                }

                let message = motivationalMessage(for: hour)
                let content = UNMutableNotificationContent()
                content.title = message.title
                content.body = message.body
                content.sound = .default
                content.categoryIdentifier = NotificationCategory.hydrationReminder.rawValue
                content.threadIdentifier = "hydration-reminders"

                var components = calendar.dateComponents(
                    [.year, .month, .day, .hour, .minute], from: reminderDate
                )
                components.second = 0

                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(
                    identifier: NotificationID.hydrationReminder(day: dayOffset, hour: hour),
                    content: content,
                    trigger: trigger
                )

                try? await center.add(request)
                hour += hourIncrement
            }
        }
    }

    // MARK: - Morning Reminder

    private func scheduleMorningReminder() async {
        let message = randomMessage(for: .morningReminder)
        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = message.body
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.morningReminder.rawValue
        content.threadIdentifier = "morning-reminder"

        var components = DateComponents()
        components.hour = profile.sleepEnd
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationID.morningReminder,
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    // MARK: - Evening Summary

    private func scheduleEveningSummary() async {
        let content = UNMutableNotificationContent()
        content.title = "Daily Hydration Summary 🌙"
        // Body is generic since we can't know the exact amount at schedule time.
        // We use a notification service extension pattern: schedule with placeholder,
        // update via bestAttemptContent. For now, use a motivational generic message.
        content.body = "Check your hydration progress for today! Tap to see your summary."
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.eveningSummary.rawValue
        content.threadIdentifier = "evening-summary"

        // Schedule 1 hour before sleep
        var components = DateComponents()
        let summaryHour = max(0, profile.sleepStart - 1)
        components.hour = summaryHour
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationID.eveningSummary,
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    /// Fire an immediate evening summary with actual data
    func sendEveningSummaryNow(todayTotal: Double, goalAmount: Double, logCount: Int = 0) {
        let message = randomMessage(
            for: .eveningSummary,
            amount: todayTotal,
            goal: goalAmount,
            count: logCount
        )

        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = message.body
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.eveningSummary.rawValue

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(NotificationID.eveningSummary)_now",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // MARK: - Goal Complete Celebration

    func sendGoalCompleteNotification(streak: Int) {
        guard profile.goalCelebrationEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Goal Complete! 🎉💧"

        let messages: [String] = if streak > 7 {
            [
                "You've hit your daily hydration goal! That's \(streak) days in a row. Legendary! 🔥",
                "Goal crushed — \(streak)-day streak and counting. You're a hydration machine! 🏆",
                "\(streak) days strong! Your consistency is impressive. Keep dominating! 💪"
            ]
        } else if streak > 1 {
            [
                "You've hit your daily hydration goal! That's \(streak) days in a row. You're on fire! 🔥",
                "Daily goal — done. \(streak)-day streak is growing! 💪",
                "Another day, another goal crushed. \(streak) days and counting! 🌟"
            ]
        } else {
            [
                "You've reached your daily hydration goal. Great job staying hydrated!",
                "Daily goal achieved! Your body thanks you. Keep it going tomorrow! 💧",
                "100% hydrated today — that's how it's done! 🎯"
            ]
        }

        content.body = messages.randomElement()!

        content.sound = UNNotificationSound.default
        content.categoryIdentifier = NotificationCategory.goalComplete.rawValue
        content.threadIdentifier = "goal-complete"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: NotificationID.goalComplete,
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // MARK: - Streak Reminder

    private func scheduleStreakReminder() async {
        let streak = profile.currentStreak
        guard streak > 0 else { return }

        let message = randomMessage(for: .streakProtection, streak: streak)
        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = message.body
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.streakReminder.rawValue
        content.threadIdentifier = "streak-reminder"

        // Schedule for midday (halfway through waking hours)
        let midday = profile.sleepEnd + (profile.sleepStart - profile.sleepEnd) / 2
        var components = DateComponents()
        components.hour = midday
        components.minute = 30

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationID.streakReminder,
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    private func streakMessage(for streak: Int) -> String {
        switch streak {
        case 1 ... 2:
            "You've got a \(streak)-day streak! Don't break it — log some water today. 💧"
        case 3 ... 6:
            "Your \(streak)-day streak is building momentum! Keep it going. 💪"
        case 7 ... 13:
            "A whole week of hydration! Your \(streak)-day streak is impressive. Keep pushing! 🌟"
        case 14 ... 29:
            "\(streak) days strong! You're building a real habit. Don't stop now! 🏆"
        case 30 ... 59:
            "\(streak)-day streak — that's over a month! You're a hydration champion. 👑"
        case 60 ... 99:
            "Incredible \(streak)-day streak! You're in the top tier of hydration. 🎯"
        default:
            "\(streak) days — legendary streak! Keep this going forever. 🌊"
        }
    }

    // MARK: - Motivational Messages (Rotating)

    private func motivationalMessage(for hour: Int) -> (title: String, body: String) {
        let messages: [(String, String)] = [
            ("Time to hydrate! 💧", "A glass of water keeps you sharp and energized."),
            ("Water break! 🌊", "Your body is 60% water — keep it topped up."),
            ("Stay hydrated! 💦", "Even mild dehydration affects your focus and mood."),
            ("Drink up! 🥤", "Regular sips beat drinking all at once."),
            ("Hydration check ✅", "Have you had water recently? Your body will thank you."),
            ("Water time! 🫗", "Hydration helps your skin, digestion, and energy levels."),
            ("Quick reminder 💧", "Take a moment to drink some water — future you will appreciate it."),
            ("H₂O time! 🌿", "Hydration is the foundation of good health."),
            ("Thirsty? 💙", "Your brain works better when you're well hydrated."),
            ("Sip break! 🧊", "A few sips now can prevent that afternoon energy crash."),
            ("Water o'clock! ⏰", "Consistent hydration beats waiting until you're thirsty."),
            ("Hydration boost 🚀", "Water fuels everything — from thinking to moving."),
            ("Stay sharp! 🎯", "Dehydration drops cognitive performance by up to 25%."),
            ("Your body needs you 💪", "Every cell in your body needs water to function."),
            ("Refill time! 🔄", "Top up your water bottle and take a few sips."),
            ("Glow up! ✨", "Hydrated skin is happy skin. Drink some water.")
        ]

        // Use hour + day-of-year for rotation so messages vary across hours and days
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: .now) ?? 0
        let index = (hour + dayOfYear) % messages.count
        return messages[index]
    }

    // MARK: - Weekly Summary (Sundays at 8 PM)

    private func scheduleWeeklySummary() async {
        let content = UNMutableNotificationContent()
        content.title = "Weekly Hydration Report 📊"
        content.body = "Tap to see your week in review — streaks, achievements, and hydration trends."
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.weeklySummary.rawValue
        content.threadIdentifier = "weekly-summary"

        var components = DateComponents()
        components.weekday = 1 // Sunday
        components.hour = 20 // 8 PM
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationID.weeklySummary,
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    // MARK: - Streak Protection (2 hours before bedtime if no logs today)

    func scheduleStreakProtection() async {
        let streak = profile.currentStreak
        guard streak > 0, profile.streakReminderEnabled else { return }

        // Remove any existing streak protection notification
        center.removePendingNotificationRequests(withIdentifiers: [NotificationID.streakProtection])

        let message = randomMessage(for: .streakProtection, streak: streak)
        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = message.body
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.streakProtection.rawValue
        content.threadIdentifier = "streak-protection"
        content.interruptionLevel = .timeSensitive

        // Fire 2 hours before bedtime
        let protectionHour = max(0, profile.sleepStart - 2)
        var components = DateComponents()
        components.hour = protectionHour
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: NotificationID.streakProtection,
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    // MARK: - Inactivity Nudge (after 3+ days of no logs)

    func scheduleInactivityNudge(lastLogDate: Date?) async {
        // Remove existing inactivity nudge
        center.removePendingNotificationRequests(withIdentifiers: [NotificationID.inactivityNudge])

        guard let lastLog = lastLogDate else { return }

        let daysSinceLastLog = Calendar.current.dateComponents([.day], from: lastLog, to: .now).day ?? 0
        guard daysSinceLastLog >= 3 else { return }

        let message = randomMessage(for: .inactivityNudge)
        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = message.body
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.inactivityNudge.rawValue
        content.threadIdentifier = "inactivity-nudge"

        // Fire tomorrow morning at wake time
        var components = DateComponents()
        components.hour = profile.sleepEnd
        components.minute = 30

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: NotificationID.inactivityNudge,
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    // MARK: - Cancel All

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Refill Reminder

    /// Send a refill reminder when user has emptied a bottle worth of water
    func sendRefillReminder(bottleNumber: Int) {
        let profile = UserProfile.shared
        guard profile.refillReminderEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Time to Refill! 🔄"
        content.body = "You've finished bottle #\(bottleNumber) (\(profile.unit.formatAmount(profile.bottleSize))). Refill your bottle to keep the hydration going! 💧"
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.hydrationReminder.rawValue
        content.threadIdentifier = "refill-reminder"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "refill_\(bottleNumber)_\(Date.now.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // MARK: - Helpers

    func updatePendingCount() async {
        let pending = await center.pendingNotificationRequests()
        pendingCount = pending.count
    }

    /// Open system notification settings for the app
    func openNotificationSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    /// Show notifications even when app is in foreground
    nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Don't show hydration reminders in foreground — user is actively using the app
        let category = notification.request.content.categoryIdentifier
        if category == NotificationCategory.hydrationReminder.rawValue {
            return []
        }
        // Show goal complete and other notifications as banners
        return [.banner, .sound]
    }

    /// Handle notification tap and action button responses
    nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let actionID = response.actionIdentifier
        if actionID == "LOG_WATER" {
            // Post notification so ContentView/HydrationManager can log water
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .didTapLogWaterNotificationAction,
                    object: nil
                )
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let didTapLogWaterNotificationAction = Notification.Name("didTapLogWaterNotificationAction")
}

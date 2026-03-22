import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let profile = UserProfile.shared

    private init() {}

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("[AquaFaste] Notification auth failed: \(error)")
            return false
        }
    }

    // MARK: - Schedule Reminders

    func scheduleReminders() async {
        // Clear existing
        center.removeAllPendingNotificationRequests()

        let authorized = await requestAuthorization()
        guard authorized else { return }

        let intervalMinutes = profile.reminderInterval
        let sleepStart = profile.sleepStart
        let sleepEnd = profile.sleepEnd

        // Schedule reminders for today and tomorrow
        let calendar = Calendar.current
        let now = Date.now

        for dayOffset in 0...1 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            let startOfDay = calendar.startOfDay(for: day)

            // Create reminders from sleepEnd to sleepStart
            var hour = sleepEnd
            while hour < sleepStart {
                let minute = 0
                guard let reminderDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: startOfDay) else {
                    hour += intervalMinutes / 60
                    continue
                }

                // Skip past reminders
                if reminderDate <= now {
                    hour += intervalMinutes / 60
                    continue
                }

                let content = UNMutableNotificationContent()
                content.title = reminderMessage(for: hour).title
                content.body = reminderMessage(for: hour).body
                content.sound = .default
                content.categoryIdentifier = "HYDRATION_REMINDER"

                var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
                components.second = 0

                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "hydration_\(dayOffset)_\(hour)",
                    content: content,
                    trigger: trigger
                )

                do {
                    try await center.add(request)
                } catch {
                    print("[AquaFaste] Failed to schedule notification: \(error)")
                }

                hour += intervalMinutes / 60
            }
        }
    }

    // MARK: - Milestone Notifications

    func scheduleGoalCompleteNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Goal Complete! 💧"
        content.body = "You've reached your daily hydration goal. Great job staying hydrated!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "goal_complete", content: content, trigger: trigger)
        center.add(request)
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Messages

    private func reminderMessage(for hour: Int) -> (title: String, body: String) {
        let messages: [(String, String)] = [
            ("Time to hydrate! 💧", "A glass of water keeps you sharp and energized."),
            ("Water break! 🌊", "Your body needs water to perform its best."),
            ("Stay hydrated! 💦", "Even mild dehydration affects focus and mood."),
            ("Drink up! 🥤", "Regular sips throughout the day beat drinking all at once."),
            ("Hydration check ✅", "Have you had water recently? Your body will thank you."),
            ("Water time! 🫗", "Staying hydrated helps your skin, digestion, and energy."),
            ("Quick reminder 💧", "Take a moment to drink some water."),
            ("H₂O time! 🌿", "Hydration is the foundation of good health."),
        ]

        let index = hour % messages.count
        return messages[index]
    }
}

import Foundation

enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
    case sedentary
    case light
    case moderate
    case active
    case veryActive

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sedentary: "Sedentary"
        case .light: "Lightly Active"
        case .moderate: "Moderately Active"
        case .active: "Active"
        case .veryActive: "Very Active"
        }
    }

    var description: String {
        switch self {
        case .sedentary: "Desk job, minimal exercise"
        case .light: "Light exercise 1-3 days/week"
        case .moderate: "Moderate exercise 3-5 days/week"
        case .active: "Hard exercise 6-7 days/week"
        case .veryActive: "Athlete or very physical job"
        }
    }

    /// Activity multiplier for water goal calculation
    var multiplier: Double {
        switch self {
        case .sedentary: 1.0
        case .light: 1.1
        case .moderate: 1.2
        case .active: 1.35
        case .veryActive: 1.5
        }
    }
}

enum MeasurementUnit: String, Codable, CaseIterable {
    case ml
    case oz

    var displayName: String {
        switch self {
        case .ml: "ml"
        case .oz: "fl oz"
        }
    }

    /// Convert ml to display unit
    func fromMl(_ ml: Double) -> Double {
        switch self {
        case .ml: ml
        case .oz: ml / 29.5735
        }
    }

    /// Convert display unit to ml
    func toMl(_ value: Double) -> Double {
        switch self {
        case .ml: value
        case .oz: value * 29.5735
        }
    }

    func formatAmount(_ ml: Double) -> String {
        let value = fromMl(ml)
        if self == .ml {
            return "\(Int(value)) ml"
        } else {
            return String(format: "%.1f fl oz", value)
        }
    }
}

/// User profile stored in UserDefaults (lightweight, not SwiftData)
@Observable @MainActor
final class UserProfile {
    static let shared = UserProfile()

    private let defaults = UserDefaults.standard

    var weight: Double {
        get { defaults.double(forKey: "af_weight").nonZero ?? 70.0 }
        set { defaults.set(newValue, forKey: "af_weight") }
    }

    var activityLevel: ActivityLevel {
        get {
            guard let raw = defaults.string(forKey: "af_activity") else { return .moderate }
            return ActivityLevel(rawValue: raw) ?? .moderate
        }
        set { defaults.set(newValue.rawValue, forKey: "af_activity") }
    }

    var unit: MeasurementUnit {
        get {
            guard let raw = defaults.string(forKey: "af_unit") else { return .ml }
            return MeasurementUnit(rawValue: raw) ?? .ml
        }
        set { defaults.set(newValue.rawValue, forKey: "af_unit") }
    }

    var onboardingComplete: Bool {
        get { defaults.bool(forKey: "af_onboarding_complete") }
        set { defaults.set(newValue, forKey: "af_onboarding_complete") }
    }

    var reminderInterval: Int {
        get {
            let val = defaults.integer(forKey: "af_reminder_interval")
            return val > 0 ? val : 120 // default 2 hours
        }
        set { defaults.set(newValue, forKey: "af_reminder_interval") }
    }

    var sleepStart: Int {
        get {
            let val = defaults.integer(forKey: "af_sleep_start")
            return val > 0 ? val : 22 // 10 PM
        }
        set { defaults.set(newValue, forKey: "af_sleep_start") }
    }

    var sleepEnd: Int {
        get {
            let val = defaults.integer(forKey: "af_sleep_end")
            return val > 0 ? val : 7 // 7 AM
        }
        set { defaults.set(newValue, forKey: "af_sleep_end") }
    }

    var dailyGoalOverride: Double? {
        get {
            let val = defaults.double(forKey: "af_goal_override")
            return val > 0 ? val : nil
        }
        set { defaults.set(newValue ?? 0, forKey: "af_goal_override") }
    }

    /// Calculated daily goal in ml
    /// Formula: weight(kg) × 35ml × activity multiplier
    /// Based on IOM/EFSA research (hydration-science.md)
    var dailyGoal: Double {
        if let override = dailyGoalOverride { return override }
        return weight * 35.0 * activityLevel.multiplier
    }

    // Streak tracking
    var currentStreak: Int {
        get { defaults.integer(forKey: "af_streak") }
        set { defaults.set(newValue, forKey: "af_streak") }
    }

    var lastGoalMetDate: Date? {
        get { defaults.object(forKey: "af_last_goal_date") as? Date }
        set { defaults.set(newValue, forKey: "af_last_goal_date") }
    }

    /// Cup presets in ml
    var cupPresets: [Double] {
        get {
            let data = defaults.array(forKey: "af_cups") as? [Double]
            return data ?? [250, 350, 500]
        }
        set { defaults.set(newValue, forKey: "af_cups") }
    }

    /// Cup preset names (parallel array with cupPresets)
    var cupPresetNames: [String] {
        get {
            let data = defaults.array(forKey: "af_cup_names") as? [String]
            return data ?? ["Small", "Medium", "Large"]
        }
        set { defaults.set(newValue, forKey: "af_cup_names") }
    }

    /// Refill reminder — bottle size in ml
    var bottleSize: Double {
        get {
            let val = defaults.double(forKey: "af_bottle_size")
            return val > 0 ? val : 500
        }
        set { defaults.set(newValue, forKey: "af_bottle_size") }
    }

    /// Whether refill reminders are enabled
    var refillReminderEnabled: Bool {
        get { defaults.object(forKey: "af_refill_reminder") == nil ? false : defaults.bool(forKey: "af_refill_reminder") }
        set { defaults.set(newValue, forKey: "af_refill_reminder") }
    }

    /// Last saved timezone identifier — for detecting timezone changes
    var lastTimezoneIdentifier: String {
        get { defaults.string(forKey: "af_timezone") ?? TimeZone.current.identifier }
        set { defaults.set(newValue, forKey: "af_timezone") }
    }

    // MARK: - Notification Preferences

    /// Master toggle — all reminders
    var remindersEnabled: Bool {
        get { defaults.object(forKey: "af_reminders_enabled") == nil ? true : defaults.bool(forKey: "af_reminders_enabled") }
        set { defaults.set(newValue, forKey: "af_reminders_enabled") }
    }

    /// Morning 'Start your day with water!' reminder
    var morningReminderEnabled: Bool {
        get { defaults.object(forKey: "af_morning_reminder") == nil ? true : defaults.bool(forKey: "af_morning_reminder") }
        set { defaults.set(newValue, forKey: "af_morning_reminder") }
    }

    /// Evening summary notification
    var eveningSummaryEnabled: Bool {
        get { defaults.object(forKey: "af_evening_summary") == nil ? true : defaults.bool(forKey: "af_evening_summary") }
        set { defaults.set(newValue, forKey: "af_evening_summary") }
    }

    /// Goal completion celebration
    var goalCelebrationEnabled: Bool {
        get { defaults.object(forKey: "af_goal_celebration") == nil ? true : defaults.bool(forKey: "af_goal_celebration") }
        set { defaults.set(newValue, forKey: "af_goal_celebration") }
    }

    /// Streak reminder
    var streakReminderEnabled: Bool {
        get { defaults.object(forKey: "af_streak_reminder") == nil ? true : defaults.bool(forKey: "af_streak_reminder") }
        set { defaults.set(newValue, forKey: "af_streak_reminder") }
    }

    private init() {}
}

private extension Double {
    var nonZero: Double? {
        self > 0 ? self : nil
    }
}

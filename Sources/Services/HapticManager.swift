import UIKit
import AudioToolbox

/// Centralized haptic + sound feedback for the app.
/// All feedback fires on MainActor to avoid threading issues with UIKit generators.
@MainActor
final class HapticManager {
    static let shared = HapticManager()

    // Pre-warmed generators for responsiveness
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let softGenerator = UIImpactFeedbackGenerator(style: .soft)
    private let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()

    private init() {
        // Pre-warm on creation so first trigger is instant
        lightGenerator.prepare()
        mediumGenerator.prepare()
        softGenerator.prepare()
        rigidGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }

    // MARK: - Core Patterns

    func light() {
        lightGenerator.impactOccurred()
        lightGenerator.prepare()
    }

    func medium() {
        mediumGenerator.impactOccurred()
        mediumGenerator.prepare()
    }

    func success() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }

    func error() {
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }

    func selectionChanged() {
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }

    // MARK: - Semantic Actions

    /// Log a drink — satisfying medium impact
    func logDrink() {
        mediumGenerator.impactOccurred()
        mediumGenerator.prepare()
    }

    /// Delete a drink — warning notification
    func deleteDrink() {
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }

    /// Goal complete celebration — success notification
    func goalComplete() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }

    /// Tab or segment change — selection feedback
    func tabChange() {
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }

    /// Generic button press — light impact
    func buttonPress() {
        lightGenerator.impactOccurred()
        lightGenerator.prepare()
    }

    /// Streak milestone reached — success notification
    func streakMilestone() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }

    /// Slider value changed — selection feedback
    func sliderChanged() {
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }

    /// Sheet presented — soft impact
    func sheetPresented() {
        softGenerator.impactOccurred()
        softGenerator.prepare()
    }

    /// Toggle changed — rigid impact
    func toggleChanged() {
        rigidGenerator.impactOccurred()
        rigidGenerator.prepare()
    }

    // MARK: - Composite Feedback

    /// Satisfying splash feel for water logging — medium impact + subtle click sound
    func waterLogged() {
        mediumGenerator.impactOccurred(intensity: 0.8)
        mediumGenerator.prepare()
        AudioServicesPlaySystemSound(1104) // subtle click
    }

    /// Drink type selection changed
    func drinkSelected() {
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }
}

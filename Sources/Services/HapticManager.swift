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
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()

    private init() {
        // Pre-warm on creation so first trigger is instant
        lightGenerator.prepare()
        mediumGenerator.prepare()
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

    // MARK: - Composite Feedback

    /// Satisfying splash feel for water logging — medium impact + subtle click sound
    func waterLogged() {
        mediumGenerator.impactOccurred(intensity: 0.8)
        mediumGenerator.prepare()
        AudioServicesPlaySystemSound(1104) // subtle click
    }

    /// Celebration for goal completion — success haptic + triumph sound
    func goalComplete() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
        AudioServicesPlaySystemSound(1025) // celebration chime
    }

    /// Drink type selection changed
    func drinkSelected() {
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }
}

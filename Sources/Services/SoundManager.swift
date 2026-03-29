import AudioToolbox
import SwiftUI

/// Centralized sound feedback manager.
/// Uses system sounds for lightweight audio cues — no custom audio files needed.
@MainActor @Observable
final class SoundManager {
    static let shared = SoundManager()

    @ObservationIgnored
    @AppStorage("af_sound_enabled") var soundEnabled: Bool = true

    // MARK: - System Sound IDs

    private enum SoundID {
        static let logDrink: SystemSoundID = 1104 // subtle key click
        static let delete: SystemSoundID = 1155 // delete swoosh
        static let goalComplete: SystemSoundID = 1025 // positive chime
        static let error: SystemSoundID = 1053 // error tone
        static let celebration: SystemSoundID = 1026 // celebration flourish
    }

    private init() {}

    // MARK: - Playback

    /// Subtle click when logging a drink
    func playLogSound() {
        play(SoundID.logDrink)
    }

    /// Swoosh for delete actions
    func playDeleteSound() {
        play(SoundID.delete)
    }

    /// Positive chime when daily goal is reached
    func playGoalComplete() {
        play(SoundID.goalComplete)
    }

    /// Error tone for failures
    func playError() {
        play(SoundID.error)
    }

    /// Celebration flourish for confetti / milestones
    func playCelebration() {
        play(SoundID.celebration)
    }

    // MARK: - Private

    private func play(_ soundID: SystemSoundID) {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(soundID)
    }
}

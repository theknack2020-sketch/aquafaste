import StoreKit
import SwiftUI

@Observable @MainActor
final class WinBackManager {
    static let shared = WinBackManager()

    var showWinBackOffer = false
    var lapsedDays: Int = 0

    private let defaults = UserDefaults.standard
    private let lastActiveKey = "af_last_active_date"
    private let winBackShownKey = "af_winback_shown"

    /// Check if user is lapsed (3+ days inactive) and show win-back
    func checkLapsedUser() {
        let lastActive = defaults.double(forKey: lastActiveKey)
        guard lastActive > 0 else {
            recordActivity()
            return
        }

        let lastDate = Date(timeIntervalSince1970: lastActive)
        let days = Calendar.current.dateComponents([.day], from: lastDate, to: .now).day ?? 0

        if days >= 3 {
            lapsedDays = days
            let alreadyShown = defaults.bool(forKey: winBackShownKey)
            if !alreadyShown {
                showWinBackOffer = true
                defaults.set(true, forKey: winBackShownKey)
            }
        }

        recordActivity()
    }

    func recordActivity() {
        defaults.set(Date().timeIntervalSince1970, forKey: lastActiveKey)
    }

    func resetWinBack() {
        defaults.set(false, forKey: winBackShownKey)
    }
}

// MARK: - Win-Back Overlay View

struct WinBackOverlay: View {
    let daysAway: Int
    let onDismiss: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(appeared ? 0.5 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 20) {
                // Icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.cyan.opacity(0.2), .blue.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 80, height: 80)
                    Image(systemName: "drop.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom))
                        .shadow(color: .cyan.opacity(0.5), radius: 12, y: 4)
                }

                Text("We Missed You! 💧")
                    .font(.system(size: 24, weight: .bold, design: .rounded))

                Text("You've been away for \(daysAway) days.\nYour body needs hydration — let's get back on track!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Stats reminder
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Image(systemName: "flame.fill").foregroundStyle(.orange)
                        Text("Streak\nLost")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise").foregroundStyle(.blue)
                        Text("Easy\nRestart")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    VStack(spacing: 4) {
                        Image(systemName: "trophy.fill").foregroundStyle(.yellow)
                        Text("Earn\nBack")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }

                // CTA
                Button {
                    dismiss()
                } label: {
                    Text("Start Fresh Today")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(colors: [.cyan, .blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                }
                .shadow(color: .cyan.opacity(0.3), radius: 10, y: 5)
            }
            .padding(28)
            .frame(maxWidth: 340)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.2), radius: 24, y: 12)
            .scaleEffect(appeared ? 1 : 0.7)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { appeared = true }
        }
    }

    private func dismiss() {
        withAnimation(.easeIn(duration: 0.2)) { appeared = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { onDismiss() }
    }
}

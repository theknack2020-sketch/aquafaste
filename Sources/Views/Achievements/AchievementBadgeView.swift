import SwiftUI

/// Circular badge displaying an achievement with tier-colored ring, icon, and title.
struct AchievementBadgeView: View {
    let achievement: Achievement

    @State private var appeared = false

    private let theme = ThemeManager.shared.effectiveTheme

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // Tier ring
                Circle()
                    .stroke(
                        achievement.isUnlocked
                            ? achievement.tier.color.opacity(0.3)
                            : Color.gray.opacity(0.15),
                        lineWidth: 3
                    )
                    .frame(width: 72, height: 72)

                Circle()
                    .fill(
                        achievement.isUnlocked
                            ? achievement.tier.color.opacity(0.12)
                            : Color.gray.opacity(0.06)
                    )
                    .frame(width: 66, height: 66)

                // Icon
                Image(systemName: achievement.iconName)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(
                        achievement.isUnlocked
                            ? achievement.tier.color
                            : Color.gray.opacity(0.35)
                    )
                    .symbolEffect(.bounce, value: appeared && achievement.isUnlocked)

                // Lock overlay
                if !achievement.isUnlocked {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 66, height: 66)

                    Image(systemName: "lock.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                // Checkmark for unlocked
                if achievement.isUnlocked {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.green)
                                .background(
                                    Circle()
                                        .fill(Color(.systemBackground))
                                        .frame(width: 16, height: 16)
                                )
                        }
                        Spacer()
                    }
                    .frame(width: 72, height: 72)
                }
            }
            .scaleEffect(appeared ? 1.0 : 0.7)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.6),
                value: appeared
            )

            // Title
            Text(achievement.title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(achievement.isUnlocked ? .primary : .secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            // Subtitle or unlock date
            if achievement.isUnlocked, let date = achievement.unlockedAt {
                Text(date, format: .dateTime.month(.abbreviated).day())
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(.tertiary)
            } else {
                Text(achievement.subtitle)
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: theme.cardShadow, radius: 6, x: 0, y: 3)
        )
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
                appeared = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(achievement.title), \(achievement.isUnlocked ? "unlocked" : "locked"). \(achievement.subtitle)")
        .accessibilityAddTraits(achievement.isUnlocked ? [] : .isButton)
    }
}

// MARK: - Achievement Celebration Overlay

/// Full-screen overlay shown when an achievement is unlocked.
struct AchievementCelebrationOverlay: View {
    let achievement: Achievement
    let onDismiss: () -> Void

    @State private var showContent = false
    @State private var showConfetti = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            // Confetti
            if showConfetti && !reduceMotion {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // Achievement card
            VStack(spacing: 20) {
                Text("🏆")
                    .font(.system(size: 48))

                Text("Achievement Unlocked!")
                    .font(.system(size: 22, weight: .bold, design: .rounded))

                ZStack {
                    Circle()
                        .fill(achievement.tier.color.opacity(0.15))
                        .frame(width: 88, height: 88)

                    Circle()
                        .stroke(achievement.tier.color, lineWidth: 3)
                        .frame(width: 88, height: 88)

                    Image(systemName: achievement.iconName)
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(achievement.tier.color)
                }

                VStack(spacing: 6) {
                    Text(achievement.title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))

                    Text(achievement.subtitle)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)

                    Text(achievement.tier.displayName)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(achievement.tier.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(achievement.tier.color.opacity(0.12))
                        )
                }

                Button {
                    dismiss()
                } label: {
                    Text("Awesome!")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.aquaPrimary)
                        )
                }
                .padding(.top, 4)
                .accessibilityLabel("Dismiss achievement celebration")
                .accessibilityIdentifier("achievementCelebrationDismiss")
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.2), radius: 24, x: 0, y: 12)
            )
            .padding(.horizontal, 32)
            .scaleEffect(showContent ? 1 : 0.6)
            .opacity(showContent ? 1 : 0)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Achievement unlocked: \(achievement.title). \(achievement.subtitle)")
            .accessibilityAddTraits(.isModal)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showContent = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showConfetti = true
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            showContent = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDismiss()
        }
    }
}

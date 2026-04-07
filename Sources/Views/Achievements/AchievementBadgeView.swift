import SwiftUI

/// Circular badge displaying an achievement with tier-colored ring, icon, and title.
struct AchievementBadgeView: View {
    let achievement: Achievement

    @State private var appeared = false
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool {
        sizeClass == .regular
    }

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
                    .frame(width: isRegular ? 88 : 72, height: isRegular ? 88 : 72)

                Circle()
                    .fill(
                        achievement.isUnlocked
                            ? achievement.tier.color.opacity(0.12)
                            : Color.gray.opacity(0.06)
                    )
                    .frame(width: isRegular ? 82 : 66, height: isRegular ? 82 : 66)

                // Icon
                Image(systemName: achievement.iconName)
                    .font(.adaptiveDisplay(size: 28, weight: .medium, isRegular: isRegular))
                    .foregroundStyle(
                        achievement.isUnlocked
                            ? achievement.tier.color
                            : Color.gray.opacity(0.35)
                    )
                    .symbolEffect(.bounce, value: appeared && achievement.isUnlocked)
                    .accessibilityHidden(true)

                // Lock overlay
                if !achievement.isUnlocked {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: isRegular ? 82 : 66, height: isRegular ? 82 : 66)

                    Image(systemName: "lock.fill")
                        .font(.adaptiveCaption(isRegular: isRegular).weight(.medium))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }

                // Checkmark for unlocked
                if achievement.isUnlocked {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.adaptiveSubheadline(isRegular: isRegular))
                                .foregroundStyle(.green)
                                .accessibilityHidden(true)
                                .background(
                                    Circle()
                                        .fill(Color(.systemBackground))
                                        .frame(width: 16, height: 16)
                                )
                        }
                        Spacer()
                    }
                    .frame(width: isRegular ? 88 : 72, height: isRegular ? 88 : 72)
                }
            }
            .scaleEffect(appeared ? 1.0 : 0.7)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.6),
                value: appeared
            )

            // Title
            Text(achievement.title)
                .font(.adaptiveCaption(isRegular: isRegular).weight(.semibold))
                .foregroundStyle(achievement.isUnlocked ? .primary : .secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            // Subtitle or unlock date
            if achievement.isUnlocked, let date = achievement.unlockedAt {
                Text(date, format: .dateTime.month(.abbreviated).day())
                    .font(.adaptiveCaption2(isRegular: isRegular))
                    .foregroundStyle(.tertiary)
            } else {
                Text(achievement.subtitle)
                    .font(.adaptiveCaption2(isRegular: isRegular))
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
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool {
        sizeClass == .regular
    }

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            // Confetti
            if showConfetti, !reduceMotion {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // Achievement card
            VStack(spacing: 20) {
                Text("🏆")
                    .font(.adaptiveDisplay(size: 48, weight: .regular, isRegular: isRegular))

                Text("Achievement Unlocked!")
                    .font(.adaptiveDisplay(size: 22, weight: .bold, design: .rounded, isRegular: isRegular))

                ZStack {
                    Circle()
                        .fill(achievement.tier.color.opacity(0.15))
                        .frame(width: isRegular ? 110 : 88, height: isRegular ? 110 : 88)

                    Circle()
                        .stroke(achievement.tier.color, lineWidth: 3)
                        .frame(width: isRegular ? 110 : 88, height: isRegular ? 110 : 88)

                    Image(systemName: achievement.iconName)
                        .font(.adaptiveDisplay(size: 36, weight: .medium, isRegular: isRegular))
                        .foregroundStyle(achievement.tier.color)
                        .accessibilityHidden(true)
                }

                VStack(spacing: 6) {
                    Text(achievement.title)
                        .font(.adaptiveTitle3(isRegular: isRegular).weight(.bold))

                    Text(achievement.subtitle)
                        .font(.adaptiveCaption(isRegular: isRegular))
                        .foregroundStyle(.secondary)

                    Text(achievement.tier.displayName)
                        .font(.adaptiveCaption(isRegular: isRegular).weight(.semibold))
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
                        .font(.adaptiveSubheadline(isRegular: isRegular).weight(.semibold))
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
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            showContent = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDismiss()
        }
    }
}

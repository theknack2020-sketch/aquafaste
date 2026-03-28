import SwiftUI
import SwiftData

/// Grid view displaying all achievements grouped by category.
struct AchievementsView: View {
    @Environment(\.modelContext) private var modelContext

    private let manager = AchievementManager.shared
    private let theme = ThemeManager.shared.effectiveTheme

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Progress header
                    progressHeader

                    // Empty state when no achievements unlocked
                    if manager.unlockedCount == 0 {
                        VStack(spacing: 16) {
                            Image(systemName: "trophy")
                                .font(.system(size: 60))
                                .foregroundStyle(theme.primary)
                                .symbolEffect(.pulse)

                            Text("Your Trophy Case Awaits")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(Color.primary)

                            Text("Start tracking to unlock your first achievement. Every streak starts with day one!")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(40)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Your trophy case awaits. Start tracking to unlock your first achievement.")
                    }

                    // Achievement grid by category
                    LazyVStack(spacing: 24) {
                        ForEach(manager.groupedByCategory, id: \.category) { group in
                            categorySection(group.category, items: group.items)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Achievements")
            .background(Color(.systemGroupedBackground))
            .aquaBackgroundGradient()
            .onAppear {
                manager.setupAchievements(context: modelContext)
            }
        }
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(spacing: 12) {
            // Trophy icon with glow
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.10))
                    .frame(width: 64, height: 64)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(theme.primary)
            }

            // Counter
            HStack(spacing: 4) {
                Text("\(manager.unlockedCount)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.primary)
                    .contentTransition(.numericText())

                Text("of \(manager.totalCount)")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)

                Text("Unlocked")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 2)
            }

            // Progress bar
            GeometryReader { geo in
                let ratio = manager.totalCount > 0
                    ? CGFloat(manager.unlockedCount) / CGFloat(manager.totalCount)
                    : 0

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.12))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.gradient)
                        .frame(width: geo.size.width * ratio, height: 6)
                        .animation(.spring(response: 0.5), value: ratio)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 40)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: theme.cardShadow, radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(manager.unlockedCount) of \(manager.totalCount) achievements unlocked")
        .accessibilityIdentifier("achievementsProgressHeader")
    }

    // MARK: - Category Section

    private func categorySection(_ category: AchievementCategory, items: [Achievement]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 6) {
                Image(systemName: category.iconName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.primary.opacity(0.70))

                Text(category.displayName)
                    .aquaSectionHeader(theme: theme)
            }
            .padding(.leading, 4)
            .accessibilityAddTraits(.isHeader)
            .accessibilityLabel("\(category.displayName) achievements")
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(items, id: \.id) { achievement in
                    AchievementBadgeView(achievement: achievement)
                }
            }
        }
    }
}

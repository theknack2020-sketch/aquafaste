import SwiftData
import SwiftUI

/// Grid view displaying all achievements grouped by category.
struct AchievementsView: View {
    @Environment(\.modelContext) private var modelContext

    private let manager = AchievementManager.shared
    private let theme = ThemeManager.shared.effectiveTheme
    private let haptics = HapticManager.shared

    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isRegular: Bool {
        sizeClass == .regular
    }

    private var columns: [GridItem] {
        let count = isRegular ? 4 : 3
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Progress header
                    progressHeader

                    // Empty state when no achievements unlocked
                    if manager.unlockedCount == 0 {
                        ContentUnavailableView {
                            Label("Your Trophy Case Awaits", systemImage: "trophy")
                        } description: {
                            Text("Start tracking to unlock your first achievement. Every streak starts with day one!")
                        }
                        .symbolEffect(.pulse)
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
                HapticManager.shared.tabChange()
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
                    .font(.adaptiveDisplay(size: 28, weight: .medium, isRegular: isRegular))
                    .foregroundStyle(theme.primary)
                    .symbolEffect(.bounce, value: manager.unlockedCount)
                    .accessibilityHidden(true)
            }

            // Counter
            HStack(spacing: 4) {
                Text("\(manager.unlockedCount)")
                    .font(.adaptiveDisplay(size: 28, weight: .bold, design: .rounded, isRegular: isRegular))
                    .foregroundStyle(theme.primary)
                    .contentTransition(.numericText())

                Text("of \(manager.totalCount)")
                    .font(.adaptiveTitle3(isRegular: isRegular).weight(.medium))
                    .foregroundStyle(.secondary)

                Text("Unlocked")
                    .font(.adaptiveCaption(isRegular: isRegular))
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
                    .font(.adaptiveCaption(isRegular: isRegular).weight(.semibold))
                    .foregroundStyle(theme.primary.opacity(0.70))
                    .accessibilityHidden(true)

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

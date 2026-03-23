import SwiftUI

struct DrinkPickerView: View {
    @Binding var selectedDrink: DrinkType
    @Environment(\.dismiss) private var dismiss

    private let haptics = HapticManager.shared

    // Group drinks by category
    private var groupedDrinks: [(category: DrinkCategory, drinks: [DrinkType])] {
        let grouped = Dictionary(grouping: DrinkType.allCases) { $0.category }
        return DrinkCategory.allCases.compactMap { category in
            guard let drinks = grouped[category], !drinks.isEmpty else { return nil }
            return (category: category, drinks: drinks)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Selected drink preview
                    selectedPreview

                    // Categorized drink grid
                    ForEach(groupedDrinks, id: \.category) { group in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(group.category.rawValue)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.aquaTextSecondary)
                                .padding(.horizontal, 4)

                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ],
                                spacing: 12
                            ) {
                                ForEach(group.drinks) { drink in
                                    DrinkTile(
                                        drink: drink,
                                        isSelected: drink == selectedDrink
                                    ) {
                                        haptics.drinkSelected()
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedDrink = drink
                                        }
                                        // Dismiss after brief delay so user sees selection
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                            dismiss()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Drink")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .accessibilityLabel("Done, close drink picker")
                }
            }
        }
    }

    // MARK: - Selected Preview

    private var selectedPreview: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(selectedDrink.color.opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: selectedDrink.iconName)
                    .font(.title2)
                    .foregroundStyle(selectedDrink.color)
                    .symbolEffect(.bounce, value: selectedDrink)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(selectedDrink.displayName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.aquaTextPrimary)

                HStack(spacing: 12) {
                    Label(
                        "\(Int(selectedDrink.hydrationRatio * 100))% hydration",
                        systemImage: "drop.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(Color.aquaPrimary)

                    if selectedDrink.hasCaffeine {
                        Label(
                            "\(Int(selectedDrink.caffeinePer250ml))mg caffeine",
                            systemImage: "cup.and.saucer.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(.brown)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.aquaCardBackground, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Drink Tile

struct DrinkTile: View {
    let drink: DrinkType
    let isSelected: Bool
    let action: () -> Void

    @State private var tileScale: CGFloat = 1.0

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                tileScale = 0.9
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    tileScale = 1.0
                }
            }
            action()
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                                ? drink.color.opacity(0.25)
                                : drink.color.opacity(0.1)
                        )
                        .frame(width: 52, height: 52)

                    // Subtle ring for selected
                    if isSelected {
                        Circle()
                            .strokeBorder(drink.color, lineWidth: 2.5)
                            .frame(width: 52, height: 52)
                    }

                    Image(systemName: drink.iconName)
                        .font(.title3)
                        .foregroundStyle(drink.color)
                }

                Text(drink.displayName)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Color.aquaTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                // Hydration ratio badge
                HStack(spacing: 2) {
                    if drink.hasCaffeine {
                        Text("☕")
                            .font(.system(size: 8))
                    }
                    Text("\(Int(drink.hydrationRatio * 100))%")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(
                            drink.hydrationRatio >= 1.0 ? .green :
                            drink.hydrationRatio >= 0.7 ? Color.aquaPrimary : .orange
                        )
                }
            }
            .padding(.vertical, 4)
            .scaleEffect(tileScale)
        }
        .accessibilityLabel("\(drink.displayName), \(Int(drink.hydrationRatio * 100)) percent hydration\(drink.hasCaffeine ? ", contains caffeine" : "")")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to select")
    }
}

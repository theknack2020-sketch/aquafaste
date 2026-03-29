import SwiftUI

struct DrinkPickerView: View {
    @Binding var selectedDrink: DrinkType
    @Environment(\.dismiss) private var dismiss

    private let haptics = HapticManager.shared
    private let sounds = SoundManager.shared

    /// Group drinks by category
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
                            HStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.aquaGradientStart, Color.aquaGradientEnd],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 3, height: 16)
                                Text(group.category.rawValue)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.aquaTextSecondary)
                            }
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
                    Button("Done") {
                        haptics.buttonPress()
                        dismiss()
                    }
                    .accessibilityLabel("Done, close drink picker")
                    .accessibilityIdentifier("drinkPickerDoneButton")
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

                Text(hydrationEfficiencyText(for: selectedDrink))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding()
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.aquaCardBackground)
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [selectedDrink.color.opacity(0.08), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .shadow(color: selectedDrink.color.opacity(0.15), radius: 10, x: 0, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Selected: \(selectedDrink.displayName), \(Int(selectedDrink.hydrationRatio * 100)) percent hydration\(selectedDrink.hasCaffeine ? ", \(Int(selectedDrink.caffeinePer250ml)) milligrams caffeine" : "")")
    }

    // MARK: - Hydration Efficiency

    private func hydrationEfficiencyText(for drink: DrinkType) -> String {
        switch drink {
        case .water: "Pure hydration — the gold standard"
        case .coffee: "Coffee: 85% hydration • mild diuretic"
        case .tea: "Tea: 90% hydration • less caffeine than coffee"
        case .juice: "Juice: 130% hydration • electrolytes boost"
        case .milk: "Milk: 150% hydration • superior to water (research)"
        case .soda: "Soda: 70% hydration • sugar + caffeine reduce effect"
        case .sparklingWater: "Same as still water — 100% hydration"
        case .coconutWater: "Coconut: 110% hydration • natural electrolytes"
        case .smoothie: "Smoothie: 90% hydration • nutrient-rich"
        case .soup: "Soup: 80% hydration • sodium affects ratio"
        case .beer: "Beer: 40% hydration • alcohol is dehydrating"
        case .wine: "Wine: 30% hydration • high alcohol reduces effect"
        }
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
                                ? LinearGradient(
                                    colors: [drink.color.opacity(0.3), drink.color.opacity(0.12)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [drink.color.opacity(0.12), drink.color.opacity(0.06)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .frame(width: 52, height: 52)
                        .shadow(color: drink.color.opacity(isSelected ? 0.3 : 0.1), radius: isSelected ? 8 : 4, x: 0, y: 2)

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

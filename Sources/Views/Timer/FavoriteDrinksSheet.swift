import SwiftUI

struct FavoriteDrinksSheet: View {
    @Environment(HydrationManager.self) private var manager
    @Environment(\.dismiss) private var dismiss

    private let haptics = HapticManager.shared
    private let sounds = SoundManager.shared

    @State private var showAddSheet = false
    @State private var newName = ""
    @State private var newDrinkType: DrinkType = .water
    @State private var newAmount: String = "250"

    private let profile = UserProfile.shared

    var body: some View {
        NavigationStack {
            let favorites = manager.fetchFavorites()

            Group {
                if favorites.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(favorites, id: \.id) { fav in
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(fav.drink.color.opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: fav.drink.iconName)
                                        .font(.body)
                                        .foregroundStyle(fav.drink.color)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(fav.name)
                                        .font(.subheadline.weight(.medium))
                                    HStack(spacing: 4) {
                                        Text(fav.drink.displayName)
                                        Text("•")
                                        Text(profile.unit.formatAmount(fav.amount))
                                        if fav.caffeineAmount > 0 {
                                            Text("• \(Int(fav.caffeineAmount))mg ☕")
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                        }
                        .onDelete { indexSet in
                            haptics.deleteDrink()
                            sounds.playDeleteSound()
                            let favs = manager.fetchFavorites()
                            for index in indexSet {
                                manager.deleteFavorite(favs[index])
                            }
                        }
                    }
                }
            }
            .navigationTitle("Favorite Drinks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("favoritesDoneButton")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        haptics.buttonPress()
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add new favorite drink")
                    .accessibilityIdentifier("addFavoriteButton")
                }
            }
            .alert("New Favorite", isPresented: $showAddSheet) {
                TextField("Name", text: $newName)
                TextField(profile.unit == .ml ? "Amount (ml)" : "Amount (fl oz)", text: $newAmount)
                    .keyboardType(.numberPad)
                Button("Add") {
                    if !newName.isEmpty, let amount = Double(newAmount), amount > 0 {
                        let ml = profile.unit.toMl(amount)
                        manager.addFavorite(
                            name: newName,
                            drinkType: newDrinkType,
                            amount: ml,
                            caffeineMg: newDrinkType.caffeinePer250ml * ml / 250.0
                        )
                    }
                    newName = ""
                    newAmount = "250"
                }
                Button("Cancel", role: .cancel) {
                    newName = ""
                    newAmount = "250"
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "star.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.aquaPrimary.opacity(0.3))

            Text("No Favorites Yet")
                .font(.headline)

            Text("Save your most-used drinks for quick access.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Add a Favorite") {
                haptics.buttonPress()
                showAddSheet = true
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.aquaPrimary)
            .accessibilityIdentifier("addFirstFavoriteButton")

            Spacer()
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No favorites yet. Save your most-used drinks for quick access.")
    }
}

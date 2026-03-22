import SwiftUI

struct DrinkPickerView: View {
    @Binding var selectedDrink: DrinkType
    @Environment(\.dismiss) private var dismiss

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(DrinkType.allCases) { drink in
                        Button {
                            selectedDrink = drink
                            dismiss()
                        } label: {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(drink.color.opacity(0.15))
                                        .frame(width: 56, height: 56)

                                    Image(systemName: drink.iconName)
                                        .font(.title2)
                                        .foregroundStyle(drink.color)
                                }

                                Text(drink.displayName)
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(Color.aquaTextPrimary)
                                    .lineLimit(1)

                                Text("\(Int(drink.hydrationRatio * 100))%")
                                    .font(.caption2)
                                    .foregroundStyle(Color.aquaTextSecondary)
                            }
                            .padding(.vertical, 4)
                            .overlay {
                                if drink == selectedDrink {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.aquaPrimary, lineWidth: 2)
                                        .padding(-4)
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
                }
            }
        }
    }
}

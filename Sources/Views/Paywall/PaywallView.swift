import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var products: [Product] = []
    @State private var isLoading = true
    @State private var purchaseInProgress = false
    @State private var errorMessage: String?

    private let manager = SubscriptionManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.aquaGradient)

                        Text("AquaFaste Premium")
                            .font(.title2.weight(.bold))

                        Text("Unlock the full hydration experience")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)

                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        featureRow(icon: "cup.and.saucer.fill", title: "Custom Drinks", description: "Create unlimited custom beverages")
                        featureRow(icon: "bell.badge.fill", title: "Smart Reminders", description: "Adaptive reminders that learn your habits")
                        featureRow(icon: "paintpalette.fill", title: "Themes", description: "Beautiful color themes and accent colors")
                        featureRow(icon: "chart.line.uptrend.xyaxis", title: "Detailed Stats", description: "Monthly trends, charts, and data export")
                        featureRow(icon: "arrow.counterclockwise", title: "Streak Recovery", description: "Freeze and recover your streaks")
                    }
                    .padding(.horizontal)

                    // Products
                    if isLoading {
                        ProgressView()
                            .padding()
                    } else {
                        VStack(spacing: 12) {
                            ForEach(products.sorted(by: { productSortOrder($0) < productSortOrder($1) })) { product in
                                ProductButton(product: product, isPopular: product.id == SubscriptionManager.yearlyID) {
                                    await purchase(product)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Error
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    // Restore
                    Button("Restore Purchases") {
                        Task {
                            await manager.restorePurchases()
                            if manager.isPremium { dismiss() }
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    // Legal
                    VStack(spacing: 4) {
                        Text("Payment will be charged to your Apple ID account. Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 16) {
                            Link("Privacy Policy", destination: URL(string: "https://theknack2020-sketch.github.io/aquafaste/privacy/")!)
                            Link("Terms of Use", destination: URL(string: "https://theknack2020-sketch.github.io/aquafaste/terms/")!)
                        }
                        .font(.caption2)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .task { await loadProducts() }
            .disabled(purchaseInProgress)
            .overlay {
                if purchaseInProgress {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    ProgressView("Processing...")
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.aquaPrimary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func loadProducts() async {
        do {
            products = try await Product.products(for: [
                SubscriptionManager.monthlyID,
                SubscriptionManager.yearlyID,
                SubscriptionManager.lifetimeID
            ])
        } catch {
            errorMessage = "Failed to load products"
        }
        isLoading = false
    }

    private func purchase(_ product: Product) async {
        purchaseInProgress = true
        errorMessage = nil
        do {
            let success = try await manager.purchase(product)
            if success { dismiss() }
        } catch {
            errorMessage = "Purchase failed. Please try again."
        }
        purchaseInProgress = false
    }

    private func productSortOrder(_ product: Product) -> Int {
        switch product.id {
        case SubscriptionManager.yearlyID: return 0
        case SubscriptionManager.monthlyID: return 1
        case SubscriptionManager.lifetimeID: return 2
        default: return 3
        }
    }
}

// MARK: - Product Button

struct ProductButton: View {
    let product: Product
    let isPopular: Bool
    let action: () async -> Void

    var body: some View {
        Button {
            Task { await action() }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(product.displayName)
                            .font(.subheadline.weight(.semibold))
                        if isPopular {
                            Text("BEST VALUE")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange, in: Capsule())
                                .foregroundStyle(.white)
                        }
                    }

                    if let intro = product.subscription?.introductoryOffer,
                       intro.paymentMode == .freeTrial {
                        Text("7-day free trial")
                            .font(.caption)
                            .foregroundStyle(Color.aquaPrimary)
                    }
                }

                Spacer()

                Text(product.displayPrice)
                    .font(.subheadline.weight(.bold))

                if product.type == .autoRenewable {
                    Text(product.id == SubscriptionManager.yearlyID ? "/year" : "/month")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                isPopular
                    ? AnyShapeStyle(Color.aquaGradient)
                    : AnyShapeStyle(Color.aquaCardBackground),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .foregroundStyle(isPopular ? .white : Color.aquaTextPrimary)
        }
    }
}

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var products: [Product] = []
    @State private var isLoading = true
    @State private var purchaseInProgress = false
    @State private var errorMessage: String?
    @State private var selectedProductID: String = SubscriptionManager.yearlyID
    @State private var showRestoreAlert = false
    @State private var restoreSuccess = false

    private let manager = SubscriptionManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    socialProofBadge
                    featureComparisonTable
                    productSection
                    purchaseButton
                    restoreButton
                    termsDisclosure
                }
                .padding(.bottom, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.secondary)
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
            .alert(
                restoreSuccess ? "Purchases Restored!" : "No Purchases Found",
                isPresented: $showRestoreAlert
            ) {
                Button("OK") {
                    if restoreSuccess { dismiss() }
                }
            } message: {
                Text(
                    restoreSuccess
                        ? "Your premium access has been restored successfully."
                        : "We couldn't find any previous purchases for this Apple ID. If you believe this is an error, please contact support."
                )
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "drop.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.aquaGradient)
                .padding(.top, 20)

            Text("Upgrade to Premium")
                .font(.title2.weight(.bold))

            Text("Unlock the full hydration experience")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Social Proof

    private var socialProofBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "person.3.fill")
                .font(.caption)
                .foregroundStyle(Color.aquaPrimary)
            Text("Join 5,000+ hydrated users")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.aquaPrimary.opacity(0.08), in: Capsule())
    }

    // MARK: - Feature Comparison Table

    private var featureComparisonTable: some View {
        VStack(spacing: 0) {
            // Header row
            HStack {
                Text("Features")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("Free")
                    .font(.caption.weight(.semibold))
                    .frame(width: 50)
                Text("Pro")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.aquaPrimary)
                    .frame(width: 50)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.aquaCardBackground)

            Divider()

            comparisonRow("Water Tracking", free: true, pro: true)
            comparisonRow("Daily Goal", free: true, pro: true)
            comparisonRow("HealthKit Sync", free: true, pro: true)
            comparisonRow("Custom Drinks", free: false, pro: true)
            comparisonRow("Smart Reminders", free: false, pro: true)
            comparisonRow("Themes & Colors", free: false, pro: true)
            comparisonRow("Detailed Stats", free: false, pro: true)
            comparisonRow("Data Export", free: false, pro: true)
            comparisonRow("Streak Recovery", free: false, pro: true)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private func comparisonRow(_ feature: String, free: Bool, pro: Bool) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(feature)
                    .font(.subheadline)
                Spacer()
                Image(systemName: free ? "checkmark" : "xmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(free ? .green : Color(.tertiaryLabel))
                    .frame(width: 50)
                Image(systemName: pro ? "checkmark" : "xmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(pro ? Color.aquaPrimary : Color(.tertiaryLabel))
                    .frame(width: 50)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider().padding(.leading, 16)
        }
    }

    // MARK: - Products

    private var productSection: some View {
        Group {
            if isLoading {
                ProgressView()
                    .padding()
            } else {
                VStack(spacing: 10) {
                    ForEach(products.sorted(by: { productSortOrder($0) < productSortOrder($1) })) { product in
                        ProductTile(
                            product: product,
                            isSelected: selectedProductID == product.id,
                            badge: productBadge(for: product)
                        ) {
                            selectedProductID = product.id
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        Group {
            if let product = products.first(where: { $0.id == selectedProductID }) {
                Button {
                    Task { await purchase(product) }
                } label: {
                    HStack {
                        Text("Continue")
                            .font(.headline)
                        if let intro = product.subscription?.introductoryOffer,
                           intro.paymentMode == .freeTrial {
                            Text("— 7 days free")
                                .font(.subheadline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.aquaGradient, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
                }
                .padding(.horizontal)
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Restore

    private var restoreButton: some View {
        Button("Restore Purchases") {
            Task {
                let success = await manager.restorePurchases()
                restoreSuccess = success
                showRestoreAlert = true
            }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    // MARK: - Terms Disclosure (Apple Requirement)

    private var termsDisclosure: some View {
        VStack(spacing: 6) {
            Text(subscriptionTermsText)
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
    }

    private var subscriptionTermsText: String {
        "Payment will be charged to your Apple ID account at confirmation of purchase. " +
        "Subscriptions automatically renew unless auto-renew is turned off at least 24 hours before the end of the current period. " +
        "Your account will be charged for renewal within 24 hours prior to the end of the current period. " +
        "You can manage and cancel your subscriptions by going to your account settings on the App Store after purchase. " +
        "Any unused portion of a free trial period will be forfeited when you purchase a subscription."
    }

    // MARK: - Helpers

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

    private func productBadge(for product: Product) -> String? {
        switch product.id {
        case SubscriptionManager.yearlyID: return "BEST VALUE"
        case SubscriptionManager.lifetimeID: return "FOREVER"
        default: return nil
        }
    }
}

// MARK: - Product Tile

struct ProductTile: View {
    let product: Product
    let isSelected: Bool
    let badge: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Radio indicator
                Circle()
                    .strokeBorder(isSelected ? Color.aquaPrimary : Color(.separator), lineWidth: 2)
                    .background(
                        Circle().fill(isSelected ? Color.aquaPrimary : .clear).padding(3)
                    )
                    .frame(width: 22, height: 22)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(product.displayName)
                            .font(.subheadline.weight(.semibold))

                        if let badge {
                            Text(badge)
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange, in: Capsule())
                                .foregroundStyle(.white)
                        }
                    }

                    if let intro = product.subscription?.introductoryOffer,
                       intro.paymentMode == .freeTrial {
                        Text("Includes 7-day free trial")
                            .font(.caption)
                            .foregroundStyle(Color.aquaPrimary)
                    }

                    if product.id == SubscriptionManager.yearlyID {
                        Text("Save 58% vs monthly")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.subheadline.weight(.bold))

                    if product.type == .autoRenewable {
                        Text(product.id == SubscriptionManager.yearlyID ? "/year" : "/month")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("one-time")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.aquaPrimary.opacity(0.06) : Color.aquaCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.aquaPrimary : Color(.separator).opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
            .foregroundStyle(Color.aquaTextPrimary)
        }
    }
}

// MARK: - Soft Paywall View (non-blocking nudge)

struct SoftPaywallBanner: View {
    @State private var showPaywall = false
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
            }

            Image(systemName: "sparkles")
                .font(.title)
                .foregroundStyle(Color.aquaPrimary)

            Text("Enjoying AquaFaste?")
                .font(.headline)

            Text("Unlock custom drinks, smart reminders, detailed stats, and more with Premium.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showPaywall = true
            } label: {
                Text("See Premium Plans")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.aquaGradient, in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)
            }
        }
        .padding()
        .background(Color.aquaCardBackground, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

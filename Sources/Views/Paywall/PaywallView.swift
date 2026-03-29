import StoreKit
import SwiftUI
import TelemetryDeck

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var products: [Product] = []
    @State private var isLoading = true
    @State private var purchaseInProgress = false
    @State private var errorMessage: String?
    @State private var showPurchaseError = false
    @State private var lastFailedProduct: Product?
    @State private var selectedProductID: String = SubscriptionManager.yearlyID
    @State private var showRestoreAlert = false
    @State private var restoreSuccess = false
    @State private var restoreInProgress = false
    @State private var wantsTrial = true
    @State private var testimonialPage = 0

    private let manager = SubscriptionManager.shared
    private let haptics = HapticManager.shared
    private let sounds = SoundManager.shared
    private let theme = ThemeManager.shared.effectiveTheme

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Rich premium background
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.02, green: 0.12, blue: 0.28),
                        Color(red: 0.05, green: 0.18, blue: 0.42),
                        Color(red: 0.08, green: 0.25, blue: 0.50)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Ambient glow orbs
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.cyan.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 180
                        )
                    )
                    .frame(width: 360, height: 360)
                    .offset(x: -100, y: -200)
                    .blur(radius: 60)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.blue.opacity(0.25), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .offset(x: 120, y: 300)
                    .blur(radius: 70)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.teal.opacity(0.2), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .offset(x: 80, y: -50)
                    .blur(radius: 50)
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // Spacer for dismiss button clearance
                    Color.clear.frame(height: 20)

                    headerSection
                    socialProofBadge
                    featureComparisonTable
                    planSelector
                    trialToggle
                    ctaButton
                    trialEndDate
                    trustIndicators
                    testimonialCards
                    restoreButton
                    termsSection
                }
                .padding(.bottom, 40)
            }

            // Dismiss button — ALWAYS visible
            dismissButton
        }
        .task {
            TelemetryDeck.signal("paywall.viewed")
            await loadProducts()
        }
        .disabled(purchaseInProgress)
        .overlay {
            if purchaseInProgress {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                ProgressView("Processing...")
                    .padding(20)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
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
        .alert("Purchase Failed", isPresented: $showPurchaseError) {
            if lastFailedProduct != nil {
                Button("Try Again") {
                    if let product = lastFailedProduct {
                        Task { await purchase(product) }
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                lastFailedProduct = nil
            }
        } message: {
            Text(errorMessage ?? "Something went wrong with your purchase. Please check your internet connection and try again.")
        }
    }

    // MARK: - Dismiss Button

    private var dismissButton: some View {
        Button {
            haptics.light()
            dismiss()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.aquaTextSecondary)
        }
        .padding(.top, 16)
        .padding(.trailing, 20)
        .accessibilityLabel("Close")
        .accessibilityHint("Dismiss paywall")
        .accessibilityIdentifier("paywallDismissButton")
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 14) {
            // Premium glow icon
            ZStack {
                // Outer glow rings
                ForEach(0..<3, id: \.self) { ring in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.cyan.opacity(0.15 - Double(ring) * 0.04),
                                    Color.blue.opacity(0.1 - Double(ring) * 0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .frame(
                            width: CGFloat(80 + ring * 28),
                            height: CGFloat(80 + ring * 28)
                        )
                }

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.cyan.opacity(0.25), Color.blue.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)

                Image(systemName: "drop.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .cyan.opacity(0.5), radius: 12, y: 4)
            }

            Text("AquaFaste Pro")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Unlock the complete hydration experience")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
    }

    // MARK: - Social Proof

    private var socialProofBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.3.fill")
                .font(.caption)
                .foregroundStyle(theme.primary)
            Text("10,000+ hydrated users")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.aquaTextSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(theme.primary.opacity(0.08), in: Capsule())
    }

    // MARK: - Feature Comparison Table (12 rows)

    private var featureComparisonTable: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Features")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("Free")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.aquaTextSecondary)
                    .frame(width: 54)
                Text("Pro")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.primary)
                    .frame(width: 54)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.aquaCardBackground)

            Divider()

            // Rows
            FeatureRow(feature: "Water & drink tracking", freeValue: .check, proValue: .check)
            FeatureRow(feature: "12 drink types", freeValue: .check, proValue: .check)
            FeatureRow(feature: "Daily goal", freeValue: .check, proValue: .check)
            FeatureRow(feature: "HealthKit sync", freeValue: .check, proValue: .check)
            FeatureRow(feature: "Themes", freeValue: .text("4"), proValue: .text("6 ✦"))
            FeatureRow(feature: "History", freeValue: .text("7 days"), proValue: .text("Unlimited"))
            FeatureRow(feature: "Statistics", freeValue: .text("Basic"), proValue: .text("Advanced"))
            FeatureRow(feature: "Reminders", freeValue: .text("Basic"), proValue: .text("Smart"))
            FeatureRow(feature: "CSV Export", freeValue: .cross, proValue: .check)
            FeatureRow(feature: "Streak Freeze", freeValue: .cross, proValue: .text("1/day"))
            FeatureRow(feature: "Caffeine Insights", freeValue: .cross, proValue: .check)
            FeatureRow(feature: "Custom Drinks", freeValue: .cross, proValue: .check)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator).opacity(0.2), lineWidth: 0.5)
        )
        .padding(.horizontal)
        .accessibilityLabel("Feature comparison: Free plan vs Pro plan")
    }

    // MARK: - Plan Selector

    private var planSelector: some View {
        VStack(spacing: 10) {
            ForEach(sortedProducts) { product in
                PlanCard(
                    product: product,
                    isSelected: selectedProductID == product.id,
                    badge: planBadge(for: product),
                    savingsText: planSavings(for: product),
                    theme: theme
                ) {
                    haptics.selectionChanged()
                    selectedProductID = product.id
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Trial Toggle

    private var trialToggle: some View {
        Group {
            if selectedProduct?.subscription?.introductoryOffer != nil {
                Button {
                    haptics.selectionChanged()
                    wantsTrial.toggle()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: wantsTrial ? "checkmark.square.fill" : "square")
                            .font(.title3)
                            .foregroundStyle(wantsTrial ? theme.primary : Color(.tertiaryLabel))

                        Text("Start with 7-day free trial")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.aquaTextPrimary)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(wantsTrial ? theme.primary.opacity(0.06) : Color.aquaCardBackground)
                    )
                }
                .padding(.horizontal)
                .accessibilityLabel("Start with 7-day free trial, \(wantsTrial ? "enabled" : "disabled")")
                .accessibilityHint("Double tap to toggle")
                .accessibilityIdentifier("trialToggle")
            }
        }
    }

    // MARK: - CTA Button

    private var ctaButton: some View {
        Group {
            if let product = selectedProduct {
                Button {
                    haptics.buttonPress()
                    Task { await purchase(product) }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: wantsTrial && product.subscription?.introductoryOffer != nil
                            ? "gift.fill" : "crown.fill")
                            .font(.subheadline)

                        Text(ctaText(for: product))
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [theme.gradientStart, theme.primary, theme.gradientEnd],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: Capsule()
                    )
                    .shadow(color: theme.primary.opacity(0.4), radius: 14, x: 0, y: 6)
                    .shadow(color: theme.gradientEnd.opacity(0.2), radius: 4, x: 0, y: 2)
                    .foregroundStyle(.white)
                }
                .padding(.horizontal)
                .accessibilityLabel(ctaText(for: product))
                .accessibilityHint("Double tap to proceed with purchase")
                .accessibilityIdentifier("subscribeCTA")
            }
        }
    }

    // MARK: - Trial End Date

    private var trialEndDate: some View {
        Group {
            if wantsTrial, let product = selectedProduct,
               product.subscription?.introductoryOffer != nil
            {
                let endDate = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
                VStack(spacing: 4) {
                    Text("Trial ends \(endDate, format: .dateTime.month().day().year())")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.aquaTextSecondary)
                    Text("We'll send you a reminder before it ends.")
                        .font(.caption2)
                        .foregroundStyle(Color.aquaTextTertiary)
                }
                .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Trust Indicators

    private var trustIndicators: some View {
        HStack(spacing: 20) {
            TrustBadge(icon: "xmark.circle", text: "Cancel\nanytime", theme: theme)
            TrustBadge(icon: "hand.raised.slash", text: "No ads\never", theme: theme)
            TrustBadge(icon: "lock.shield", text: "Secure\npayment", theme: theme)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Cancel anytime. No ads ever. Secure payment via Apple.")
    }

    // MARK: - Testimonial Cards

    private var testimonialCards: some View {
        VStack(spacing: 12) {
            TabView(selection: $testimonialPage) {
                TestimonialCard(
                    text: "AquaFaste Pro made it so easy to build a daily hydration habit. The smart reminders are a game changer!",
                    author: "Sarah M.",
                    rating: 5
                )
                .tag(0)

                TestimonialCard(
                    text: "I love the detailed stats and caffeine tracking. Finally an app that takes hydration seriously.",
                    author: "James R.",
                    rating: 5
                )
                .tag(1)

                TestimonialCard(
                    text: "The streak system keeps me motivated every day. 60 days and counting!",
                    author: "Emily K.",
                    rating: 5
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 150)
        }
        .padding(.horizontal)
    }

    // MARK: - Restore Button

    private var restoreButton: some View {
        Button {
            haptics.buttonPress()
            Task {
                restoreInProgress = true
                let success = await manager.restorePurchases()
                restoreInProgress = false
                restoreSuccess = success
                showRestoreAlert = true
            }
        } label: {
            if restoreInProgress {
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Restoring...")
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
            } else {
                Text("Restore Purchases")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .disabled(restoreInProgress)
        .accessibilityLabel("Restore previous purchases")
        .accessibilityHint("Restores premium access if you purchased before")
        .accessibilityIdentifier("restorePurchasesButton")
    }

    // MARK: - Terms Section

    private var termsSection: some View {
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

    private var selectedProduct: Product? {
        products.first { $0.id == selectedProductID }
    }

    private var sortedProducts: [Product] {
        products.sorted { productSortOrder($0) < productSortOrder($1) }
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
        lastFailedProduct = nil
        do {
            let success = try await manager.purchase(product)
            if success {
                haptics.goalComplete()
                sounds.playCelebration()
                dismiss()
            }
        } catch {
            lastFailedProduct = product
            if let storeError = error as? StoreKitError {
                switch storeError {
                case .networkError:
                    errorMessage = "Network error. Please check your internet connection and try again."
                case .userCancelled:
                    purchaseInProgress = false
                    return
                default:
                    errorMessage = "Purchase could not be completed. Please try again later."
                }
            } else {
                errorMessage = "Something went wrong. Please try again."
            }
            showPurchaseError = true
        }
        purchaseInProgress = false
    }

    private func productSortOrder(_ product: Product) -> Int {
        switch product.id {
        case SubscriptionManager.monthlyID: 0
        case SubscriptionManager.yearlyID: 1
        case SubscriptionManager.lifetimeID: 2
        default: 3
        }
    }

    private func planBadge(for product: Product) -> String? {
        switch product.id {
        case SubscriptionManager.yearlyID: "Most Popular"
        case SubscriptionManager.lifetimeID: "Best Value"
        default: nil
        }
    }

    private func planSavings(for product: Product) -> String? {
        switch product.id {
        case SubscriptionManager.yearlyID: "Save 58%"
        default: nil
        }
    }

    private func ctaText(for product: Product) -> String {
        if wantsTrial, product.subscription?.introductoryOffer != nil {
            return "Start Free Trial"
        }
        return "Subscribe Now"
    }
}

// MARK: - Feature Row

private enum FeatureCellValue {
    case check
    case cross
    case text(String)
}

private struct FeatureRow: View {
    let feature: String
    let freeValue: FeatureCellValue
    let proValue: FeatureCellValue

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(feature)
                    .font(.subheadline)
                    .foregroundStyle(Color.aquaTextPrimary)
                Spacer()
                featureCell(freeValue, isPro: false)
                    .frame(width: 54)
                featureCell(proValue, isPro: true)
                    .frame(width: 54)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider().padding(.leading, 16)
        }
    }

    @ViewBuilder
    private func featureCell(_ value: FeatureCellValue, isPro: Bool) -> some View {
        switch value {
        case .check:
            Image(systemName: "checkmark")
                .font(.caption.weight(.semibold))
                .foregroundStyle(isPro ? Color.aquaPrimary : .green)
        case .cross:
            Image(systemName: "xmark")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(.tertiaryLabel))
        case let .text(label):
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(isPro ? Color.aquaPrimary : Color.aquaTextSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Plan Card

private struct PlanCard: View {
    let product: Product
    let isSelected: Bool
    let badge: String?
    let savingsText: String?
    let theme: AppTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Radio indicator
                Circle()
                    .strokeBorder(isSelected ? theme.primary : Color(.separator), lineWidth: 2)
                    .background(
                        Circle().fill(isSelected ? theme.primary : .clear).padding(3)
                    )
                    .frame(width: 22, height: 22)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(product.displayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.aquaTextPrimary)

                        if let badge {
                            Text(badge)
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule().fill(
                                        product.id == SubscriptionManager.yearlyID
                                            ? Color.orange
                                            : theme.primary
                                    )
                                )
                                .foregroundStyle(.white)
                        }
                    }

                    HStack(spacing: 6) {
                        if let intro = product.subscription?.introductoryOffer,
                           intro.paymentMode == .freeTrial
                        {
                            Text("7-day free trial")
                                .font(.caption)
                                .foregroundStyle(theme.primary)
                        }

                        if let savingsText {
                            Text(savingsText)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.green)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.aquaTextPrimary)

                    if product.type == .autoRenewable {
                        Text(product.id == SubscriptionManager.yearlyID ? "/year" : "/month")
                            .font(.caption2)
                            .foregroundStyle(Color.aquaTextSecondary)
                    } else {
                        Text("one-time")
                            .font(.caption2)
                            .foregroundStyle(Color.aquaTextSecondary)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? theme.primary.opacity(0.06) : Color.aquaCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? theme.primary : Color(.separator).opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: isSelected ? theme.primary.opacity(0.15) : Color.black.opacity(0.04),
                radius: isSelected ? 10 : 4, x: 0, y: 3
            )
        }
        .accessibilityLabel("\(product.displayName), \(product.displayPrice)\(isSelected ? ", selected" : "")\(badge != nil ? ", \(badge!)" : "")")
        .accessibilityHint(isSelected ? "Currently selected plan" : "Double tap to select this plan")
    }
}

// MARK: - Trust Badge

private struct TrustBadge: View {
    let icon: String
    let text: String
    let theme: AppTheme

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(theme.primary)
            Text(text)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.aquaTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Testimonial Card

private struct TestimonialCard: View {
    let text: String
    let author: String
    let rating: Int

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 2) {
                ForEach(0 ..< rating, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }

            Text("\u{201C}\(text)\u{201D}")
                .font(.subheadline)
                .foregroundStyle(Color.aquaTextPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(3)

            Text("— \(author)")
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.aquaTextSecondary)
        }
        .padding(16)
        .background(Color.aquaCardBackground, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
        .padding(.horizontal, 4)
    }
}

// MARK: - Soft Paywall Banner (non-blocking nudge)

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
                .accessibilityLabel("Dismiss promotion")
                .accessibilityIdentifier("softPaywallDismiss")
            }

            Image(systemName: "sparkles")
                .font(.title)
                .foregroundStyle(Color.aquaPrimary)

            Text("Enjoying AquaFaste?")
                .font(.headline)

            Text("Unlock custom drinks, smart reminders, detailed stats, and more with Pro.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                HapticManager.shared.buttonPress()
                showPaywall = true
            } label: {
                Text("See Pro Plans")
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

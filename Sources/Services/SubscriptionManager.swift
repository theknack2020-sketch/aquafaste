import Foundation
import StoreKit

@Observable @MainActor
final class SubscriptionManager {
    static let shared = SubscriptionManager()

    private(set) var isSubscribed = false
    private(set) var isLifetime = false

    static let monthlyID = "com.theknack.aquafaste.premium.monthly"
    static let yearlyID = "com.theknack.aquafaste.premium.yearly"
    static let lifetimeID = "com.theknack.aquafaste.premium.lifetime"

    var isPremium: Bool { isSubscribed || isLifetime }

    private init() {
        Task { await checkSubscriptionStatus() }
        Task { await listenForTransactions() }
    }

    func checkSubscriptionStatus() async {
        var hasSubscription = false
        var hasLifetime = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            if transaction.productID == Self.lifetimeID {
                hasLifetime = true
            } else if transaction.productID == Self.monthlyID ||
                      transaction.productID == Self.yearlyID {
                hasSubscription = true
            }
        }

        self.isSubscribed = hasSubscription
        self.isLifetime = hasLifetime
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            guard case .verified(_) = result else { continue }
            await checkSubscriptionStatus()
        }
    }

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else { return false }
            await transaction.finish()
            await checkSubscriptionStatus()
            return true
        case .pending:
            return false
        case .userCancelled:
            return false
        @unknown default:
            return false
        }
    }

    /// Restore purchases and return whether any premium entitlement was found
    func restorePurchases() async -> Bool {
        try? await AppStore.sync()
        await checkSubscriptionStatus()
        return isPremium
    }

    // MARK: - Soft Paywall Logic

    /// Date when the user first launched the app (set once)
    var firstLaunchDate: Date {
        get {
            let defaults = UserDefaults.standard
            if let date = defaults.object(forKey: "af_first_launch") as? Date {
                return date
            }
            let now = Date()
            defaults.set(now, forKey: "af_first_launch")
            return now
        }
    }

    /// Whether 7+ days have passed since first launch
    var shouldShowSoftPaywall: Bool {
        guard !isPremium else { return false }
        let daysSinceInstall = Calendar.current.dateComponents(
            [.day], from: firstLaunchDate, to: .now
        ).day ?? 0
        return daysSinceInstall >= 7
    }

    /// Whether the user dismissed the soft paywall this session
    var softPaywallDismissedThisSession = false
}

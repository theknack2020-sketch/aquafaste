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

        await MainActor.run {
            self.isSubscribed = hasSubscription
            self.isLifetime = hasLifetime
        }
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

    func restorePurchases() async {
        try? await AppStore.sync()
        await checkSubscriptionStatus()
    }
}

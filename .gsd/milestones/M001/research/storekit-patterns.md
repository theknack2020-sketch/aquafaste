# StoreKit 2 Implementation Patterns for Subscription Apps (iOS 17+)

**Date:** 2026-03-22
**Purpose:** Define StoreKit 2 architecture for AquaFaste premium subscription
**Scope:** Product config, paywall UI, verification, status monitoring, billing resilience, family sharing, offers
**Baseline:** Lumifaste SubscriptionManager.swift + PaywallView.swift (custom paywall)

---

## 1. Product Configuration

### App Store Connect Setup

AquaFaste needs one subscription group containing all auto-renewable plans. Per the monetization research, the planned products are:

| Product ID | Type | Price |
|---|---|---|
| `com.theknack.aquafaste.pro.weekly` | Auto-renewable | $1.99/wk |
| `com.theknack.aquafaste.pro.monthly` | Auto-renewable | $3.99/mo |
| `com.theknack.aquafaste.pro.yearly` | Auto-renewable | $19.99/yr |
| `com.theknack.aquafaste.pro.lifetime` | Non-consumable | $39.99 |

**Subscription group:** "AquaFaste Pro" — all auto-renewable plans must be in the same group. The lifetime purchase is a separate non-consumable IAP (not part of the subscription group).

**Service level ordering** within the group (highest → lowest): Yearly → Monthly → Weekly. This controls upgrade/downgrade behavior — moving from Weekly to Yearly is an upgrade (immediate), Yearly to Monthly is a downgrade (end of period).

### StoreKit Configuration File (Local Testing)

For development, create a `.storekit` configuration file in Xcode. This allows full purchase flow testing without App Store Connect:

- File → New → File → StoreKit Configuration File
- Add all products with matching identifiers
- Set scheme → Run → Options → StoreKit Configuration to the file
- Transaction Manager (Debug → StoreKit → Manage Transactions) for state manipulation

**Key testing capability:** Xcode's config file supports simulating billing retry, grace period, offer redemption, and renewal acceleration — all without sandbox or production.

### What Lumifaste Does

Lumifaste hardcodes two product IDs (`premium.monthly`, `premium.yearly`) as a `Set<String>` in `SubscriptionManager`. Products are fetched via `Product.products(for:)` with a 3-attempt retry loop (2s, 4s delays).

### Gaps for AquaFaste

1. **4 products** (3 subscriptions + 1 lifetime) vs Lumifaste's 2 — need to handle mixed product types (auto-renewable + non-consumable) in a single paywall.
2. **Lifetime purchase** requires different entitlement logic — it's not in `Transaction.currentEntitlements` for auto-renewables, it's a non-consumable entitlement.
3. **Product ID management** — consider an enum like Rolldark's `RolldarkProduct` pattern for type-safe product handling instead of raw strings.

---

## 2. SubscriptionStoreView vs Custom Paywall

### Option A: SubscriptionStoreView (Apple's Built-in)

Introduced in iOS 17. A single SwiftUI view that handles the entire subscription merchandising experience for one subscription group.

```swift
SubscriptionStoreView(groupID: "YOUR_GROUP_ID") {
    // Custom marketing content above the plan picker
    MyMarketingView()
}
.subscriptionStoreControlStyle(.buttons)     // or .compactPicker, .pagedPicker (iOS 18)
.subscriptionStoreButtonLabel(.multiline)
.subscriptionStorePickerItemBackground(.thinMaterial)
.storeButton(.visible, for: .restorePurchases)
.subscriptionStorePolicyDestination(url: termsURL, for: .termsOfService)
.subscriptionStorePolicyDestination(url: privacyURL, for: .privacyPolicy)
```

**Pros:**
- Handles purchase flow, verification, restore, and legal links automatically
- Localization built-in (price, duration, currency)
- Automatically shows introductory offers when eligible
- `.preferredSubscriptionOffer` modifier (iOS 18) for custom offer selection logic
- Apple Review-friendly — follows App Store design guidelines by default
- Automatically handles subscription upgrades/downgrades within the group

**Cons:**
- Only works for a single subscription group — cannot show the lifetime non-consumable
- Limited layout customization (marketing area above + plan picker below)
- Cannot build multi-page paywalls or highlight one plan on a main page
- No control over the purchase button text (e.g., "Start 7-Day Free Trial")
- Cannot mix auto-renewable + non-consumable products in one view

### Option B: Custom Paywall (Lumifaste Pattern)

Full SwiftUI paywall with manual `Product.products(for:)` loading, custom UI, and `product.purchase()` calls.

**Pros:**
- Complete design freedom (3-plan layout, highlighted yearly, lifetime card)
- Can mix product types (subscriptions + lifetime) in one view
- Custom CTA text based on trial eligibility
- Timed offers, countdowns, A/B testing capability
- Contextual paywalls (different layouts for different trigger points)

**Cons:**
- Must handle purchase flow, verification, restore manually
- Must check and display introductory offer eligibility manually
- Must build localized price display
- Must handle all edge cases (pending, cancelled, network errors)
- More code to maintain and more surface area for bugs

### Recommendation for AquaFaste: **Hybrid Approach**

Use a **custom paywall** as the primary experience (like Lumifaste) because:
1. AquaFaste needs to show 3 subscriptions + 1 lifetime in one view
2. The monetization strategy calls for specific paywall tactics (highlighted yearly, limited-time lifetime deal)
3. We need full control over CTA text ("Start 7-Day Free Trial" vs "Subscribe")

Use **SubscriptionStoreView** as a secondary surface:
- Subscription management view (for existing subscribers to upgrade/downgrade)
- Settings → "Manage Subscription" link
- Simpler paywall for contextual upsells (e.g., tapping a locked feature)

### What Lumifaste Does

Custom paywall with `ProductCard` components, manual product selection, and `subscriptionManager.purchase(product)`. The CTA says "Start 7-Day Free Trial" — hardcoded, doesn't dynamically check trial eligibility. This is a problem if the user has already used a trial.

---

## 3. Transaction Verification

### How StoreKit 2 Verification Works

StoreKit 2 replaced manual receipt validation with automatic JWS (JSON Web Signature) verification. Every transaction comes wrapped in a `VerificationResult<Transaction>`:

```swift
case .verified(let transaction)    // JWS signature valid, safe to use
case .unverified(let transaction, let error)  // Signature invalid or tampered
```

The device verifies the JWS signature locally against Apple's root certificate. No server round-trip needed for basic verification.

### What Lumifaste Does

```swift
private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
    switch result {
    case .unverified:
        throw SubscriptionError.verificationFailed
    case .verified(let safe):
        return safe
    }
}
```

This is the standard pattern — used identically across Lumifaste, Tendril, EmojiDecode, and Rolldark. It's correct and sufficient for client-side verification.

### Server-Side Verification (Optional Enhancement)

For apps without a backend (like all current Faste apps), client-side JWS verification is adequate. Server-side verification becomes valuable when:
- You need a server-authoritative subscription state (multi-platform access)
- You want to detect jailbreak/tampered transactions
- You need to process refunds server-side
- You want to use App Store Server Notifications V2

**AquaFaste recommendation:** Client-side only for v1. No backend needed. The `checkVerified` pattern from Lumifaste is correct and reusable.

### New in iOS 18.4+ (WWDC 2025)

- `AppTransaction.appTransactionID` — globally unique identifier per Apple Account per app, back-deployed to iOS 15. Useful for tracking unique users without a server.
- JWS-based `introductoryOfferEligibility` and `promotionalOffer` purchase options — new signed verification for offers.

---

## 4. Subscription Status Monitoring

### The Correct Pattern

Lumifaste uses `Transaction.currentEntitlements` to check status — this works but is a **pull-based** approach. The recommended iOS 17+ pattern adds **push-based** monitoring via `subscriptionStatusTask`:

```swift
// In your root view or app scene
ContentView()
    .subscriptionStatusTask(for: "YOUR_GROUP_ID") { taskState in
        // Called whenever subscription status changes
        // taskState.value is [Product.SubscriptionInfo.Status]
    }
```

This modifier automatically monitors the subscription group and calls back when status changes — no polling needed.

### Full Status State Machine

StoreKit 2 exposes `Product.SubscriptionInfo.RenewalState` with these states:

| State | User Should Have Access | Action |
|---|---|---|
| `.subscribed` | ✅ Yes | Full access |
| `.inGracePeriod` | ✅ Yes | Full access + prompt to update payment |
| `.inBillingRetryPeriod` | ❌ No (configurable) | Revoke access, show payment failed UI |
| `.expired` | ❌ No | Show re-subscribe offer |
| `.revoked` | ❌ No | Refunded — revoke access |

### What Lumifaste Does

```swift
func checkSubscriptionStatus() async {
    var foundActive = false
    for await result in Transaction.currentEntitlements {
        if let transaction = try? checkVerified(result) {
            if transaction.productType == .autoRenewable {
                foundActive = true
                break
            }
        }
    }
    isSubscribed = foundActive
}
```

**Problems:**
1. Only checks for `.autoRenewable` — would miss a lifetime non-consumable purchase
2. No granular state handling — treats everything as binary active/inactive
3. Doesn't distinguish grace period from billing retry from expired
4. No `subscriptionStatusTask` — relies on manual calls to `checkSubscriptionStatus()`

### Recommended Pattern for AquaFaste

```swift
enum SubscriptionState {
    case notSubscribed
    case subscribed
    case inGracePeriod(expirationDate: Date)
    case inBillingRetry
    case expired
    case revoked
    case lifetime  // non-consumable purchase
}
```

Check entitlements for both auto-renewable AND non-consumable (lifetime). Use `subscriptionStatusTask` for real-time subscription monitoring. Fall back to `Transaction.currentEntitlements` for lifetime check.

---

## 5. Grace Periods

### What They Are

When a subscription renewal fails (expired card, insufficient funds), the subscriber normally loses access immediately. **Billing Grace Period** keeps them subscribed while Apple retries the charge.

### Configuration

Enabled per-app in App Store Connect → Features → In-App Purchases → Billing Grace Period:
- **Duration options:** 3, 16, or 28 days
- **Scope:** All renewals (including free→paid transitions) or existing paid renewals only
- **Recommendation for AquaFaste:** 16 days, all renewals — matches most subscription apps

### Implementation

StoreKit 2 surfaces grace period as `.inGracePeriod` in the `RenewalState`. The app should:

1. **Grant full access** during grace period (this is the whole point)
2. **Show a non-intrusive banner** prompting the user to update payment info
3. Use `RenewalInfo.gracePeriodExpirationDate` (iOS 17+) to show remaining time
4. Deep-link to payment settings: `showManageSubscriptions(in:)` or the Settings URL

### What Lumifaste Does

**Nothing.** Lumifaste has no grace period handling. The binary `isSubscribed` check via `currentEntitlements` happens to grant access during grace period (because the entitlement is still present), but there's no user-facing prompt to fix the payment issue. If the grace period expires, the user loses access silently.

### Gap for AquaFaste

Must explicitly handle `.inGracePeriod` state with a soft UI prompt ("Your subscription has a billing issue — tap to update payment method"). This significantly reduces involuntary churn.

---

## 6. Billing Retry

### What It Is

After a subscription renewal fails, Apple automatically retries the charge for up to **60 days**. This happens regardless of whether grace period is enabled.

- **With grace period:** User keeps access during grace period window (3/16/28 days), then loses access during remaining retry period
- **Without grace period:** User loses access immediately when renewal fails, Apple retries in background

### Implementation

The `.inBillingRetryPeriod` renewal state indicates the user's subscription failed to renew and Apple is retrying. Standard practice:

1. **Revoke premium access** (unlike grace period)
2. **Show a recovery screen** — "Your subscription is paused due to a billing issue"
3. Offer a direct link to update payment: `showManageSubscriptions(in:)`
4. If billing recovers, the `Transaction.updates` listener fires and access is restored

### What Lumifaste Does

No specific billing retry handling. The `currentEntitlements` loop would simply not find an active entitlement, so `isSubscribed` becomes `false`. No user communication about what happened.

### What Lumifaste Should Do (and AquaFaste Must Do)

Distinguish "expired because user cancelled" from "expired because payment failed" — different UX responses. Payment failure → recovery prompt. Cancellation → win-back offer.

---

## 7. Family Sharing

### How It Works

When Family Sharing is enabled for a subscription in App Store Connect:
- The family organizer purchases/subscribes
- Up to 5 other family members get access automatically
- Family members appear in `Transaction.currentEntitlements` with the same product
- The `Transaction` object includes `ownershipType: .familyShared` vs `.purchased`

### Eligibility Rules for Offers

- **Only the family organizer** can redeem introductory offers and promotional offers
- Family members get access through the shared subscription but cannot independently redeem offers
- `Transaction.currentEntitlements(for:)` (new API, WWDC 2025) properly handles multiple entitlement scenarios including Family Sharing

### Implementation

```swift
for await result in Transaction.currentEntitlements {
    if let transaction = try? checkVerified(result) {
        // transaction.ownershipType tells you if this user bought it
        // or if they're a family member
        if transaction.ownershipType == .familyShared {
            // Still grant access, but don't show "Manage Subscription"
            // (they can't manage it — the organizer can)
        }
    }
}
```

### What Lumifaste Does

No Family Sharing awareness. The `checkSubscriptionStatus` method would grant access to family members (correct) but wouldn't know they're family members (could show incorrect "Manage Subscription" UI).

### Recommendation for AquaFaste

1. Enable Family Sharing for the subscription group in App Store Connect
2. Check `ownershipType` to customize the subscription management UI
3. For family-shared users: show "Shared via Family" badge, hide "Manage Subscription" button (they can't manage it)
4. A hydration tracker is a good candidate for family sharing — families tracking together

---

## 8. Offer Codes

### Types

1. **One-time-use codes** — 18-digit unique codes generated in App Store Connect (up to 500,000 per campaign). Each code can only be redeemed once.
2. **Custom codes** — Developer-defined alphanumeric strings (e.g., "SPRINGWATER"). Reusable up to a set redemption limit.

### Use Cases for AquaFaste

- **Launch promotion:** "AQUALAUNCH" custom code for 1 month free
- **Influencer partnerships:** One-time codes for YouTube/Instagram promoters
- **Cross-promotion from Lumifaste:** "FASTEWATER" code for Lumifaste users
- **Re-engagement emails:** Offer codes sent to churned users

### Implementation

Users redeem offer codes through:
1. **App Store → Account → Redeem Gift Card or Code**
2. **In-app redemption sheet:**
   ```swift
   // Present the offer code redemption sheet
   try await AppStore.presentOfferCodeRedeemSheet(in: windowScene)
   ```
3. **Direct URL:** `https://apps.apple.com/redeem?ctx=offercodes&id=APP_ID&code=CODE`

The redemption triggers a transaction through `Transaction.updates` — handled like any other purchase. No special code needed beyond showing the redemption UI.

### What Lumifaste Does

No offer code support.

---

## 9. Introductory Offers (Free Trial)

### Types of Introductory Offers

1. **Free trial** — Full access for free for a duration (e.g., 7 days). Auto-converts to paid at end.
2. **Pay as you go** — Discounted price per period for N periods (e.g., $0.99/mo for 3 months, then $3.99/mo).
3. **Pay up front** — One-time discounted price for a duration (e.g., $1.99 for 2 months).

### Eligibility

- One introductory offer per subscription group, per Apple Account, ever
- If a user redeemed a free trial for the monthly plan, they can't get another intro offer on the yearly plan (same group)
- Family sharing: only the organizer is eligible
- **Must check eligibility before displaying the offer** — showing "Start Free Trial" to an ineligible user is misleading and an App Review risk

### Checking Eligibility (StoreKit 2)

```swift
// On the Product's subscription info
let isEligible = await product.subscription?.isEligibleForIntroOffer ?? false
```

This is the StoreKit 2 method — significantly simpler than StoreKit 1's receipt-based approach. Returns `true` only if the user has never used an intro offer in this group.

### Displaying the Offer

```swift
if let introOffer = product.subscription?.introductoryOffer {
    switch introOffer.paymentMode {
    case .freeTrial:
        // "7-day free trial, then $19.99/year"
        let trialDuration = introOffer.period  // e.g., 7 days
    case .payAsYouGo:
        // "$0.99/mo for 3 months, then $3.99/mo"
        let discountPrice = introOffer.displayPrice
        let periods = introOffer.periodCount
    case .payUpFront:
        // "$1.99 for 2 months, then $3.99/mo"
        let upfrontPrice = introOffer.displayPrice
    }
}
```

### SubscriptionStoreView Automatic Handling

If using `SubscriptionStoreView`, introductory offers are displayed automatically when the user is eligible. The `.preferredSubscriptionOffer` modifier (iOS 18+) allows custom offer selection:

```swift
SubscriptionStoreView(groupID: groupID)
    .preferredSubscriptionOffer { product, subscription, eligibleOffers in
        // Return the offer you want to display, or nil for default
        eligibleOffers
            .filter { $0.paymentMode == .freeTrial }
            .max { $0.period.value < $1.period.value }
    }
```

### What Lumifaste Does

The PaywallView **hardcodes** "Start 7-Day Free Trial" as the CTA button text and "Try all Premium features free for 7 days" in the legal text. It does **not** check `isEligibleForIntroOffer`. A returning user who already used their trial would see "Start 7-Day Free Trial" but would be charged immediately — misleading UX.

### Critical Fix for AquaFaste

1. Check `product.subscription?.isEligibleForIntroOffer` before displaying trial language
2. Show "Start Free Trial" only when eligible
3. Show "Subscribe" or "Continue" when not eligible
4. Display the actual offer terms from the `introductoryOffer` property (don't hardcode "7 days")

---

## 10. Win-Back Offers (iOS 18+)

### What They Are

New in iOS 18. Targeted offers for lapsed subscribers (users who previously subscribed but let it expire or cancelled). Configure in App Store Connect with eligibility criteria.

### How They Surface

1. **Automatic StoreKit Message** — the system shows a win-back sheet when the user opens the app (no code needed beyond having a `Transaction.updates` listener)
2. **SubscriptionStoreView** — automatically shows win-back offers to eligible users
3. **Custom implementation** — use `Product.SubscriptionInfo.winBackOffers` (iOS 18+) to build custom UI

### Recommendation for AquaFaste

Since iOS 17 is the minimum target, win-back offers are available on iOS 18+ devices only. Implement the Message API handler (zero effort) and consider custom win-back UI if analytics show significant churn-and-return patterns post-launch.

---

## 11. Transaction Listener Pattern

### The Correct Pattern

Every app using StoreKit 2 must have a transaction listener running at app launch to handle:
- Transactions that complete outside the app (Ask to Buy approval, offer code redemption)
- Subscription renewals
- Refunds and revocations
- Billing retry resolutions

### What Lumifaste Does

```swift
private func listenForTransactions() -> Task<Void, Never> {
    Task { [weak self] in
        for await result in Transaction.updates {
            if let self, let transaction = try? self.checkVerified(result) {
                await transaction.finish()
                self.checkSubscriptionStatusSync()
            }
        }
    }
}
```

**Issues:**
1. `[weak self]` + `if let self` — correct memory pattern but `self` is captured strongly after the check. In practice fine since the manager lives for the app lifetime.
2. Silently ignores `.unverified` transactions — should log them for diagnostics.
3. Uses a nested `Task` in `checkSubscriptionStatusSync` — adds unnecessary indirection.

### Recommended Pattern for AquaFaste

```swift
private func listenForTransactions() -> Task<Void, Never> {
    Task.detached { [weak self] in
        for await result in Transaction.updates {
            switch result {
            case .verified(let transaction):
                await transaction.finish()
                await self?.refreshEntitlementState()
            case .unverified(let transaction, let error):
                // Log but don't finish — might be tampered
                Logger.store.error("Unverified transaction \(transaction.id): \(error)")
            }
        }
    }
}
```

---

## 12. Comparison: Lumifaste vs AquaFaste Requirements

| Capability | Lumifaste (Current) | AquaFaste (Needed) | Gap |
|---|---|---|---|
| Product types | 2 subscriptions | 3 subscriptions + 1 lifetime | Mixed product type handling |
| Paywall UI | Custom (hardcoded trial text) | Custom + SubscriptionStoreView | Dynamic trial eligibility check |
| Transaction verification | Client-side JWS ✅ | Client-side JWS ✅ | None |
| Status monitoring | Pull-based (currentEntitlements) | Push-based (subscriptionStatusTask) | Add subscriptionStatusTask |
| Grace period | Implicit (no UI) | Explicit UI prompt | Add grace period banner |
| Billing retry | No handling | Recovery prompt UI | Add billing retry screen |
| Family sharing | Not aware | ownershipType check | Add family sharing UI |
| Offer codes | Not supported | Redemption sheet + cross-promo | Add offer code flow |
| Introductory offers | Hardcoded trial text | Dynamic eligibility check | Critical: fix trial display |
| Win-back offers | N/A (pre-iOS 18) | Message API + optional custom UI | iOS 18+ feature |
| Restore purchases | AppStore.sync() ✅ | AppStore.sync() ✅ | None |
| Product loading retry | 3 attempts, 2s/4s delay | Same pattern + timeout | Add timeout (EmojiDecode pattern) |
| Error logging | os.Logger ✅ | os.Logger ✅ | None |
| Lifetime purchase | N/A | Non-consumable entitlement check | New logic needed |

---

## 13. Recommended Architecture for AquaFaste

### File Structure

```
Sources/
  Services/
    StoreManager.swift          // Product loading, purchase, verification
    EntitlementManager.swift     // Subscription state, grace period, family sharing
  Views/
    Paywall/
      PaywallView.swift         // Primary custom paywall (3 subs + lifetime)
      PaywallProductCard.swift  // Individual product card component
      SubscriptionManageView.swift  // SubscriptionStoreView wrapper for existing subs
    Components/
      GracePeriodBanner.swift   // Non-intrusive billing issue prompt
      PremiumBadge.swift        // "Pro" badge for locked features
```

### Key Design Decisions

1. **Separate StoreManager from EntitlementManager** — StoreManager handles App Store interaction (products, purchases). EntitlementManager owns the subscription state machine (subscribed, grace, retry, expired, lifetime). This is cleaner than Lumifaste's single-class approach.

2. **Type-safe product IDs** — Use an enum (like Rolldark) instead of raw strings:
   ```swift
   enum AquaFasteProduct: String, CaseIterable {
       case weekly = "com.theknack.aquafaste.pro.weekly"
       case monthly = "com.theknack.aquafaste.pro.monthly"
       case yearly = "com.theknack.aquafaste.pro.yearly"
       case lifetime = "com.theknack.aquafaste.pro.lifetime"
       
       var isSubscription: Bool { self != .lifetime }
   }
   ```

3. **Dynamic trial text** — Always check `isEligibleForIntroOffer` before showing "Free Trial" language. Never hardcode.

4. **Timeout on product loading** — Use EmojiDecode's `withTimeout` pattern (15s per attempt) with Lumifaste's retry logic (3 attempts, exponential backoff).

5. **Cached entitlement state** — Use Rolldark's UserDefaults caching pattern for instant UI state on cold launch, then verify against StoreKit in background.

---

## Sources

1. Apple Developer — [StoreKit 2](https://developer.apple.com/storekit/) (official)
2. Apple Developer — [SubscriptionStoreView](https://developer.apple.com/documentation/storekit/subscriptionstoreview) (official)
3. Apple Developer — [Auto-renewable Subscriptions](https://developer.apple.com/app-store/subscriptions/) (official)
4. Apple Developer — [Billing Grace Period](https://developer.apple.com/help/app-store-connect/manage-subscriptions/enable-billing-grace-period-for-auto-renewable-subscriptions/) (official)
5. Apple Developer — [Implementing Introductory Offers](https://developer.apple.com/documentation/storekit/implementing-introductory-offers-in-your-app) (official)
6. Apple Developer — [WWDC25: What's New in StoreKit](https://developer.apple.com/videos/play/wwdc2025/241/) (official)
7. Apple Developer — [WWDC24: Implement App Store Offers](https://developer.apple.com/videos/play/wwdc2024/10110/) (official)
8. BleepingSwift — [StoreKit 2 for IAP and Subscriptions](https://bleepingswift.com/blog/storekit-2-in-app-purchases-subscriptions) (Feb 2026)
9. Adapty — [Grace Period Handling](https://adapty.io/blog/how-to-handle-apple-billing-grace-period/) (2023)
10. Adapty — [Apple Subscription Offers Guide 2026](https://adapty.io/blog/apple-subscription-offers-guide/) (Dec 2025)
11. RevenueCat — [StoreKit Views Guide](https://www.revenuecat.com/blog/engineering/storekit-views-guide-paywall-swift-ui/) (Jun 2024)
12. RevenueCat — [iOS Subscription Tutorial with StoreKit 2](https://www.revenuecat.com/blog/engineering/ios-in-app-subscription-tutorial-with-storekit-2-and-swift/) (Jun 2024)
13. Swift with Majid — [Mastering StoreKit 2 SubscriptionStoreView](https://swiftwithmajid.com/2023/08/23/mastering-storekit2-subscriptionstoreview-in-swiftui/) (Aug 2023)
14. DEV Community — [WWDC 2025 StoreKit Updates](https://dev.to/arshtechpro/wwdc-2025-whats-new-in-storekit-and-in-app-purchase-31if) (Jun 2025)
15. DEV Community — [App Store Offers Implementation Guide](https://dev.to/arshtechpro/wwdc-app-store-offers-implementation-guide-for-ios-developers-3lbh) (Jul 2025)
16. Internal — Lumifaste `SubscriptionManager.swift` + `PaywallView.swift`
17. Internal — Tendril `SubscriptionManager.swift`
18. Internal — Rolldark `StoreManager.swift`
19. Internal — EmojiDecode `StoreManager.swift`

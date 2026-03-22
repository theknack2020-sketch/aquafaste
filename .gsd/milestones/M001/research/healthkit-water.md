# HealthKit Water Tracking — Research

> Research date: 2026-03-22
> Target: iOS 17+, SwiftUI, Swift concurrency (async/await)

---

## 1. Project Setup (Prerequisites)

### Xcode Configuration

1. **Add HealthKit capability**: Target → Signing & Capabilities → + Capability → HealthKit
2. **Enable Background Delivery** (optional): Check "Background Delivery" under HealthKit capability. This adds the `com.apple.developer.healthkit.background-delivery` entitlement.
3. **Info.plist keys** (required for App Store):

```xml
<key>NSHealthShareUsageDescription</key>
<string>AquaFaste reads your water intake data to show daily hydration progress.</string>
<key>NSHealthUpdateUsageDescription</key>
<string>AquaFaste saves your water intake to Apple Health so it syncs across all your health apps.</string>
```

### Platform Availability

- HealthKit is **iPhone only** — not available on iPad (no Health app on iPad).
- Always guard with `HKHealthStore.isHealthDataAvailable()` before any HealthKit work.
- The simulator has limited HealthKit support; test on a real device for reliable results.

### Key Types for Water Tracking

```swift
import HealthKit

// The quantity type for water
let waterType = HKQuantityType(.dietaryWater)

// Supported units
let milliliters = HKUnit.literUnit(with: .milli)  // mL
let liters = HKUnit.liter()                        // L
let fluidOunces = HKUnit.fluidOunceUS()            // fl oz (US)
```

`dietaryWater` is a **cumulative** quantity type (aggregation style: `.cumulativeSum`), meaning statistics queries can sum samples over a time range.

---

## 2. Authorization

### Request Authorization (async/await — iOS 15+)

```swift
import HealthKit

final class HealthKitManager: ObservableObject {
    private let store = HKHealthStore()
    
    /// Check if HealthKit is available on this device
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    /// Request read+write authorization for dietary water
    func requestAuthorization() async throws {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }
        
        let waterType = HKQuantityType(.dietaryWater)
        
        // toShare = write permission, read = read permission
        try await store.requestAuthorization(
            toShare: [waterType],
            read: [waterType]
        )
    }
}
```

### Authorization Caveats

- **Privacy by design**: HealthKit never reveals whether the user denied read access. `authorizationStatus(for:)` only tells you about *write* access (`.sharingAuthorized`, `.sharingDenied`, `.notDetermined`). For read access, queries simply return no data if denied — you cannot distinguish "no data" from "permission denied".
- **One-shot prompt**: Once the user responds to the permission sheet, the system dialog will not appear again. If the user denied access, you must redirect them to: **Settings → Health → Your App** to re-enable permissions.
- **Check write authorization** before saving:

```swift
/// Returns true if the user has authorized writing water data
var canWriteWater: Bool {
    let status = store.authorizationStatus(for: HKQuantityType(.dietaryWater))
    return status == .sharingAuthorized
}
```

---

## 3. Saving Water Samples

### Basic Save (async/await)

```swift
/// Save a water intake entry to HealthKit
/// - Parameters:
///   - amount: Amount of water consumed
///   - unit: Unit of measurement (default: milliliters)
///   - date: When the water was consumed (default: now)
func saveWaterIntake(
    amount: Double,
    unit: HKUnit = .literUnit(with: .milli),
    date: Date = .now
) async throws {
    guard canWriteWater else {
        throw HealthKitError.notAuthorized
    }
    
    let waterType = HKQuantityType(.dietaryWater)
    let quantity = HKQuantity(unit: unit, doubleValue: amount)
    
    // For instantaneous intake, start == end
    let sample = HKQuantitySample(
        type: waterType,
        quantity: quantity,
        start: date,
        end: date
    )
    
    try await store.save(sample)
}
```

### Usage from SwiftUI

```swift
Button("Log 250 mL") {
    Task {
        do {
            try await healthKitManager.saveWaterIntake(amount: 250)
        } catch {
            // Handle error — show alert, log, etc.
            print("Failed to save water: \(error.localizedDescription)")
        }
    }
}
```

### Notes on Saving

- `start` and `end` should be the same `Date` for a point-in-time intake event.
- Use `HKUnit.liter()` for liters, `HKUnit.fluidOunceUS()` for US fluid ounces, `HKUnit.literUnit(with: .milli)` for milliliters.
- Be careful not to write duplicate samples. HealthKit does **not** deduplicate — each `save()` creates a new sample.
- Some apps wrap water in an `HKCorrelation` with `HKCorrelationTypeIdentifier.food`, but this is **not required** for water — saving an `HKQuantitySample` directly works fine and is the common approach.

---

## 4. Reading Daily Totals with HKStatisticsQuery

### Single-Day Total (async/await with withCheckedThrowingContinuation)

```swift
/// Fetch total water intake for a given day
/// - Parameter date: The day to query (defaults to today)
/// - Returns: Total water in milliliters, or 0 if no data
func fetchDailyWaterTotal(for date: Date = .now) async throws -> Double {
    let waterType = HKQuantityType(.dietaryWater)
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: date)
    let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
    
    let predicate = HKQuery.predicateForSamples(
        withStart: startOfDay,
        end: endOfDay,
        options: .strictStartDate
    )
    
    return try await withCheckedThrowingContinuation { continuation in
        let query = HKStatisticsQuery(
            quantityType: waterType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, statistics, error in
            if let error {
                continuation.resume(throwing: error)
                return
            }
            
            let ml = statistics?
                .sumQuantity()?
                .doubleValue(for: .literUnit(with: .milli)) ?? 0
            
            continuation.resume(returning: ml)
        }
        
        store.execute(query)
    }
}
```

### Why HKStatisticsQuery for Water?

- `dietaryWater` is a cumulative type, so `.cumulativeSum` is the correct option.
- `HKStatisticsQuery` automatically **deduplicates overlapping samples** from multiple sources (e.g., your app + another water tracking app), unlike raw `HKSampleQuery` which returns all individual samples.
- For weekly/monthly charts, use `HKStatisticsCollectionQuery` with `DateComponents(day: 1)` intervals.

### Modern Alternative: HKStatisticsQueryDescriptor (iOS 15.4+)

```swift
func fetchDailyWaterTotal(for date: Date = .now) async throws -> Double {
    let waterType = HKQuantityType(.dietaryWater)
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: date)
    let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
    
    let predicate = HKQuery.predicateForSamples(
        withStart: startOfDay,
        end: endOfDay,
        options: .strictStartDate
    )
    
    let descriptor = HKStatisticsQueryDescriptor(
        predicate: HKSamplePredicate.quantitySample(
            type: waterType,
            predicate: predicate
        ),
        options: .cumulativeSum
    )
    
    let result = try await descriptor.result(for: store)
    return result?.sumQuantity()?.doubleValue(for: .literUnit(with: .milli)) ?? 0
}
```

---

## 5. Fetching Individual Samples (HKSampleQuery)

Useful for displaying a log/history of individual water entries:

```swift
/// Fetch individual water intake entries for today
func fetchTodayWaterSamples() async throws -> [HKQuantitySample] {
    let waterType = HKQuantityType(.dietaryWater)
    let startOfDay = Calendar.current.startOfDay(for: .now)
    
    let predicate = HKQuery.predicateForSamples(
        withStart: startOfDay,
        end: .now,
        options: .strictStartDate
    )
    
    let sortDescriptor = NSSortDescriptor(
        key: HKSampleSortIdentifierEndDate,
        ascending: false
    )
    
    return try await withCheckedThrowingContinuation { continuation in
        let query = HKSampleQuery(
            sampleType: waterType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            if let error {
                continuation.resume(throwing: error)
                return
            }
            
            let waterSamples = (samples as? [HKQuantitySample]) ?? []
            continuation.resume(returning: waterSamples)
        }
        
        store.execute(query)
    }
}
```

### Reading Sample Values

```swift
for sample in waterSamples {
    let ml = sample.quantity.doubleValue(for: .literUnit(with: .milli))
    let date = sample.startDate
    let source = sample.sourceRevision.source.name  // "AquaFaste", "WaterMinder", etc.
    print("\(date): \(ml) mL from \(source)")
}
```

---

## 6. Observing Changes with HKObserverQuery

### Foreground Observer (live updates while app is running)

```swift
private var observerQuery: HKObserverQuery?

/// Start observing water intake changes from any source
func startObservingWaterChanges(onChange: @escaping () -> Void) {
    let waterType = HKQuantityType(.dietaryWater)
    
    let query = HKObserverQuery(
        sampleType: waterType,
        predicate: nil
    ) { [weak self] query, completionHandler, error in
        if let error {
            print("Observer query error: \(error.localizedDescription)")
            completionHandler()  // MUST call even on error
            return
        }
        
        // HKObserverQuery only notifies that data changed — 
        // it does NOT tell you what changed.
        // Run a fresh statistics query to get updated totals.
        DispatchQueue.main.async {
            onChange()
        }
        
        // CRITICAL: Always call the completion handler.
        // Failure to call it causes exponential backoff and 
        // eventual delivery suspension after 3 failures.
        completionHandler()
    }
    
    observerQuery = query
    store.execute(query)
}

/// Stop observing
func stopObservingWaterChanges() {
    if let query = observerQuery {
        store.stop(query)
        observerQuery = nil
    }
}
```

### Key Rules for HKObserverQuery

1. **Always call `completionHandler()`** — even on error. If you don't, HealthKit uses exponential backoff and stops delivering after 3 failures.
2. **Observer only notifies, not what changed** — you must run a separate query (HKStatisticsQuery, HKSampleQuery, or HKAnchoredObjectQuery) inside the handler to fetch updated data.
3. **Long-running** — the query stays active until you call `store.stop(query)` or the app terminates.
4. **No async/await variant** — HKObserverQuery uses closure-based callbacks. Wrap in a continuation if needed.

---

## 7. Background Delivery Setup

Background delivery lets your app receive HealthKit updates even when suspended or terminated.

### Step 1: Enable Entitlement

In Xcode: Target → Signing & Capabilities → HealthKit → check **"Background Delivery"**.

This adds:
```
com.apple.developer.healthkit.background-delivery = true
```

### Step 2: Register in App Lifecycle (do this on every launch)

```swift
// In your App struct or AppDelegate — must happen on every launch
func enableBackgroundDelivery() {
    let waterType = HKQuantityType(.dietaryWater)
    
    store.enableBackgroundDelivery(
        for: waterType,
        frequency: .hourly  // .immediate, .hourly, or .daily
    ) { success, error in
        if let error {
            print("Failed to enable background delivery: \(error.localizedDescription)")
        }
    }
}
```

### Step 3: Set Up Observer Query (also on every launch)

```swift
// SwiftUI App with AppDelegate
@main
struct AquaFasteApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    let store = HKHealthStore()
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        setupHealthKitBackgroundDelivery()
        return true
    }
    
    private func setupHealthKitBackgroundDelivery() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let waterType = HKQuantityType(.dietaryWater)
        
        // 1. Enable background delivery
        store.enableBackgroundDelivery(
            for: waterType,
            frequency: .hourly
        ) { success, error in
            if let error {
                print("BG delivery setup failed: \(error.localizedDescription)")
            }
        }
        
        // 2. Set up observer query
        let query = HKObserverQuery(
            sampleType: waterType,
            predicate: nil
        ) { query, completionHandler, error in
            defer { completionHandler() }
            
            guard error == nil else {
                print("BG observer error: \(error!.localizedDescription)")
                return
            }
            
            // App was woken up — water data changed.
            // Refresh local state, update widgets, etc.
            self.handleWaterDataChanged()
        }
        
        store.execute(query)
    }
    
    private func handleWaterDataChanged() {
        // Re-query totals, update UserDefaults for widgets, post notification, etc.
        NotificationCenter.default.post(name: .healthKitWaterDataChanged, object: nil)
    }
}

extension Notification.Name {
    static let healthKitWaterDataChanged = Notification.Name("healthKitWaterDataChanged")
}
```

### Background Delivery Caveats

- **`enableBackgroundDelivery` must be called on every app launch** — it does not persist across launches.
- **Frequency is a minimum interval**, not a guarantee. `.immediate` does not mean truly instant — the system batches deliveries.
- **iOS may throttle delivery** based on battery state, Low Power Mode, and system conditions.
- **The app cannot read HealthKit when the iPhone is locked** — this is by design for privacy. Background delivery will queue updates and deliver them when the device unlocks.
- **The observer completion handler is critical** — always call it in every code path (use `defer`).
- **Background delivery on watchOS** shares a budget with `WKApplicationRefreshBackgroundTask` (4 updates/hour with an active complication).

---

## 8. Error Handling Patterns

### Custom Error Type

```swift
enum HealthKitError: LocalizedError {
    case notAvailable
    case notAuthorized
    case queryFailed(Error)
    case saveFailed(Error)
    case invalidQuantity
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Health data is not available on this device."
        case .notAuthorized:
            return "Water tracking permission not granted. Please enable in Settings → Health."
        case .queryFailed(let error):
            return "Failed to read water data: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save water data: \(error.localizedDescription)"
        case .invalidQuantity:
            return "Invalid water quantity."
        }
    }
}
```

### Defensive Patterns

```swift
// Always check availability first
guard HKHealthStore.isHealthDataAvailable() else {
    throw HealthKitError.notAvailable
}

// Check write authorization before saving
guard store.authorizationStatus(for: waterType) == .sharingAuthorized else {
    throw HealthKitError.notAuthorized
}

// Validate quantities before creating samples
guard amount > 0, amount < 10_000 else {  // sanity check: 0–10L
    throw HealthKitError.invalidQuantity
}
```

### Known HealthKit Error Codes

| Code | Domain | Meaning |
|------|--------|---------|
| 5 | com.apple.healthkit | Authorization not determined |
| 4 | com.apple.healthkit | Missing background-delivery entitlement |
| — | — | `HKError.errorHealthDataUnavailable` — device doesn't support HealthKit |
| — | — | `HKError.errorNoData` — query returned no matching samples |

---

## 9. Complete Manager Pattern

```swift
import HealthKit
import Combine

@MainActor
final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    private let store = HKHealthStore()
    private let waterType = HKQuantityType(.dietaryWater)
    private var observerQuery: HKObserverQuery?
    
    @Published var todayTotal: Double = 0  // in mL
    @Published var isAuthorized: Bool = false
    
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    var canWriteWater: Bool {
        store.authorizationStatus(for: waterType) == .sharingAuthorized
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async throws {
        guard isAvailable else { throw HealthKitError.notAvailable }
        
        try await store.requestAuthorization(
            toShare: [waterType],
            read: [waterType]
        )
        
        isAuthorized = canWriteWater
    }
    
    // MARK: - Write
    
    func logWater(ml: Double, at date: Date = .now) async throws {
        guard canWriteWater else { throw HealthKitError.notAuthorized }
        guard ml > 0, ml < 10_000 else { throw HealthKitError.invalidQuantity }
        
        let quantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: ml)
        let sample = HKQuantitySample(
            type: waterType,
            quantity: quantity,
            start: date,
            end: date
        )
        
        try await store.save(sample)
        await refreshTodayTotal()
    }
    
    // MARK: - Read
    
    func refreshTodayTotal() async {
        do {
            todayTotal = try await fetchDailyTotal(for: .now)
        } catch {
            print("Failed to refresh water total: \(error.localizedDescription)")
        }
    }
    
    func fetchDailyTotal(for date: Date) async throws -> Double {
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        
        let predicate = HKQuery.predicateForSamples(
            withStart: start, end: end, options: .strictStartDate
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: waterType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let ml = statistics?.sumQuantity()?
                    .doubleValue(for: .literUnit(with: .milli)) ?? 0
                continuation.resume(returning: ml)
            }
            self.store.execute(query)
        }
    }
    
    // MARK: - Observe
    
    func startObserving() {
        guard observerQuery == nil else { return }
        
        let query = HKObserverQuery(
            sampleType: waterType,
            predicate: nil
        ) { [weak self] _, completionHandler, error in
            defer { completionHandler() }
            guard error == nil else { return }
            
            Task { @MainActor in
                await self?.refreshTodayTotal()
            }
        }
        
        observerQuery = query
        store.execute(query)
    }
    
    func stopObserving() {
        if let query = observerQuery {
            store.stop(query)
            observerQuery = nil
        }
    }
    
    // MARK: - Background Delivery
    
    nonisolated func enableBackgroundDelivery() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        store.enableBackgroundDelivery(
            for: HKQuantityType(.dietaryWater),
            frequency: .hourly
        ) { success, error in
            if let error {
                print("BG delivery error: \(error.localizedDescription)")
            }
        }
    }
}
```

---

## 10. Deleting Samples

If you need to let users undo/delete water entries:

```swift
/// Delete a specific water sample (must be one your app created)
func deleteWaterSample(_ sample: HKQuantitySample) async throws {
    try await store.delete(sample)
}
```

**Important**: You can only delete samples your app created. Attempting to delete samples from other apps will fail silently or throw an error.

---

## 11. Gotchas & Edge Cases

1. **No iPad support** — HealthKit is unavailable on iPad. Always check `HKHealthStore.isHealthDataAvailable()`.
2. **Read permission is opaque** — You cannot determine if the user denied read access. Queries return empty results whether denied or simply no data.
3. **Denied write ≠ re-promptable** — Once denied, the system prompt never reappears. Guide users to Settings.
4. **Duplicate prevention** — HealthKit does not deduplicate. Your app must track what it has saved (e.g., via metadata or local DB).
5. **Thread safety** — `HKHealthStore` is thread-safe, but query callbacks execute on arbitrary background queues. Dispatch to `@MainActor` for UI updates.
6. **Background delivery frequency** — `.immediate` is a hint, not a guarantee. System conditions affect actual delivery timing.
7. **Locked device** — HealthKit reads fail when the device is locked. Background delivery queues and delivers after unlock.
8. **Unit conversion** — Always use HealthKit's built-in unit system (`HKUnit`). Never do manual conversion math.
9. **Source deduplication** — `HKStatisticsQuery` handles overlapping samples from multiple sources automatically. Raw `HKSampleQuery` does not.

---

## Sources

1. [Apple: dietaryWater Documentation](https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier/1615313-dietarywater)
2. [Apple: HKObserverQuery](https://developer.apple.com/documentation/healthkit/hkobserverquery)
3. [Apple: HKStatisticsQuery](https://developer.apple.com/documentation/healthkit/hkstatisticsquery)
4. [Apple: enableBackgroundDelivery](https://developer.apple.com/documentation/HealthKit/HKHealthStore/enableBackgroundDelivery(for:frequency:withCompletion:))
5. [Apple: Background Delivery Entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.healthkit.background-delivery)
6. [Apple: WWDC20 — Getting Started with HealthKit](https://developer.apple.com/videos/play/wwdc2020/10664/)
7. [Gulps — Open Source Water Tracking App (HealthKit helper)](https://github.com/FancyPixel/gulps/blob/master/Gulps/Support/HealthKitHealper.swift)
8. [Kodeco: HealthKit Water Tracking (watchOS)](https://www.kodeco.com/books/watchos-with-swiftui-by-tutorials/v1.0/chapters/15-healthkit)
9. [Phatblat: HKObserverQuery + Background Delivery Gist](https://gist.github.com/phatblat/654ab2b3a135edf905f4a854fdb2d7c8)
10. [iTwenty: Read Workouts with Observer Query](https://itwenty.me/posts/09-healthkit-workout-updates/)
11. [Apple Developer Forums: Water Intake Query Issues](https://developer.apple.com/forums/tags/healthkit?page=4)
12. [Mark Volkmann: HealthKit Guide](https://mvolkmann.github.io/blog/swift/HealthKit/)
13. [DevFright: HKStatisticsQuery](https://www.devfright.com/the-healthkit-hkstatisticsquery/)
14. [DevFright: HKStatisticsCollectionQuery](https://www.devfright.com/how-to-use-the-hkstatisticscollectionquery/)

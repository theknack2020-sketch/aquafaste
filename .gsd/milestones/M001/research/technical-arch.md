# Technical Architecture Research — AquaFaste Hydration Tracker

> Research date: 2026-03-22  
> Scope: HealthKit, Apple Watch complications, WidgetKit, notifications, SwiftData, background refresh, Siri Shortcuts, CloudKit sync

---

## 1. HealthKit Integration (dietaryWater read/write)

### Identifier & Type

- **Identifier:** `HKQuantityTypeIdentifier.dietaryWater`
- **Type:** `HKQuantityType` — a quantity sample measuring water consumed
- **Units:** `HKUnit.liter()`, `HKUnit.literUnit(with: .milli)`, `HKUnit.fluidOunceUS()`
- **Platform:** iPhone only (Health app is not available on iPad or Mac)

### Authorization

```swift
let waterType = HKQuantityType(.dietaryWater)
let typesToShare: Set<HKSampleType> = [waterType]
let typesToRead: Set<HKObjectType> = [waterType]

try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
```

**Critical caveats:**
- Once a user denies access, the system will **never show the permission dialog again**. The app must redirect users to Settings → Health → App to re-enable.
- `authorizationStatus(for:)` returns `.notDetermined`, `.sharingDenied`, or `.sharingAuthorized` — but **read authorization status is never disclosed** for privacy (you can't tell if the user denied read access; queries simply return no results).
- Always call `HKHealthStore.isHealthDataAvailable()` before any HealthKit operation.

### Writing a Water Sample

```swift
func saveWaterIntake(milliliters: Double) async throws {
    let waterType = HKQuantityType(.dietaryWater)
    let quantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: milliliters)
    let sample = HKQuantitySample(
        type: waterType,
        quantity: quantity,
        start: Date(),
        end: Date()
    )
    try await healthStore.save(sample)
}
```

### Reading / Querying Water Intake

Use `HKStatisticsQuery` with `.cumulativeSum` to get total daily intake:

```swift
func todayWaterIntake() async throws -> Double {
    let waterType = HKQuantityType(.dietaryWater)
    let startOfDay = Calendar.current.startOfDay(for: Date())
    let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date())
    
    let stats = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<HKStatistics, Error>) in
        let query = HKStatisticsQuery(
            quantityType: waterType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            if let error { cont.resume(throwing: error) }
            else if let result { cont.resume(returning: result) }
        }
        healthStore.execute(query)
    }
    return stats.sumQuantity()?.doubleValue(for: .literUnit(with: .milli)) ?? 0
}
```

### Deleting Samples

You **cannot delete an object you just created in memory**. You must query HealthKit for the saved objects, then delete the returned `HKObject` instances:

```swift
let samples = try await healthStore.samples(matching: query)
try await healthStore.delete(samples)
```

### Observer Query (Background Delivery)

Register an `HKObserverQuery` + `enableBackgroundDelivery(for:frequency:)` to receive callbacks when **other apps** write water data to HealthKit. This keeps our local store in sync.

```swift
healthStore.enableBackgroundDelivery(for: waterType, frequency: .immediate) { success, error in }
```

### Entitlements Required

- **HealthKit capability** in Signing & Capabilities
- **Info.plist keys:**
  - `NSHealthShareUsageDescription` (read)
  - `NSHealthUpdateUsageDescription` (write)

---

## 2. Apple Watch Complications (via WidgetKit)

### Architecture (watchOS 9+)

ClockKit is deprecated. All new complications use **WidgetKit** with the accessory widget families. This means a single codebase can power both **iOS Lock Screen widgets** and **watchOS complications**.

### Widget Families for Complications

| Family | Description | Use Case for Hydration |
|--------|-------------|----------------------|
| `accessoryCircular` | Small circular view | Progress ring showing % of daily goal |
| `accessoryRectangular` | Multi-line text/small charts | "1.2L / 2.5L" with mini bar chart |
| `accessoryInline` | Single line of text | "1200ml — 48% of goal" |
| `accessoryCorner` | watchOS-only, corner of face | Gauge arc showing progress + icon |

### Implementation Pattern

```swift
struct HydrationComplication: Widget {
    let kind = "HydrationComplication"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HydrationTimelineProvider()) { entry in
            HydrationComplicationView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Hydration")
        .description("Track your daily water intake")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCorner  // watchOS only
        ])
    }
}
```

### Timeline Provider

```swift
struct HydrationTimelineProvider: TimelineProvider {
    func getTimeline(in context: Context, completion: @escaping (Timeline<HydrationEntry>) -> Void) {
        // Read current intake from shared container / HealthKit
        let entry = HydrationEntry(date: .now, currentML: 1200, goalML: 2500)
        // Refresh every 15 minutes or after next expected drink
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}
```

### Watch-Specific Considerations

- **`accessoryCorner`** supports `.widgetLabel { }` for curved text around the circular content
- **Always-On Display:** Use `@Environment(\.isLuminanceReduced)` to dim content in always-on mode
- **Privacy:** Use `.privacySensitive()` modifier on data that should be redacted on locked screens
- **Tinting:** Use `@Environment(\.widgetRenderingMode)` to adapt between `.fullColor`, `.accented`, and `.vibrant` rendering
- **Cache behavior:** watchOS complications are cached aggressively — changes won't reflect immediately during development. Kill the Watch Simulator and rebuild.

### Updating Complications from the Phone

Use `WCSession` (Watch Connectivity) to push updated data to the watch, then call `WidgetCenter.shared.reloadTimelines(ofKind:)` on the watch side.

---

## 3. WidgetKit — Home Screen & Lock Screen Widgets

### Widget Types for Hydration

| Family | Platform | Best Use |
|--------|----------|----------|
| `systemSmall` | iOS Home Screen | Circular progress + number |
| `systemMedium` | iOS Home Screen | Progress + recent drinks list |
| `systemLarge` | iOS Home Screen | Full day timeline chart |
| `accessoryCircular` | iOS Lock Screen | Progress ring |
| `accessoryRectangular` | iOS Lock Screen | Text + mini chart |
| `accessoryInline` | iOS Lock Screen | One-liner status |

### Interactive Widgets (iOS 17+)

Since iOS 17, widgets support **interactivity via AppIntents**. A "Log Water" button can be placed directly on the widget:

```swift
struct LogWaterIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Water"
    
    @Parameter(title: "Amount (ml)")
    var amount: Int
    
    init() { self.amount = 250 }
    
    func perform() async throws -> some IntentResult {
        let manager = HydrationManager.shared
        try await manager.logWater(ml: Double(amount))
        return .result()
    }
}

// In widget view:
Button(intent: LogWaterIntent(amount: 250)) {
    Label("250ml", systemImage: "drop.fill")
}
```

### Data Sharing Between App and Widget

Widgets run in a **separate process** and cannot access the main app's data store directly. Solutions:

1. **App Group container:** Both app and widget extension share an App Group. SwiftData's `ModelConfiguration` supports this:

```swift
let config = ModelConfiguration(
    schema: Schema([WaterLog.self]),
    groupContainer: .identifier("group.com.aquafaste.shared")
)
```

2. **Shared UserDefaults:**

```swift
let defaults = UserDefaults(suiteName: "group.com.aquafaste.shared")
defaults?.set(totalML, forKey: "todayIntake")
```

### Timeline Reload Strategies

- **`.atEnd`** — reload when the last entry's date passes
- **`.after(date)`** — reload at a specific time
- **`.never`** — only reload when explicitly triggered
- **Explicit reload:** Call `WidgetCenter.shared.reloadTimelines(ofKind: "HydrationWidget")` from the main app after each water log

### Relevant Budgets

Widget reloads are **budgeted by the system**. Apps in active use get ~40-70 reloads/day. Calling `reloadTimelines` is the most reliable trigger.

---

## 4. Smart Notification Strategies

### Notification Types

#### A. Time-Based Reminders (UNCalendarNotificationTrigger)

Fixed-interval reminders throughout the day:

```swift
func scheduleHourlyReminders(from startHour: Int, to endHour: Int) {
    let center = UNUserNotificationCenter.current()
    
    for hour in startHour...endHour {
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = "Time to hydrate 💧"
        content.body = "You've had \(currentML)ml today. \(remainingML)ml to go!"
        content.sound = .default
        content.categoryIdentifier = "HYDRATION_REMINDER"
        
        let request = UNNotificationRequest(identifier: "reminder-\(hour)", content: content, trigger: trigger)
        center.add(request)
    }
}
```

#### B. Interval-Based Reminders (UNTimeIntervalNotificationTrigger)

Adaptive intervals (e.g., every 45 minutes during active hours):

```swift
let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 45 * 60, repeats: true)
```

#### C. Activity-Based / Context-Aware Reminders

Use **CoreMotion** or **HealthKit workout sessions** to detect activity:

```swift
// After workout detection — boost reminder
func schedulePostWorkoutReminder() {
    let content = UNMutableNotificationContent()
    content.title = "Rehydrate! 🏃‍♂️"
    content.body = "Great workout! Drink some extra water to recover."
    content.interruptionLevel = .timeSensitive  // iOS 15+, breaks through Focus
    
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
    let request = UNNotificationRequest(identifier: "post-workout", content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request)
}
```

#### D. Smart Suppression Logic

Don't annoy the user — suppress reminders when:
- User already logged water in the last 30 minutes
- Daily goal is already met
- It's outside the user's configured active hours (Do Not Disturb awareness)
- Device is in Sleep Focus

#### E. Actionable Notifications

```swift
let logAction = UNNotificationAction(identifier: "LOG_250ML", title: "Log 250ml 💧", options: [])
let logLargeAction = UNNotificationAction(identifier: "LOG_500ML", title: "Log 500ml 💧", options: [])
let snoozeAction = UNNotificationAction(identifier: "SNOOZE", title: "Remind in 15min", options: [])

let category = UNNotificationCategory(
    identifier: "HYDRATION_REMINDER",
    actions: [logAction, logLargeAction, snoozeAction],
    intentIdentifiers: [],
    options: [.customDismissAction]
)
UNUserNotificationCenter.current().setNotificationCategories([category])
```

### Notification Budget

iOS limits local notifications to **64 scheduled at a time**. Reschedule the next batch each time the app launches or a notification fires.

---

## 5. SwiftData Models

### Core Model Design

```swift
import SwiftData

@Model
final class WaterLog {
    #Unique<WaterLog>([\.id])
    #Index<WaterLog>([\.timestamp])
    #Index<WaterLog>([\.date])
    
    var id: UUID
    var timestamp: Date
    var date: String           // "2026-03-22" for fast day-grouping queries
    var amountML: Double
    var source: LogSource      // .manual, .siri, .widget, .complication, .notification
    var healthKitSynced: Bool
    var healthKitSampleUUID: String?  // HKSample UUID for delete tracking
    
    init(amountML: Double, source: LogSource = .manual) {
        self.id = UUID()
        self.timestamp = Date()
        self.date = Self.dateFormatter.string(from: Date())
        self.amountML = amountML
        self.source = source
        self.healthKitSynced = false
    }
    
    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}

enum LogSource: String, Codable {
    case manual, siri, widget, complication, notification, watch
}
```

```swift
@Model
final class DailyGoal {
    #Unique<DailyGoal>([\.date])
    
    var date: String            // "2026-03-22"
    var goalML: Double
    var achieved: Bool
    var achievedAt: Date?
    
    init(date: String, goalML: Double) {
        self.date = date
        self.goalML = goalML
        self.achieved = false
    }
}
```

```swift
@Model
final class UserProfile {
    var dailyGoalML: Double     // Default 2500
    var preferredUnit: HydrationUnit  // .ml or .oz
    var reminderStartHour: Int  // 8
    var reminderEndHour: Int    // 22
    var reminderIntervalMinutes: Int // 60
    var quickLogAmounts: [Double]  // [150, 250, 500, 750]
    var weight: Double?         // kg, for adaptive goal calculation
    
    init() {
        self.dailyGoalML = 2500
        self.preferredUnit = .ml
        self.reminderStartHour = 8
        self.reminderEndHour = 22
        self.reminderIntervalMinutes = 60
        self.quickLogAmounts = [150, 250, 500, 750]
    }
}

enum HydrationUnit: String, Codable {
    case ml, oz
}
```

### ModelContainer Configuration

```swift
let schema = Schema([WaterLog.self, DailyGoal.self, UserProfile.self])
let config = ModelConfiguration(
    "AquaFaste",
    schema: schema,
    groupContainer: .identifier("group.com.aquafaste.shared"),
    cloudKitDatabase: .automatic  // enables CloudKit sync
)
let container = try ModelContainer(for: schema, configurations: [config])
```

### Key Design Decisions

- **`date` as String field** with index for O(1) day lookups without date math in predicates
- **`healthKitSampleUUID`** stored so we can delete the exact HealthKit sample if the user undoes a log
- **`source` enum** tracks provenance — useful for analytics (which entry point is most used)
- **`#Unique` on id** prevents duplicate inserts from widget/notification races
- **App Group container** required so widget extension, watch app, and main app all read/write the same store

---

## 6. Background App Refresh

### BGAppRefreshTask

```swift
// Register in AppDelegate or App init
BGTaskScheduler.shared.register(
    forTaskWithIdentifier: "com.aquafaste.refresh",
    using: nil
) { task in
    handleAppRefresh(task: task as! BGAppRefreshTask)
}

func scheduleAppRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: "com.aquafaste.refresh")
    request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 min minimum
    try? BGTaskScheduler.shared.submit(request)
}

func handleAppRefresh(task: BGAppRefreshTask) {
    // 1. Sync HealthKit data (other apps may have logged water)
    // 2. Recalculate today's total
    // 3. Update widget timelines
    // 4. Reschedule next batch of notifications
    // 5. Schedule next refresh
    scheduleAppRefresh()
    task.setTaskCompleted(success: true)
}
```

### BGProcessingTask (Heavy Work)

For daily summary computation, streak calculations, or large CloudKit syncs:

```swift
BGTaskScheduler.shared.register(
    forTaskWithIdentifier: "com.aquafaste.dailySummary",
    using: nil
) { task in
    handleDailySummary(task: task as! BGProcessingTask)
}

let request = BGProcessingTaskRequest(identifier: "com.aquafaste.dailySummary")
request.requiresNetworkConnectivity = true  // for CloudKit sync
request.requiresExternalPower = false
request.earliestBeginDate = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400)) // midnight
```

### HealthKit Background Delivery

Distinct from BGTaskScheduler — HealthKit has its own background delivery:

```swift
let waterType = HKQuantityType(.dietaryWater)
healthStore.enableBackgroundDelivery(for: waterType, frequency: .immediate) { success, error in }

// Register observer query
let observerQuery = HKObserverQuery(sampleType: waterType, predicate: nil) { query, completionHandler, error in
    // Another app wrote water data — update our totals + widgets
    WidgetCenter.shared.reloadTimelines(ofKind: "HydrationWidget")
    completionHandler()
}
healthStore.execute(observerQuery)
```

### Info.plist

```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.aquafaste.refresh</string>
    <string>com.aquafaste.dailySummary</string>
</array>
```

### Practical Limits

- Background refresh is **not guaranteed** — iOS schedules it based on user behavior patterns
- Apps the user opens frequently get more background time
- Heavy processing tasks may only run while charging
- HealthKit background delivery for `.immediate` frequency wakes the app ~once per hour (not truly immediate)

---

## 7. Siri Shortcuts & App Intents

### App Intents Framework (iOS 16+, preferred over SiriKit Intents)

```swift
import AppIntents

struct LogWaterIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Water"
    static var description = IntentDescription("Log water intake to AquaFaste")
    static var openAppWhenRun: Bool = false  // runs in background
    
    @Parameter(title: "Amount", default: 250)
    var amountML: Int
    
    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$amountML) ml of water")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<Int> {
        let manager = HydrationManager.shared
        try await manager.logWater(ml: Double(amountML))
        let total = try await manager.todayTotal()
        return .result(
            value: Int(total),
            dialog: "Logged \(amountML)ml. Today's total: \(Int(total))ml 💧"
        )
    }
}
```

### Shortcuts Provider (Suggested Shortcuts)

```swift
struct AquaFasteShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogWaterIntent(),
            phrases: [
                "Log water in \(.applicationName)",
                "I drank water",
                "Log \(\.$amountML) ml in \(.applicationName)",
                "Add water to \(.applicationName)"
            ],
            shortTitle: "Log Water",
            systemImageName: "drop.fill"
        )
        AppShortcut(
            intent: CheckHydrationIntent(),
            phrases: [
                "How much water did I drink today",
                "Check my hydration in \(.applicationName)",
                "Water status in \(.applicationName)"
            ],
            shortTitle: "Check Hydration",
            systemImageName: "chart.bar.fill"
        )
    }
}
```

### Check Hydration Status Intent

```swift
struct CheckHydrationIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Hydration"
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let total = try await HydrationManager.shared.todayTotal()
        let goal = try await HydrationManager.shared.todayGoal()
        let pct = Int((total / goal) * 100)
        return .result(dialog: "You've had \(Int(total))ml today — \(pct)% of your \(Int(goal))ml goal.")
    }
}
```

### Integration Points

- **Siri voice:** "Log water in AquaFaste" / "I drank water"
- **Shortcuts app:** User can build automations (e.g., log water after morning alarm)
- **Spotlight suggestions:** Appear based on user behavior patterns
- **Interactive widgets:** Same `AppIntent` powers widget buttons
- **Action button (iPhone 15 Pro+):** Can be configured to run any shortcut

### Donate for Prediction

```swift
// Call after each manual log to help Siri predict
LogWaterIntent.donate(amount: 250)
```

---

## 8. CloudKit Sync

### SwiftData + CloudKit (Zero-Code Sync)

SwiftData with `.cloudKitDatabase: .automatic` provides automatic sync via `NSPersistentCloudKitContainer` under the hood.

```swift
let config = ModelConfiguration(
    schema: schema,
    groupContainer: .identifier("group.com.aquafaste.shared"),
    cloudKitDatabase: .automatic
)
```

### Requirements & Constraints

1. **All model properties must be optional or have defaults** — CloudKit records may arrive partially
2. **No unique constraints with CloudKit** — `#Unique` is incompatible with CloudKit sync (last-write-wins merge)
3. **Relationships must have inverse** — CloudKit requires bidirectional relationships
4. **No ordered relationships** — use a sort index field instead
5. **Entitlements:** iCloud capability → CloudKit → enable the container (`iCloud.com.aquafaste`)

### Model Adjustments for CloudKit Compatibility

```swift
@Model
final class WaterLog {
    // Note: NO #Unique when using CloudKit — use app-level dedup instead
    #Index<WaterLog>([\.timestamp])
    
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var date: String = ""
    var amountML: Double = 0
    var sourceRaw: String = LogSource.manual.rawValue  // CloudKit needs primitive types
    var healthKitSynced: Bool = false
    var healthKitSampleUUID: String?
    
    var source: LogSource {
        get { LogSource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }
}
```

### Conflict Resolution

CloudKit uses **last-write-wins** for field-level conflicts. For a hydration tracker this is acceptable because:
- Water logs are append-only (rarely edited)
- Each log has a unique UUID — conflicts only arise if the same log is edited on two devices simultaneously
- Goal changes are infrequent

### Sync Status Monitoring

```swift
NotificationCenter.default.addObserver(
    forName: NSPersistentCloudKitContainer.eventChangedNotification,
    object: nil,
    queue: .main
) { notification in
    if let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationKey] as? NSPersistentCloudKitContainer.Event {
        // Monitor import/export/setup events
        // Surface sync errors to the user
    }
}
```

### App Group + CloudKit Together

Both the main app and widget extension need:
- Same App Group (`group.com.aquafaste.shared`)
- Same CloudKit container (`iCloud.com.aquafaste`)
- Shared `ModelConfiguration` with both `groupContainer` and `cloudKitDatabase` set

The widget reads from the same synced store — no extra plumbing needed.

---

## Architecture Summary

### Target Stack

| Layer | Technology | Min OS |
|-------|-----------|--------|
| UI | SwiftUI | iOS 17 |
| Data | SwiftData | iOS 17 |
| Health | HealthKit | iOS 17 |
| Widgets | WidgetKit (interactive) | iOS 17 |
| Watch | WidgetKit complications | watchOS 10 |
| Intents | App Intents | iOS 16 |
| Sync | CloudKit (via SwiftData) | iOS 17 |
| Background | BGTaskScheduler + HK delivery | iOS 13 |
| Notifications | UserNotifications | iOS 10 |

### Shared Data Flow

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│  Main App   │     │  Widget Ext  │     │  Watch App  │
│  (SwiftUI)  │     │  (WidgetKit) │     │  (SwiftUI)  │
└──────┬──────┘     └──────┬───────┘     └──────┬──────┘
       │                   │                     │
       ▼                   ▼                     │
┌──────────────────────────────────┐             │
│  SwiftData (App Group Container) │◄────────────┘
│  + CloudKit Sync                 │  (WatchConnectivity
└──────────────┬───────────────────┘   or independent
               │                       CloudKit sync)
               ▼
┌──────────────────────┐
│     HealthKit        │
│  (dietaryWater r/w)  │
└──────────────────────┘
```

### Key Technical Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| CloudKit + `#Unique` incompatibility | High | Drop unique constraints; dedup at app level using UUID |
| HealthKit read denial invisible to app | Medium | Design UX assuming data may not be available; don't block core flow |
| Widget reload budget exhaustion | Medium | Use `.after(date)` policy; don't reload on every sip |
| 64 notification limit | Medium | Schedule only next 12-16 hours; reschedule on app launch |
| Background refresh not guaranteed | Low | App works fully without it; refresh is optimization only |
| Watch Simulator complication caching | Low | Dev-only issue; document in onboarding |

### Recommended iOS Deployment Target

**iOS 17.0** — required for interactive widgets (Button in WidgetKit), SwiftData, and the latest AppIntents features. watchOS 10.0 for the watch companion.

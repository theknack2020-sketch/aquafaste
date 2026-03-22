# S01 Plan — Core Timer & Data Layer

## Objective
Build the foundation: SwiftData models, water logging, circular progress, drink types, daily history, HealthKit integration, and tab navigation.

## Tasks

- [ ] **T01: Project Setup** `est:15m`
  - XcodeGen project.yml (iOS 17+, SwiftUI lifecycle, HealthKit entitlement)
  - Color+Theme extension (cyan/blue palette)
  - App entry point with TabView (Timer, History, Settings)
  - Generate .xcodeproj, verify build succeeds

- [ ] **T02: Data Models** `est:20m`
  - WaterLog: id, timestamp, amount (ml), drinkType, healthKitUUID
  - DrinkType enum: water, coffee, tea, juice, milk, soda, sparklingWater, coconutWater, smoothie, soup, beer, wine — with hydration ratios
  - UserProfile: weight, activityLevel, dailyGoal, unit preference, reminderInterval, sleepStart, sleepEnd, onboardingComplete
  - DailyGoal computed from weight formula
  - SwiftData @Model annotations, indexes on timestamp

- [ ] **T03: Timer View & Circular Progress** `est:30m`
  - CircularProgressView with gradient ring (cyan→blue)
  - Wave fill animation inside circle
  - Current intake / goal display (e.g., "1200 / 2400 ml")
  - Quick-add buttons (preset cup sizes: 250ml, 350ml, 500ml)
  - Start with drop.fill SF Symbol in center when empty
  - Haptic feedback on log

- [ ] **T04: Drink Type Selection** `est:20m`
  - Drink type picker (grid/list of beverage icons)
  - Each drink shows name + hydration ratio
  - Selected drink type applies ratio to logged amount
  - Custom amount input option

- [ ] **T05: History View** `est:20m`
  - Daily log list (grouped by date)
  - Weekly summary chart (bar chart, 7 days)
  - Each entry shows: time, drink type icon, amount, effective hydration
  - Streak counter display

- [ ] **T06: HealthKit Integration** `est:20m`
  - Request authorization (dietaryWater write, bodyMass read)
  - Save water samples on each log
  - Read body mass for goal calculation
  - Handle silent denial gracefully

- [ ] **T07: Settings View Stub** `est:10m`
  - Units toggle (ml / fl oz)
  - Daily goal display/override
  - Reminder settings placeholder
  - About / version info
  - Lumifaste cross-promo row (stub)

## Verification
- xcodebuild succeeds with 0 errors
- App launches in simulator showing Timer tab
- Water can be logged and appears in History
- HealthKit data visible in Health app
- Circular progress animates on log

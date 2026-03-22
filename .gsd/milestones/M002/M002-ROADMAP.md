# M002: AquaFaste MVP Build

**Vision:** Ship a clean, ad-free hydration tracker to the App Store — the sister app to Lumifaste.

## Success Criteria

- User can log water intake with one tap and see progress fill visually
- Personalized daily goal calculates from user's weight and activity level
- Smart reminders fire at intervals, respect sleep hours, stop when goal met
- 10+ beverage types tracked with hydration ratios (coffee 0.85x, milk 1.5x, etc.)
- Streak tracking shows consecutive days with celebrations at milestones
- HealthKit receives dietaryWater data after each log
- Subscription paywall gates premium features, free tier is genuinely useful
- App builds, archives, and uploads to App Store Connect via fastlane

## Key Risks / Unknowns

- HealthKit authorization flow + silent denial handling — must work first time
- Wave/liquid fill animation performance on older devices
- StoreKit 2 lifetime purchase + subscription coexistence

## Proof Strategy

- HealthKit → retire in S01 by proving water logs appear in Apple Health
- Animations → retire in S01 by verifying smooth 60fps on iPhone 15 simulator
- StoreKit → retire in S02 by testing mixed product types in sandbox

## Verification Classes

- Contract verification: xcodebuild succeeds with 0 errors, 0 warnings
- Integration verification: HealthKit data visible in Health app, StoreKit sandbox purchase flow
- Operational verification: fastlane archive + upload to ASC
- UAT / human verification: simulator screenshots of all flows

## Milestone Definition of Done

- All 6 slices complete with summaries
- App runs on simulator with full feature set
- Build archives and uploads to App Store Connect
- All screenshots captured (6.7", 6.1", iPad 13")
- Submitted for App Store review

## Requirement Coverage

- Covers: R001, R002, R003, R004, R005, R006, R007, R008, R009, R010, R011, R012
- Leaves for later: R013 (Watch), R014 (Widgets), R015 (Siri)

## Slices

- [ ] **S01: Core Timer & Data Layer** `risk:high` `depends:[]`
  > After this: user can log water, see circular progress fill, view daily history, and water data appears in HealthKit

- [ ] **S02: StoreKit 2 Subscription** `risk:high` `depends:[S01]`
  > After this: paywall shows plans ($3.99/mo, $19.99/yr, $39.99 lifetime), sandbox purchase works, premium features gate correctly

- [ ] **S03: Onboarding & Personalization** `risk:low` `depends:[S01]`
  > After this: new users go through weight→activity→goal→reminders flow, daily goal personalizes automatically

- [ ] **S04: Smart Reminders & Notifications** `risk:medium` `depends:[S01,S03]`
  > After this: reminders fire at intervals, respect sleep hours, stop when goal met, milestone notifications work

- [ ] **S05: App Icon & Branding** `risk:low` `depends:[S01]`
  > After this: cyan/blue app icon renders at all sizes, accent colors applied, visual identity complete

- [ ] **S06: Integration, Polish & Launch** `risk:medium` `depends:[S01,S02,S03,S04,S05]`
  > After this: app builds with 0 warnings, archives via fastlane, uploads to ASC, all screenshots captured, submitted for review

## Boundary Map

### S01 → S02
Produces:
- SwiftData models: WaterLog, UserProfile, DailyGoal
- SubscriptionManager stub with isPremium check
- Tab navigation structure (Timer, History, Settings)
- Color+Theme extension with cyan/blue palette

### S01 → S03
Produces:
- UserProfile model with weight, activityLevel, dailyGoal fields
- Goal calculation logic (weight-based formula)

### S01 → S04
Produces:
- WaterLog model with timestamp, amount, drinkType
- UserProfile with reminderInterval, sleepStart, sleepEnd

### S03 → S04
Produces:
- Completed UserProfile with reminder preferences set during onboarding

### S01,S02,S03,S04,S05 → S06
Produces:
- Complete app with all features wired together
- project.yml for XcodeGen
- Fastfile for build/upload

# M002 Context — MVP Build

## Goal
Build AquaFaste v1.0 — a clean, ad-free hydration tracker iOS app ready for App Store submission.

## Scope
- Core water logging with one-tap quick-add
- Personalized daily goal (weight/activity based)
- Visual progress (circular ring + wave animation)
- 10+ beverage types with hydration ratios
- Custom cup sizes
- Smart reminders (respect sleep, stop at goal)
- Streak tracking with celebrations
- HealthKit integration (dietaryWater write + bodyMass read)
- Onboarding flow (weight → goal → reminders)
- StoreKit 2 subscription ($3.99/mo, $19.99/yr, $39.99 lifetime, 7-day trial)
- Dark mode, units toggle (ml/oz)
- Lumifaste cross-promotion
- Daily + weekly history

## NOT in Scope (v1.1+)
- Apple Watch app
- Widgets (home/lock screen)
- Siri Shortcuts
- Collectible characters / gamification
- Social features
- Monthly/yearly trends

## Constraints
- iOS 17+ (SwiftData requirement)
- SwiftUI + SwiftData + StoreKit 2 (no third-party deps)
- Bundle ID: com.theknack.aquafaste
- Team ID: 99H9NJ6Z6J
- XcodeGen for project generation
- Same provisioning/signing setup as Lumifaste
- No ads, no tracking SDKs

## Key Decisions from Research
- Pricing: $3.99/mo, $19.99/yr, $39.99 lifetime (Waterllama-inspired)
- Color: Cyan/blue gradient (complementary to Lumifaste's purple)
- Primary SF Symbol: drop.fill
- Font: SF Rounded (matching Lumifaste)
- Free tier: full tracking, 10 drinks, basic reminders, HealthKit
- Premium: custom drinks, smart reminders, themes, unlimited cups, history export

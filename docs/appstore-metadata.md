# AquaFaste — App Store Metadata (v2.0)

> **Bundle ID:** `com.theknack.aquafaste`
> **Category:** Health & Fitness
> **Age Rating:** 4+
> **Version:** 2.0.0
> **iOS Minimum:** 17.0
> **Language:** English only

---

## Title & Subtitle

| Field    | Text                              | Chars |
|----------|-----------------------------------|-------|
| Title    | AquaFaste: Water Tracker          | 24/30 |
| Subtitle | Hydration Reminder & No Ads       | 27/30 |

## Keywords (100 chars)

```
water tracker,hydration,drink reminder,health,daily goal,caffeine,streak,HealthKit,wellness,no ads
```
**(98 chars)**

## Promotional Text (170 chars)

```
Track your hydration with science. 12 drink types, caffeine tracking, smart reminders, streaks & achievements. No ads, ever. Syncs with Apple Health.
```
**(149 chars)**

## Description

See `fastlane/metadata/en-US/description.txt`

Key points:
- Opens with "No ads" differentiation
- EFSA-aligned formula mentioned
- All 12 drink types listed
- Features organized with headers
- Pricing clearly stated
- **Terms of Use + Privacy Policy links at bottom** (Apple requirement)

## What's New (v2.0.0)

See `fastlane/metadata/en-US/release_notes.txt`

## Pricing

| Plan | Price | Trial |
|------|-------|-------|
| Monthly | $1.99/mo | 7-day free |
| Yearly | $9.99/yr | 7-day free |
| Lifetime | $19.99 | — |

## Screenshots (6)

| # | Screen | Headline | File |
|---|--------|----------|------|
| 1 | Hydrate (hero) | Track Every Sip | 01_hydrate.png |
| 2 | Progress | No Ads. Ever. | 02_progress.png |
| 3 | History | Your History | 03_history.png |
| 4 | Stats | Know Your Patterns | 04_stats.png |
| 5 | Trophies | Earn Achievements | 05_trophies.png |
| 6 | Settings | Make It Yours | 06_settings.png |

All screenshots: 1290×2796 PNG RGB (no alpha)

## App Icon

3 variants in `Sources/Resources/Assets.xcassets/AppIcon.appiconset/`:
- `icon_1024.png` — Light (any appearance)
- `icon_dark_1024.png` — Dark appearance
- `icon_tinted_1024.png` — Tinted appearance

All 1024×1024 RGB PNG, generated with Gemini 2.5 Flash Image.

## URLs

| Field | URL |
|-------|-----|
| Support | https://theknack2020-sketch.github.io/aquafaste/support |
| Marketing | https://theknack2020-sketch.github.io/aquafaste/ |
| Privacy | https://theknack2020-sketch.github.io/aquafaste/privacy |
| Terms | https://theknack2020-sketch.github.io/aquafaste/terms |

## Copyright

`© 2026 TheKnack`

## Review Notes

```
AquaFaste is a hydration tracking app. On first launch, onboarding asks for weight and activity level to calculate a personalized daily water goal using the EFSA-aligned formula (30 ml/kg × activity multiplier). The app requests HealthKit permission to sync water intake data and read body weight. Notification permission is requested for hydration reminders. All features work without any external account or server connection. Data is stored locally using SwiftData.

To test premium features, use the StoreKit configuration file (Products.storekit) included in the project.
```

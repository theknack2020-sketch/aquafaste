# AquaFaste MVP Scope: v1.0 vs v1.1+

**Date:** 2026-03-22  
**Purpose:** Define what ships in v1.0 (App Store approval + first-week ratings), what waits for v1.1+, and why.  
**Inputs:** competitor-analysis.md, feature-priority.md, pain-points.md, monetization.md, launch-strategy.md, top-competitor-teardown.md, REQUIREMENTS.md

---

## Executive Summary

v1.0 must do one thing exceptionally well: **let users log water in one tap, see their progress, and get reminded when they forget**. Every top hydration app (Waterllama 4.9★/147K ratings, WaterMinder 4.7★/10M+ downloads) proves that core tracking done with polish and reliability is what earns ratings. Features like Apple Watch, widgets, and social are what *retain* users over months — but they don't drive initial ratings and they substantially increase development time and bug surface.

The strategic bet: ship a tight, reliable, beautifully designed v1.0 that nails the basics competitors get wrong (ads, paywalls, broken sync, unreliable reminders), then layer on retention features in rapid v1.1–v1.3 updates. Waterllama itself launched without most of its current 100+ characters and 9 challenges — it earned 4.9★ on core tracking quality, then scaled engagement features over time.

---

## App Store Approval: Minimum Requirements

Apple doesn't publish a checklist, but rejection patterns from hydration/health apps reveal these hard requirements:

| Requirement | Notes |
|---|---|
| **Functional core loop** | Must actually track water — no placeholder screens, no "coming soon" features |
| **Privacy nutrition label** | Accurate App Privacy declaration in ASC. AquaFaste collects minimal data (HealthKit, no analytics SDK) — this is a strength |
| **Privacy policy URL** | Must be accessible. Host on theknack domain or GitHub Pages |
| **Support URL** | Must be accessible |
| **HealthKit justification** | If requesting HealthKit entitlements, the purpose string must be specific and the feature must be visibly used. "Write dietaryWater" needs clear user-facing integration |
| **No broken links/features** | Every button must do something. No dead-end screens |
| **Subscription disclosure** | If IAP is present: subscription terms on paywall, auto-renewal info, manage/cancel instructions, restore purchases button |
| **Age-appropriate content** | Health category — rate 4+ (no mature content) |
| **Minimum 1 screenshot per device class** | iPhone 6.7", iPhone 6.5", iPad 13" (required even for iPhone-only apps — learned from Lumifaste M003) |

None of these require Watch, widgets, or social features.

---

## v1.0 MVP — What Ships

### Tier 0: Core Loop (the thing users actually rate)

These features determine whether users give 4–5★ or 1–2★ in the first week. Every competitor that gets 4.5+★ nails these. Every competitor below 4.0★ breaks at least one.

| Feature | Req | Why It's v1.0 | Evidence |
|---|---|---|---|
| **One-tap water logging** | R001 | This IS the app. If logging water takes >2 seconds, users leave. | Waterllama's entire UX revolves around quick-add. WaterMinder's 4.7★ built on fast logging. |
| **Daily goal based on weight/activity** | R002 | Users expect personalized goals, not a hardcoded "8 glasses." Without this, 1★ reviews saying "how much should I drink?" | Every competitor above 4.0★ has personalized goals. Water Reminder's imprecise weight input (3-lb increments only) generated significant complaints. |
| **Visual progress indicator** | R003 | The emotional feedback loop. Users need to *see* progress to feel rewarded. A circular ring or wave animation filling up. | Waterllama's character-filling animation is their signature. WaterMinder's progress ring is the first thing users see. Plant Nanny's entire premise is visual progress. |
| **Hydration history (daily/weekly)** | R004 | Users need to see patterns. "Did I drink enough this week?" SwiftData persistence, simple calendar/chart view. | Universal across all competitors. Monthly view can wait for v1.1 — daily and weekly cover the first-week experience. |
| **Smart reminders** | R005 | The #4 pain point across competitors. Broken/annoying notifications are a top reason for 1★ reviews. Must respect sleep, stop when goal met, be gentle in tone. | WaterMinder: "static reminders don't fire." Water Reminder: "every notification fires 5 times." Aqualert: "too frequent to be helpful." Waterllama praised for "gentle" reminders — copy this approach. |
| **Multiple drink types** | R009 | "Track only water" is a dealbreaker. Coffee, tea, juice with hydration ratios. 8–12 beverages in free tier (competitors lock this behind paywall — major complaint). | Feature-priority research: multi-beverage is the #2 conversion trigger. VGFIT locking basic drinks behind paywall = angry reviews. Waterllama's 40+ beverages with ratios is the gold standard. |
| **Onboarding flow** | R010 | First 30 seconds determine if user keeps the app. Collect weight, set goal, set reminders, show the value. | Launch strategy: 80% of trial starts are Day 1. Onboarding is where conversion happens. Also collects the data needed for personalized goals (R002). |

### Tier 1: Trust & Ecosystem (what prevents 1★ reviews)

| Feature | Req | Why It's v1.0 | Evidence |
|---|---|---|---|
| **HealthKit integration** | R008 | Users expect water data in Apple Health. More importantly: if HealthKit sync is broken, users leave 1★ reviews mentioning it by name. Must write dietaryWater correctly. | WaterMinder's broken Watch→Health sync is a top complaint. Water Reminder overwrote user weight causing cascading errors across ALL health apps. Get this right or don't ship it. |
| **No ads — ever** | R006 | AquaFaste's #1 differentiator. Competitor pain point #1 (WaterMinder: "overtaken by ads", Plant Nanny: "too many ads/prompts to pay", Aqualert: "very annoying"). This is a launch-day ASO selling point. | pain-points.md: ads are the most common complaint across all 5 analyzed competitors. The no-ad stance is worth mentioning in the App Store subtitle. |
| **IAP subscription (premium)** | R007 | Revenue model must be in v1.0. The paywall drives conversion from onboarding. StoreKit 2 native, 7-day trial on annual plan. Generous free tier — premium gates delight, not utility. | monetization.md: $19.99/yr target. Waterllama's fair pricing earns praise. Plant Nanny's aggressive paywall earns complaints. The free tier must be genuinely useful. |
| **Privacy policy + support pages** | R012 | Hard App Store requirement. Host on theknack domain. | App Store rejection without these. |
| **Cross-promotion with Lumifaste** | R011 | The single biggest competitive advantage over a cold launch. Settings row + contextual banner. Reverse promo in AquaFaste → Lumifaste. | launch-strategy.md: Lumifaste's installed base is AquaFaste's Day 1 acquisition channel. SKOverlay for non-intrusive cross-promo. |

### Tier 2: First-Week Rating Drivers (what earns 5★ reviews)

These aren't table-stakes — they're the features that make users *want* to rate. The difference between "fine, it works" (no rating) and "this is great" (5★ review + recommendation).

| Feature | Why It Drives Ratings | Implementation in v1.0 |
|---|---|---|
| **Streak tracking with visual celebration** | Users who hit a 7-day streak are 2.3x more likely to engage daily. Streak milestones (3, 7, 14, 30 days) trigger positive emotions → review prompt timing. | Simple streak counter, streak calendar view, confetti/haptic on milestones. Review prompt after 3rd daily goal completion (launch-strategy.md). |
| **Delightful animations** | Waterllama won an Apple Design Award on animation quality. Users explicitly mention animations in 5★ reviews. The progress fill, the goal completion, the quick-add tap — all feel good. | Wave fill animation on progress view. Haptic feedback on log. Goal-complete celebration (confetti + sound). This is where SwiftUI shines. |
| **Custom cup sizes** | "Way too difficult to get a precise measurement" (Water Reminder). Users drink from specific containers — let them define their bottle (750ml), their mug (350ml), etc. | 3–4 presets + custom size creation. Show cup icons on quick-add. Premium: more icon options. |
| **Dark mode** | iOS users expect it. Missing dark mode = 1★ reviews. | System-respecting dark mode from day one. SwiftUI makes this near-free. |
| **Units toggle (ml/oz)** | Universal table-stakes. Missing = angry international users or angry American users. | Settings toggle, persist preference, show everywhere. |

---

## v1.0 Premium Gates (what converts free → paid)

The free tier must be genuinely useful. Premium gates *delight*, not *utility*.

| Free | Premium |
|---|---|
| Full water tracking, quick-add | — |
| 8–12 beverage types with hydration ratios | 25+ beverages + custom drink creation |
| Basic streak tracking | Streak freeze/recovery, streak milestones |
| 1 app theme (light/dark) | 5+ themes, custom accent colors |
| Basic reminders (fixed interval) | Smart reminders (adaptive, fasting-aware) |
| Daily + weekly history | Monthly history, trends, export (CSV) |
| 1 home screen widget (v1.1) | Multiple widget styles (v1.1) |
| Apple Health sync | — (free) |
| 3 cup size presets + 1 custom | Unlimited custom cups with icons |

**Conversion triggers (from competitor data):**
1. Custom beverages (user tries to add their specific smoothie → paywall)  
2. Smart reminders (user sees "adaptive reminders" in settings → paywall)
3. Themes/customization (user taps theme picker → paywall)
4. History editing (user logs wrong amount, tries to edit → paywall — but make this less aggressive than WaterMinder)

---

## v1.1 — First Post-Launch Update (Target: 2–4 weeks after v1.0)

These features are high-value but have significant implementation complexity. Shipping them broken is worse than not shipping them. Each one has been a source of 1★ reviews when done poorly by competitors.

| Feature | Req | Why v1.1, Not v1.0 | Complexity | Rating Impact |
|---|---|---|---|---|
| **Home screen + Lock screen widgets** | R014 | WidgetKit requires a separate extension target, WidgetKit timeline management, and thorough testing across device sizes. Widgets that show stale data or fail to update are worse than no widgets. WaterMinder's widgets required multiple iterations to stabilize. | Medium-High | High — widgets keep the app visible all day. Passive engagement prevents "download, use 3 days, forget." |
| **Apple Watch app** | R013 | watchOS requires a separate target, WatchConnectivity framework, independent SwiftData store with sync, complications, and standalone operation. WaterMinder's Watch app is the #1 complaint category — "Watch App Rarely Works", 30-second refresh, sync failures. Better to ship late and reliable than early and broken. | High | Very High — the #1 feature request and #1 complaint category. But also the #1 source of 1★ reviews when broken. |
| **Siri Shortcuts / App Intents** | R015 | App Intents framework, SiriKit integration, parameter resolution. Low complexity individually but adds testing surface. | Low-Medium | Low-Medium — nice-to-have, not a review driver. |
| **Interactive widgets** | — | iOS 17 interactive widgets (tap to log from widget) are a strong feature but require additional WidgetKit work on top of basic widgets. Ship basic widgets first, upgrade to interactive in v1.1 or v1.2. | Medium | Medium — delightful when it works. |
| **Monthly history + trends** | — | Weekly history covers the first-week experience. Monthly/yearly trends require more data (user won't have a month of data in week 1 anyway). Ship the analytics when users actually have data to analyze. | Low | Low in week 1 (no data yet). High by month 2. |

### v1.1 as the "Apple Feature" Update

Apple editorial loves apps that adopt new platform features. v1.1 can be positioned as the "full platform integration" update:
- Widgets (home + lock screen)
- Apple Watch standalone app  
- Siri Shortcuts / App Intents
- Interactive widgets

Submit a Featuring Nomination with v1.1 highlighting platform adoption. This is a proven path to "App of the Day" — Waterllama's Apple Watch + widget update drove their 2022 App Store Award.

---

## v1.2+ — Retention & Growth Features (Month 2–3)

These features drive long-term retention and LTV but are not essential for launch or first-month ratings.

| Feature | Why It Can Wait | Target Version |
|---|---|---|
| **Collectible characters / gamification** | The #1 revenue driver in the category (Waterllama 100+ characters, Plant Nanny 50+ plants). But designing, illustrating, and animating 20+ characters is a major art/design effort. Better to launch with a clean utility-first design and layer gamification on top once the core is proven. | v1.2–v1.3 |
| **Themed challenges** | "Caffeine Detox Week", "Hydration Marathon", etc. Waterllama has 9 challenges. Requires content design, progress tracking, reward system. Important for retention but not for first impressions. | v1.2 |
| **Social / Friends** | Lightweight accountability (see friends' streaks, gentle nudges). P Water App and WaterMinder have this. No hydration app has cracked social well yet — Strava-style lightweight social is the model. | v1.3+ |
| **Weather-adjusted goals** | Hydro Coach's differentiator. Requires WeatherKit or CoreLocation + weather API. Good feature but adds complexity and a data dependency. | v1.2 |
| **AI-powered insights** | "Your hydration drops on Wednesdays" — pattern analysis from historical data. No competitor does this well yet. Requires accumulated data (won't be useful in month 1). Apple Foundation Models integration could differentiate. | v1.3+ |
| **Data export (CSV/JSON)** | Valued by quantified-self users and medical use cases. Small user segment but high willingness to pay. | v1.2 |
| **Fasting timer integration** | Deeper than cross-promotion — actual fasting schedule awareness in hydration reminders. "You're 14 hours into your fast — stay hydrated." This is AquaFaste's unique angle but requires defining the fasting data model and either HealthKit fasting data or a built-in timer. | v1.2 |
| **Family/group tracking** | Underexplored in the category. Parents tracking kids' hydration. | v2.0+ |
| **Health condition modes** | Kidney stone prevention, pregnancy hydration, GLP-1 support. P Water charges 5x more for medical features. | v2.0+ |
| **Smart bottle integration** | HidrateSpark API. Hardware dependency, niche audience. | v2.0+ |
| **Fitbit/Garmin integration** | No iOS hydration app does this well. First-mover advantage but small audience on iOS. | v2.0+ |

---

## Cross-Promotion Strategy: v1.0 Scope

The Lumifaste relationship is AquaFaste's unfair advantage. In v1.0:

| Placement | AquaFaste | Lumifaste |
|---|---|---|
| **Settings row** | "Try Lumifaste — Fasting Tracker" with app icon | "Try AquaFaste — Water Tracker" with app icon |
| **Contextual banner** | — | "Track hydration during fasts → AquaFaste" (after completing a fast) |
| **Technical** | SKOverlay for Lumifaste product page | SKOverlay for AquaFaste product page |
| **Shared branding** | Same color palette, typography, icon style. "Faste" family identity. | — |
| **HealthKit glue** | Both apps read/write to HealthKit. Users with both get richer health data without custom sync. | — |

Deeper integration (shared subscription bundle, unified dashboard, fasting-aware hydration reminders) is v1.2+ territory.

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| **"Too simple" perception** | Medium | Medium | Invest in animation quality and visual polish. Waterllama proves that simple + delightful = 4.9★. The alternative — shipping too many half-baked features — is worse. |
| **"Missing Watch app" in reviews** | Medium | Low-Medium | Mention "Apple Watch coming in v1.1" in release notes. Users tolerate missing features better than broken ones. Ship Watch fast (2–4 weeks post-launch). |
| **HealthKit sync bugs** | Medium | High | Test exhaustively: fresh install, upgrade, device restore, iCloud sync, multiple HealthKit sources. This is the #1 trust-breaker in competitor reviews. |
| **Paywall backlash** | Low-Medium | Medium | Free tier is genuinely useful (all core tracking, 8–12 beverages, basic reminders, HealthKit). Premium gates delight, not utility. Learn from Plant Nanny's mistakes. |
| **Low Day 1 downloads** | Medium | High | Lumifaste cross-promo is the hedge. Pre-order, TestFlight beta → launch day push, Product Hunt, social media. See launch-strategy.md. |
| **Competitor response** | Low | Low | Waterllama/WaterMinder are established — they won't pivot to fasting. AquaFaste's fasting angle is defensible. |

---

## v1.0 Feature Summary (Final Checklist)

### Ships ✅
- [ ] One-tap water logging with haptic feedback
- [ ] Personalized daily goal (weight, activity level, gender)
- [ ] Circular/wave progress visualization with fill animation
- [ ] 8–12 beverage types with hydration ratios (water, coffee, tea, juice, milk, soda, smoothie, sparkling water, coconut water, beer, wine, soup)
- [ ] Custom cup sizes (3 presets + 1 custom free, unlimited custom premium)
- [ ] Daily + weekly hydration history
- [ ] Smart reminders (respect sleep, stop at goal, gentle tone)
- [ ] Streak tracking with milestone celebrations (3, 7, 14, 30 days)
- [ ] HealthKit write (dietaryWater) + read (bodyMass for goal calc)
- [ ] Onboarding flow (weight → goal → reminders → first log)
- [ ] StoreKit 2 subscription ($19.99/yr, $3.99/mo, $39.99 lifetime)
- [ ] Paywall with 7-day free trial
- [ ] Restore purchases
- [ ] Lumifaste cross-promotion (Settings row + SKOverlay)
- [ ] Dark mode (system-respecting)
- [ ] Units toggle (ml / fl oz)
- [ ] Privacy policy + support page URLs
- [ ] iPad support (adaptive layout)
- [ ] App Store screenshots (iPhone 6.7", 6.5", iPad 13")
- [ ] Goal-complete celebration animation
- [ ] No ads, no tracking SDKs

### Doesn't Ship ❌ (with timeline)
- [ ] Apple Watch app → **v1.1** (2–4 weeks post-launch)
- [ ] Home screen + lock screen widgets → **v1.1**
- [ ] Interactive widgets → **v1.1**
- [ ] Siri Shortcuts / App Intents → **v1.1**
- [ ] Monthly/yearly history + trends → **v1.1**
- [ ] Collectible characters / gamification → **v1.2** (month 2)
- [ ] Themed challenges → **v1.2**
- [ ] Weather-adjusted goals → **v1.2**
- [ ] Data export (CSV) → **v1.2**
- [ ] Fasting timer integration → **v1.2**
- [ ] Social / friends → **v1.3+** (month 3+)
- [ ] AI-powered insights → **v1.3+**
- [ ] Family/group tracking → **v2.0+**
- [ ] Health condition modes → **v2.0+**
- [ ] Smart bottle integration → **v2.0+**

---

## Decision Rationale: Why No Watch/Widgets in v1.0

The feature-priority research recommends Apple Watch and widgets as P0 (must-have at launch). This MVP scope deliberately overrides that recommendation. Here's why:

1. **The research measures revenue potential, not launch risk.** Watch and widgets drive retention and revenue over months. But they also represent the #1 source of 1★ reviews when broken (WaterMinder Watch complaints dominate their negative reviews). A broken Watch app on Day 1 tanks your rating permanently.

2. **Waterllama didn't launch with 100+ characters.** It earned 4.9★ on core tracking quality first. The characters, challenges, and platform integrations came as the team grew confidence in their foundation.

3. **Lumifaste's experience confirms this.** The Lumifaste launch (same developer, same stack) showed that a tight core + fast iteration beats a wide but buggy v1.0. K004 and K005 from KNOWLEDGE.md prove that build/deploy complexity is non-trivial.

4. **v1.1 ships 2–4 weeks later.** The gap between "no Watch app" and "Watch app" is less than a month. Users who download in week 1 will have Watch support by week 3–4. The ASO copy can say "Apple Watch support coming soon."

5. **Review timing matters.** The review prompt fires after the 3rd daily goal hit (launch-strategy.md). By the time most users see a review prompt (day 3–7), their experience is with the core loop — not Watch or widgets. If the core loop is 5★ quality, the rating reflects that.

The one exception where this bet fails: if Apple editorial considers the app for featuring and prefers apps with Watch/widget support. This is mitigated by submitting the Featuring Nomination with v1.1 (the platform integration update), not v1.0.

---

## Sources

All findings synthesized from existing AquaFaste research:
1. `competitor-analysis.md` — 20-app competitive landscape
2. `feature-priority.md` — revenue-driving feature analysis, Waterllama $90K/mo data
3. `pain-points.md` — 5-app negative review analysis (ads, paywalls, broken Watch, sync issues)
4. `monetization.md` — pricing benchmarks, RevenueCat conversion data, premium feature patterns
5. `launch-strategy.md` — TestFlight, pre-order, Day 1 velocity, review solicitation, influencer outreach
6. `top-competitor-teardown.md` — Plant Nanny + Waterllama deep analysis
7. `REQUIREMENTS.md` — R001–R015 current requirement set
8. `DECISIONS.md` — D001–D005 architectural decisions
9. `KNOWLEDGE.md` — K004, K005 Lumifaste build/deploy lessons

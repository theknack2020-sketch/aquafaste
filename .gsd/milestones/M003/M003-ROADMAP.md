# M003: AquaFaste v2.0 — Ultra Premium Redesign

**Vision:** Transform AquaFaste from a basic 40/100 MVP into a world-class 85+ hydration app that competes head-to-head with Waterllama and WaterMinder.

## Success Criteria

- App builds with ZERO errors and ZERO warnings
- Haptic calls ≥ 30 in Views/
- Accessibility labels ≥ 50
- Gradients ≥ 15
- Spring/bouncy animations ≥ 20
- isPro gates ≥ 15 (matching paywall comparison table)
- Swift Charts ≥ 5 distinct chart types
- Sound effects ≥ 5 distinct actions
- Error handling in every SwiftData save/delete
- 6 themes (4 free + 2 premium) working in dark mode
- Streak + achievement + milestone + notification ≥ 200 references
- 8-Question Quality Gate all pass
- iPad layout verified, dark mode verified on all screens
- AI app icon (3 variants: light, dark, tinted)

## Key Risks

| Risk | Why It Matters |
|------|---------------|
| Massive code changes across 25+ files | Build failures block everything |
| Pro gate enforcement could break free tier | Users need usable free tier |
| Previous App Store rejection | Must fix rejection cause before resubmit |
| Waterllama has Liquid Glass + 100 characters | Must differentiate on science/data depth |

## Slices

### Wave 1 — Foundation + Features
- [ ] **S01: Core UX + Premium UI Redesign** `risk:high` `depends:[]`
- [ ] **S02: Animation + Haptic + Sound System** `risk:high` `depends:[S01]`
- [ ] **S03: Paywall + Pro Gates + Pricing Redesign** `risk:high` `depends:[S01]`
- [ ] **S04: Charts + Statistics + Insights Engine** `risk:medium` `depends:[S01]`
- [ ] **S05: Retention + Streaks + Achievements + Notifications** `risk:medium` `depends:[S01,S02]`

### Wave 2 — Polish + Integration
- [ ] **S06: Visual Polish + Themes + Accessibility** `risk:medium` `depends:[S01-S05]`
- [ ] **S07: Error Handling + Empty States + UX Copy** `risk:low` `depends:[S01,S04,S05]`
- [ ] **S08: Integration + Build + TelemetryDeck + Final Test** `risk:high` `depends:[S06,S07]`

### Post-Build
- [ ] **S09: AI App Icon + Screenshots + ASO + Submit Prep** `risk:medium` `depends:[S08]`

## Pricing Decision (v2.0)

| Plan | Old Price | New Price | Rationale |
|------|-----------|-----------|-----------|
| Monthly | $3.99 | $1.99 | Waterllama = $0.99/mo. Undercut WaterMinder ($2.99) |
| Yearly | $19.99 | $9.99 | Waterllama = $6.99-9.99/yr. Competitive sweet spot |
| Lifetime | $39.99 | $19.99 | Waterllama = $8.99-24.99. Fair lifetime value |
| Trial | 7-day | 7-day | Standard trial, cancel anytime |

## Verification

- **Contract:** xcodebuild 0 errors, rg metric counts meet minimums
- **Integration:** Simulator screenshots, dark mode, iPad, HealthKit
- **Operational:** TelemetryDeck, crash monitoring, pre-commit hooks
- **UAT:** 8-Question Quality Gate, UI Flow Test all screens

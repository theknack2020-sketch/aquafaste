# Decisions

| ID | Scope | Decision | Choice | Rationale |
|----|-------|----------|--------|-----------|
| D001 | architecture | App name | AquaFaste | Sister app to Lumifaste, "Faste" brand family, unique on App Store |
| D002 | architecture | No ads policy | Never — subscription only | Core differentiator, same as Lumifaste. Competitor pain point #1 |
| D003 | architecture | Tech stack | SwiftUI + SwiftData + StoreKit 2 native | Same stack as Lumifaste, proven, no dependencies |
| D004 | architecture | Minimum iOS version | iOS 17+ | SwiftData requires iOS 17, same as Lumifaste |
| D005 | architecture | Bundle ID | com.theknack.aquafaste | Consistent with com.theknack.lumifaste |

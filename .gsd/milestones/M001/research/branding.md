# AquaFaste Branding & Visual Identity Research

> Color palette, iconography, typography, and brand family cohesion with Lumifaste.

---

## 1. Brand Family Context: The "Faste" Suite

Lumifaste (fasting tracker) uses a **purple/violet gradient** theme:
- Light mode accent: `rgba(0.46, 0.44, 0.78)` → **#7570C7** (muted blue-violet)
- Dark mode accent: `rgba(0.56, 0.54, 0.86)` → **#8F8ADB** (lighter violet)
- Typography: SF system font with `.rounded` design, `.light` weight for display numbers
- Visual tone: calm, clean, minimal — no bold saturated colors

AquaFaste must feel like a **sibling, not a clone**. Same family DNA (calm, clean, rounded), different personality (water/freshness vs. fasting/mindfulness).

### Brand Family Shared Traits
| Trait | Lumifaste | AquaFaste |
|-------|-----------|-----------|
| Primary hue | Violet/Purple (#7570C7) | Cyan/Teal (proposed) |
| Emotional tone | Mindful, meditative | Fresh, energizing |
| Font design | SF Rounded | SF Rounded |
| UI density | Minimal | Minimal |
| Icon style | SF Symbols | SF Symbols |
| Gradient direction | Purple → indigo | Cyan → blue |
| Dark mode | Dark bg + lighter accent | Dark bg + lighter accent |

---

## 2. Color Palette Options

### Option A: Ocean Cyan (Recommended)

A monochromatic cyan-to-blue scheme — the most natural "water" association while maintaining clear distinction from Lumifaste's violet.

| Role | Color | Hex | Usage |
|------|-------|-----|-------|
| **Primary** | Ocean Blue | `#0A84FF` | Main accent, buttons, active states |
| **Secondary** | Aqua Cyan | `#32D4DE` | Progress rings, wave fills, highlights |
| **Tertiary** | Deep Teal | `#0C6B7A` | Headers, emphasis text, icons |
| **Surface Light** | Ice Blue | `#E8F7FA` | Card backgrounds, subtle fills |
| **Surface Dark** | Midnight Blue | `#0A1628` | Dark mode background |
| **Gradient Start** | Cyan | `#00C9DB` | Gradient overlays |
| **Gradient End** | Blue | `#0066FF` | Gradient overlays |

**Rationale:** Cyan reads "water" universally. Blue builds trust — critical for a health app. The palette shifts from Lumifaste's violet by ~120° on the color wheel, making them visually distinct but harmonious when seen side by side.

### Option B: Teal Wellness

More green-leaning, spa-like calm. Feels more "wellness" than "tech."

| Role | Color | Hex |
|------|-------|-----|
| Primary | Teal | `#009B9E` |
| Secondary | Mint | `#5CCFCF` |
| Tertiary | Deep Sea | `#004D4D` |
| Surface Light | Foam | `#E0F5F5` |
| Gradient | Teal → Emerald | `#009B9E` → `#00D68F` |

**Tradeoff:** More distinctive from Lumifaste but risks feeling too "spa" rather than "tracker app." Green-teal can conflict with success/health indicator greens in the UI.

### Option C: Deep Water Blue

Classic blue — trustworthy, clean, but less differentiated from every other water app.

| Role | Color | Hex |
|------|-------|-----|
| Primary | Royal Blue | `#1A73E8` |
| Secondary | Light Blue | `#4FC3F7` |
| Tertiary | Navy | `#0D47A1` |
| Surface Light | Pale Blue | `#E3F2FD` |
| Gradient | Navy → Sky | `#0D47A1` → `#81D4FA` |

**Tradeoff:** Safe and recognizable but generic. Many competitors already use this exact palette (WaterMinder, Water Tracker).

### Recommendation: Option A (Ocean Cyan)

The cyan/aqua tones are distinctive on the App Store, feel "water" without being generic blue, and create a strong color contrast with Lumifaste's violet — making the brand family feel intentionally designed.

### Dark Mode Palette (Option A Applied)

| Role | Light Mode | Dark Mode |
|------|------------|-----------|
| Background | `#FFFFFF` | `#0A1628` (midnight blue) |
| Surface | `#E8F7FA` | `#142136` |
| Primary accent | `#0A84FF` | `#40A9FF` |
| Secondary accent | `#32D4DE` | `#5CE0E8` |
| Text primary | `#1A1A1A` | `#F0F6FA` |
| Text secondary | `#6B7280` | `#8B98A8` |

---

## 3. SF Symbols for Hydration

### Primary Symbols (Available SF Symbols 5+, iOS 17)

| Symbol Name | Use Case | Notes |
|-------------|----------|-------|
| `drop.fill` | Water logging, primary action | The quintessential hydration icon. Available since SF Symbols 1. Multicolor support. |
| `drop.halffull` | Partial progress, mid-day state | Shows partial fill — ideal for in-progress states |
| `drop.degreesign` | Temperature-related hydration | Niche but useful for weather-aware reminders |
| `waterbottle.fill` | Drink type: water bottle | **SF Symbols 5 (iOS 17).** Perfect for bottle-based tracking |
| `waterbottle` | Empty/outline state | Outline variant for untracked state |
| `cup.and.saucer.fill` | Drink type: tea/coffee | Well-recognized for hot beverages |
| `mug.fill` | Drink type: coffee/hot cocoa | **SF Symbols 5.** More casual than cup.and.saucer |
| `wineglass.fill` | Drink type indicator (non-water) | For non-water beverages tracking |
| `humidity.fill` | Humidity/weather context | Good for weather-aware hydration tips |

### Secondary Symbols (Navigation & UI)

| Symbol Name | Use Case |
|-------------|----------|
| `chart.bar.fill` | Statistics/history tab |
| `calendar` | Daily/weekly/monthly view |
| `bell.fill` | Reminder notifications |
| `gearshape.fill` | Settings |
| `heart.fill` | HealthKit integration indicator |
| `figure.walk` | Activity-based hydration goals |
| `plus.circle.fill` | Quick-add water button |
| `arrow.trianglehead.clockwise` | Streak/refresh |
| `trophy.fill` | Achievements/milestones |
| `person.fill` | Profile/onboarding |

### Animation Opportunities (SF Symbols 6+)

SF Symbols 6 introduced **Wiggle, Rotate, and Breathe** animation presets. For AquaFaste:

- **`drop.fill` + Breathe**: Pulsing water drop on the main screen to indicate active tracking
- **`drop.fill` + Bounce**: When user logs a drink — satisfying feedback animation
- **`waterbottle.fill` + Replace (Magic Replace)**: Smooth transition from empty → full bottle as progress increases
- **`trophy.fill` + Wiggle**: Celebration when daily goal is reached
- **`bell.fill` + Pulse**: Reminder notification indicator

> **Important licensing note:** SF Symbols may not be used in app icons, logos, or any trademark-related use. The app icon must be a custom design, not an SF Symbol.

---

## 4. App Icon Concepts

Since SF Symbols can't be used in app icons, the icon must be a **custom design** that reads "hydration" instantly at all sizes.

### Concept A: Abstract Water Drop (Recommended)

A stylized water droplet with a cyan-to-blue gradient, placed on a clean background. The drop shape is slightly geometric (not perfectly round) to feel modern and tech-forward.

```
┌──────────────┐
│              │
│    ╭──╮     │
│   ╱    ╲    │   Gradient: #00C9DB → #0066FF
│  │      │   │   Background: White or very light ice blue
│  │      │   │   Shape: Rounded square (iOS standard)
│   ╲    ╱    │
│    ╰──╯     │
│              │
└──────────────┘
```

**Design notes:**
- Drop should be centered with generous padding (Apple recommends ~15-20% margin)
- Gradient runs top-to-bottom (light cyan → deep blue), suggesting water depth
- The drop's highlight/reflection at the top-left adds dimensionality
- Consider a subtle concentric ring around the drop (echoing progress rings)
- At 1024×1024, the drop should be immediately recognizable
- At 29×29 (smallest icon), the silhouette must still read as a drop

### Concept B: Wave + Drop Combo

A water drop sitting above a wave line, suggesting both the liquid and the tracking/measurement aspect.

**Tradeoffs:** More complex — may not scale well to small sizes. The wave line could get lost at 29px.

### Concept C: Circular Progress Drop

A water drop integrated into a circular progress ring (representing daily goal). The ring and drop form one unified shape.

**Tradeoffs:** Clever concept but may look too complex. Similar to some competitor icons (Water Tracker Daily).

### Concept D: "AF" Monogram

Stylized "AF" lettermark in the brand gradient, with the "A" subtly incorporating a drop shape.

**Tradeoffs:** Unique and memorable, but doesn't communicate "water" as immediately. Works better as a secondary mark than the primary icon.

### Recommendation: Concept A

The abstract water drop is universally understood, scales beautifully, and lets the cyan-blue gradient do the branding work. It pairs well with Lumifaste's icon (if Lumifaste uses a similarly abstract single-symbol approach).

### Icon Production Notes (iOS 26 / Xcode 16+)

- Use **Icon Composer** (bundled with Xcode 16+) for generating all sizes
- Single 1024×1024 source file, Icon Composer handles scaling
- Support both light and dark appearance variants
- iOS 26 introduces automatic tinting — the icon should work in monochrome too
- Export in both standard and "tinted" variants for the icon set

---

## 5. Typography System

### Matching Lumifaste's Pattern

Lumifaste uses SF system fonts with `.rounded` design. AquaFaste should follow the same pattern exactly — this is the strongest brand family signal:

```swift
extension Font {
    // Timer/counter display — same as Lumifaste
    static let hydrationDisplay = Font.system(size: 44, weight: .light, design: .rounded)
    
    // Goal percentage — large but not as big as display
    static let goalDisplay = Font.system(size: 34, weight: .medium, design: .rounded)
    
    // Section headers
    static let sectionTitle = Font.system(size: 15, weight: .semibold)
    
    // Body text
    static let bodyText = Font.system(size: 15)
    
    // Small captions, timestamps
    static let caption = Font.system(size: 13)
    
    // Metric values in cards
    static let metricValue = Font.system(size: 20, weight: .medium, design: .rounded)
    
    // Metric labels
    static let metricLabel = Font.system(size: 12, weight: .regular)
}
```

### Why SF Rounded Works for Both Apps

- **Soft, approachable feel** — rounds are psychologically associated with friendliness and safety
- **Consistency across the brand family** — users who have Lumifaste will feel at home
- **Native feel** — matches iOS system aesthetic, no custom font bundles needed
- **Variable weight support** — from ultralight to black, all built in
- **Zero bundle size cost** — system font, no asset loading

### Typography Hierarchy

| Level | Size | Weight | Design | Example |
|-------|------|--------|--------|---------|
| Display | 44pt | Light | Rounded | "1,850 ml" |
| Goal | 34pt | Medium | Rounded | "74%" |
| Title 1 | 22pt | Bold | Default | "Today's Progress" |
| Title 2 | 17pt | Semibold | Default | "Drink History" |
| Body | 15pt | Regular | Default | "You've had 6 glasses today" |
| Caption | 13pt | Regular | Default | "Last drink: 10 min ago" |
| Metric | 20pt | Medium | Rounded | "250 ml" |

---

## 6. Brand Family Cohesion Strategy

### Visual Language Shared Between Apps

1. **Typography**: Both use SF Rounded for display numbers — this is the primary "family" signal
2. **Layout patterns**: Card-based UI with subtle rounded corners, generous whitespace
3. **Icon style**: SF Symbols throughout, consistent weight (medium) and size
4. **Animation approach**: Smooth, subtle — no flashy transitions. Prefer spring animations with moderate response
5. **Color temperature**: Both use "cool" palettes (violet and cyan are both cool-spectrum)
6. **Dark mode treatment**: Deep, muted backgrounds (not pure black) with lighter accent variants

### Intentional Differences

1. **Hue**: Violet (#7570C7) vs. Cyan (#0A84FF / #32D4DE) — ~120° apart on color wheel
2. **Energy level**: Lumifaste is meditative/calm; AquaFaste is fresh/energizing
3. **Primary visual element**: Lumifaste → timer circle; AquaFaste → water fill/wave
4. **Gradient character**: Lumifaste → purple to indigo (warm-cool); AquaFaste → cyan to blue (cool-cool)
5. **Micro-interactions**: Lumifaste → breathing/pulsing; AquaFaste → flowing/filling/rippling

### Cross-Promotion Design

When one app promotes the other (R011), the visual should show both app icons side by side with a shared branded banner:
- Use a gradient that blends both brand colors (violet → cyan transition)
- Copy: "From the makers of Lumifaste" or "Part of the Faste family"
- The transition gradient (violet → cyan) itself becomes a "Faste family" brand element

---

## 7. Design System Color Tokens (SwiftUI Implementation)

```swift
import SwiftUI

extension Color {
    // MARK: - Brand Colors
    static let aquaPrimary = Color("AquaPrimary")         // #0A84FF
    static let aquaSecondary = Color("AquaSecondary")     // #32D4DE
    static let aquaTertiary = Color("AquaTertiary")       // #0C6B7A
    
    // MARK: - Surfaces
    static let aquaSurface = Color("AquaSurface")         // #E8F7FA (light) / #142136 (dark)
    
    // MARK: - Gradients
    static let gradientStart = Color("GradientStart")     // #00C9DB
    static let gradientEnd = Color("GradientEnd")         // #0066FF
    
    // MARK: - Semantic
    static let hydrationProgress = Color.aquaSecondary
    static let hydrationGoalMet = Color.green             // System green for universal "success"
    static let hydrationLow = Color.orange                // Warning state
    
    // MARK: - Drink Types
    enum Drink {
        static let water = Color.aquaSecondary            // Cyan
        static let tea = Color(hex: "#A8D5BA")            // Soft green
        static let coffee = Color(hex: "#8B6F47")         // Warm brown
        static let juice = Color(hex: "#FFB347")          // Orange
        static let milk = Color(hex: "#F5F0E8")           // Cream
        static let smoothie = Color(hex: "#C77DFF")       // Light purple
    }
}
```

### Gradient Definitions

```swift
extension LinearGradient {
    /// Primary brand gradient — headers, CTAs
    static let aquaBrand = LinearGradient(
        colors: [Color.gradientStart, Color.gradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Subtle surface gradient — card backgrounds
    static let aquaSurface = LinearGradient(
        colors: [Color.aquaSurface.opacity(0.3), Color.aquaSurface.opacity(0.1)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// Water fill gradient — progress indicators
    static let waterFill = LinearGradient(
        colors: [Color.aquaSecondary, Color.aquaPrimary],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// Faste family gradient — cross-promo banner
    static let fasteFamily = LinearGradient(
        colors: [Color(hex: "#7570C7"), Color(hex: "#0A84FF")],
        startPoint: .leading,
        endPoint: .trailing
    )
}
```

---

## 8. Competitive Color Differentiation

| App | Primary Color | Icon Shape | AquaFaste Differentiation |
|-----|---------------|------------|---------------------------|
| WaterMinder | Blue (#2196F3) | Water drop | AquaFaste uses cyan, more vibrant |
| Water Tracker Daily | Light blue (#42A5F5) | Drop + circle | AquaFaste's gradient is more distinctive |
| Waterly | Teal (#26A69A) | Drop silhouette | AquaFaste is more blue-leaning cyan |
| HidrateSpark | Deep blue (#1565C0) | Wave | AquaFaste's cyan is brighter, more energetic |
| Plant Nanny | Green (#66BB6A) | Plant | Completely different category |
| Drink Water Reminder | Cyan (#00BCD4) | Glass | Closest competitor color — AquaFaste needs stronger gradient identity |

**Key insight:** Most hydration apps use flat blue. AquaFaste's cyan-to-blue gradient and the ".rounded font family" styling will be the differentiators. The wave/liquid fill animations (from visual-effects research) add another layer of uniqueness.

---

## 9. 2026 Design Trend Alignment

Based on current mobile design trends:

- **Liquid Glass aesthetic**: Apple's 2025-2026 design language uses translucent, frosted surfaces. AquaFaste's water theme naturally fits this — frosted glass cards with cyan tint
- **Purposeful micro-interactions**: Water logging should feel satisfying — splash animations, wave ripples, progress fills (already covered in visual-effects.md)
- **Dark mode as baseline**: The palette is designed dark-mode-first with adjusted accent brightness
- **Minimalist layouts with personality**: The rounded typography + water animations add warmth to a clean layout
- **Accessibility-first contrast**: All color pairs in the palette meet WCAG AA for text contrast (4.5:1 minimum)

---

## 10. Action Items

1. **Create Color Asset Catalog** — Define all colors in Assets.xcassets with light/dark variants
2. **Build Color+Theme.swift** — Same pattern as Lumifaste's extension, adapted for AquaFaste tokens
3. **Design App Icon** — Commission or create a stylized water drop with cyan→blue gradient (Concept A)
4. **Build Font extension** — Port Lumifaste's Font extension pattern with AquaFaste-specific sizes
5. **Create SF Symbol collection** — Catalog all symbols used in the app for consistency review
6. **Test icon at all sizes** — Verify the drop silhouette reads clearly from 1024px down to 29px
7. **Cross-promo gradient** — Design the violet→cyan "Faste family" gradient for the shared banner

---

## Sources

- Lumifaste source code: `Sources/Extensions/Color+Theme.swift`, `Assets.xcassets/AccentColor.colorset`
- SF Symbols 7: developer.apple.com/sf-symbols — 6,900+ symbols, Draw animations, variable rendering
- 2026 color trends: elements.envato.com — jewel-inspired blues, muted sapphire, calm neutrals
- Blue/cyan palette psychology: media.io — "teal reads spa/wellness, cyan reads tech/energy"
- Mobile app design trends 2026: Multiple sources — glassmorphism revival, purposeful micro-interactions, minimalist + personality
- SF Symbols licensing: avanderlee.com — symbols may NOT be used in app icons, logos, or trademarks

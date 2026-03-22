# Visual Effects & Animation Research for AquaFaste

> Water/hydration UI animation patterns in SwiftUI — wave animations, liquid fills, bubble particles, circular progress, splash effects, and haptic feedback.

---

## 1. Wave Animations Using Sine Functions

### Core Pattern: Custom Shape + AnimatableData

The standard approach is a `Wave` struct conforming to `Shape`, using `sin()` to compute y-coordinates across the path width. The key parameters are **amplitude** (wave height), **frequency** (wave count), and **phase** (horizontal offset for animation).

```swift
struct Wave: Shape {
    var strength: Double   // amplitude
    var frequency: Double  // how many waves
    var phase: Double      // animated offset

    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height / 2

        path.move(to: CGPoint(x: 0, y: midHeight))
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let sine = sin(relativeX * .pi * 2 * frequency + phase)
            let y = midHeight + sine * strength
            path.addLine(to: CGPoint(x: x, y: y))
        }

        // Close the shape below the wave
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        return path
    }
}
```

### Animating Phase

Drive the phase with `withAnimation` using `.linear` and `.repeatForever`:

```swift
@State private var phase: Double = 0

var body: some View {
    Wave(strength: 10, frequency: 8, phase: phase)
        .fill(Color.blue.opacity(0.5))
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
}
```

Using `.pi * 2` ensures a seamless loop since sin() covers its full period.

### Layered Waves for Depth

Stack 2–3 Wave shapes with different frequencies, phases, and opacities. Offset each layer's animation duration slightly (e.g., 2s, 2.5s, 3s) to create a natural, non-uniform water surface.

```swift
ZStack {
    Wave(strength: 12, frequency: 7, phase: phase)
        .fill(Color.blue.opacity(0.3))
    Wave(strength: 8, frequency: 10, phase: phase * 1.2)
        .fill(Color.cyan.opacity(0.3))
    Wave(strength: 6, frequency: 12, phase: phase * 0.8)
        .fill(Color.blue.opacity(0.2))
}
```

### Metal Shader Alternative (iOS 17+)

For GPU-accelerated waves, use Metal shaders with SwiftUI's `distortionEffect`:

```metal
[[ stitchable ]] float2 wave(float2 position, float length, float amplitude, float time) {
    return position - float2(0, sin(time + position.x / length) * amplitude);
}
```

Driven via `TimelineView(.animation)` and `.distortionEffect(ShaderLibrary.wave(...))`. Better performance for complex wave compositions but requires iOS 17+ and Metal shader files in the project.

**Recommendation for AquaFaste:** Use the pure SwiftUI Shape approach. It's compatible with iOS 16+, easier to maintain, and sufficient for a hydration UI. Reserve Metal for v2 polish.

---

## 2. Liquid Fill Effects

### Wave-Based Fill with Percentage

Combines the wave animation with a fill level controlled by a `percent` property (0.0–1.0):

```swift
struct LiquidWave: Shape {
    var offset: Angle
    var percent: Double

    var animatableData: Double {
        get { offset.degrees }
        set { offset = Angle(degrees: newValue) }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let waveHeight = 0.015 * rect.height
        let yOffset = CGFloat(1 - percent) * (rect.height - 4 * waveHeight) + 2 * waveHeight
        let startAngle = offset
        let endAngle = offset + Angle(degrees: 360)

        path.move(to: CGPoint(
            x: 0,
            y: yOffset + waveHeight * CGFloat(sin(offset.radians))
        ))

        for angle in stride(from: startAngle.degrees, through: endAngle.degrees, by: 5) {
            let x = CGFloat((angle - startAngle.degrees) / 360) * rect.width
            let y = yOffset + waveHeight * CGFloat(sin(Angle(degrees: angle).radians))
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}
```

### Circle-Clipped Liquid Fill

For a "water in a glass/circle" effect, place the wave inside a circle mask:

```swift
ZStack {
    Circle()
        .stroke(Color.blue, lineWidth: 4)

    LiquidWave(offset: Angle(degrees: waveOffset), percent: fillPercent / 100)
        .fill(LinearGradient(
            colors: [.blue.opacity(0.6), .cyan.opacity(0.4)],
            startPoint: .top,
            endPoint: .bottom
        ))
        .clipShape(Circle())
}
.onAppear {
    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
        waveOffset = 360
    }
}
```

### Animating Fill Level

When the user logs water, animate `fillPercent` with a spring animation for a satisfying rise:

```swift
withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
    fillPercent = newPercent
}
```

**Recommendation for AquaFaste:** Circle-clipped liquid fill is the hero visual for the main hydration screen. Use dual-layer waves (different opacity/frequency) inside a circle mask, animated fill level on log events.

---

## 3. Bubble Particle Systems

### Approach A: Pure SwiftUI with TimelineView + Canvas (iOS 15+)

Most efficient for custom particle rendering — `TimelineView` provides frame-rate updates, `Canvas` draws without creating per-particle views:

```swift
struct Bubble: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var speed: CGFloat
    var opacity: Double
    let createdAt: Date
}

class BubbleSystem: ObservableObject {
    var bubbles: [Bubble] = []

    func update(date: Date) {
        // Remove offscreen bubbles
        bubbles.removeAll { $0.y < -20 }

        // Add new bubbles occasionally
        if Int.random(in: 0...5) == 0 {
            bubbles.append(Bubble(
                x: CGFloat.random(in: 20...280),
                y: 300,
                size: CGFloat.random(in: 4...12),
                speed: CGFloat.random(in: 0.5...2.0),
                opacity: Double.random(in: 0.3...0.7),
                createdAt: date
            ))
        }

        // Move bubbles up with slight horizontal wobble
        for i in bubbles.indices {
            bubbles[i].y -= bubbles[i].speed
            bubbles[i].x += CGFloat.random(in: -0.5...0.5)
        }
    }
}
```

```swift
struct BubbleView: View {
    @StateObject private var system = BubbleSystem()

    var body: some View {
        TimelineView(.animation) { context in
            Canvas { ctx, size in
                system.update(date: context.date)
                for bubble in system.bubbles {
                    let rect = CGRect(
                        x: bubble.x - bubble.size / 2,
                        y: bubble.y - bubble.size / 2,
                        width: bubble.size,
                        height: bubble.size
                    )
                    ctx.opacity = bubble.opacity
                    ctx.fill(Circle().path(in: rect), with: .color(.white))
                }
            }
        }
    }
}
```

### Approach B: SpriteKit Particle System

Use Xcode's SpriteKit Particle File editor for visual configuration, then embed in SwiftUI via `SpriteView`:

```swift
import SpriteKit

class BubbleScene: SKScene {
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        if let emitter = SKEmitterNode(fileNamed: "Bubbles") {
            emitter.position = CGPoint(x: size.width / 2, y: 0)
            addChild(emitter)
        }
    }
}

// In SwiftUI:
SpriteView(scene: BubbleScene(), options: [.allowsTransparency])
    .frame(width: 300, height: 400)
    .allowsHitTesting(false)
```

### Approach C: Vortex Library (iOS 17+)

Paul Hudson's Vortex provides high-performance SwiftUI-native particles with built-in presets:

```swift
// SPM: https://github.com/twostraws/Vortex
import Vortex

VortexView(.rain) {
    Circle()
        .fill(.white)
        .frame(width: 32)
        .tag("circle")
}
```

Can be customized for bubble behavior (upward velocity, slower speed, circular shapes).

**Recommendation for AquaFaste:** Use TimelineView + Canvas for bubbles rising inside the liquid fill area. Lightweight, no dependencies, full control over behavior. Keep bubble count low (10–15 max) for battery efficiency.

---

## 4. Water Drop Animations

### Scale + Opacity Drop Animation

A water drop that falls and "splashes" into the fill:

```swift
struct WaterDropView: View {
    @State private var dropOffset: CGFloat = -100
    @State private var dropOpacity: Double = 1.0
    @State private var dropScale: CGFloat = 1.0
    @State private var splashScale: CGFloat = 0.0
    @State private var splashOpacity: Double = 0.0

    var body: some View {
        ZStack {
            // Splash ring
            Circle()
                .stroke(Color.cyan, lineWidth: 2)
                .scaleEffect(splashScale)
                .opacity(splashOpacity)
                .frame(width: 30, height: 30)

            // Drop
            Image(systemName: "drop.fill")
                .font(.title)
                .foregroundColor(.cyan)
                .offset(y: dropOffset)
                .opacity(dropOpacity)
                .scaleEffect(dropScale)
        }
    }

    func animateDrop() {
        // Reset
        dropOffset = -100
        dropOpacity = 1.0
        dropScale = 1.0
        splashScale = 0.0
        splashOpacity = 0.0

        // Fall
        withAnimation(.easeIn(duration: 0.4)) {
            dropOffset = 0
        }
        // Impact + splash
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.15)) {
                dropScale = 0.3
                dropOpacity = 0
            }
            withAnimation(.easeOut(duration: 0.5)) {
                splashScale = 3.0
                splashOpacity = 0.8
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                splashOpacity = 0
            }
        }
    }
}
```

### SF Symbols Animation (iOS 17+)

Use the `drop.fill` SF Symbol with symbol effects:

```swift
Image(systemName: "drop.fill")
    .symbolEffect(.bounce, value: triggerValue)
    .foregroundStyle(.cyan.gradient)
```

**Recommendation for AquaFaste:** Use water drop animation as feedback when user taps "Log Water." Drop falls into the fill area → splash ring → fill level rises. Combines multiple effect types for a cohesive moment.

---

## 5. Circular Progress with Gradient

### Activity Ring Pattern (Apple Watch Style)

The proven pattern for circular progress with gradient fill:

```swift
struct HydrationRingView: View {
    @Binding var progress: CGFloat  // 0.0 to 1.0

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color.blue.opacity(0.15), lineWidth: 20)

            // Progress arc with gradient
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color.cyan,
                            Color.blue,
                            Color.blue.opacity(0.8)
                        ]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)

            // Center content
            VStack(spacing: 4) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                Text("of daily goal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
```

### Key Techniques

- **`Circle().trim(from:to:)`** — controls arc length (0 = empty, 1 = full)
- **`AngularGradient`** — color transitions along the arc for visual richness
- **`.rotationEffect(.degrees(-90))`** — starts arc from 12 o'clock position
- **`StrokeStyle(lineCap: .round)`** — rounded endpoints like Apple's Activity Rings
- **Spring animation** on progress changes for natural feel

### Glow Effect at Progress Tip

Add a small circle at the progress endpoint for a glowing tip:

```swift
Circle()
    .fill(Color.cyan)
    .frame(width: 20, height: 20)
    .offset(y: -radius)
    .rotationEffect(.degrees(360 * Double(progress) - 90))
    .shadow(color: .cyan.opacity(0.6), radius: 6)
```

### Libraries

- **CircularProgressSwiftUI** (ArnavMotwani) — SPM package, supports linear/angular gradient fills
- **KDCircularProgress** — UIKit-based, has glow modes, less suited for pure SwiftUI

**Recommendation for AquaFaste:** Build a custom ring view (no dependency needed — the pattern is simple). Use AngularGradient transitioning from light cyan to deep blue, with the glowing tip circle for polish.

---

## 6. Splash Effects on Tap

### Ripple Effect with Metal Shader (iOS 17+)

Apple's WWDC sample provides a Metal-based ripple:

```swift
// RippleModifier — drives Metal shader from SwiftUI gesture
struct RippleModifier: ViewModifier {
    var origin: CGPoint
    var elapsedTime: TimeInterval
    var amplitude: Float = 12
    var frequency: Float = 15
    var decay: Float = 8
    var speed: Float = 1200

    func body(content: Content) -> some View {
        content.visualEffect { view, proxy in
            view.layerEffect(
                ShaderLibrary.Ripple(
                    .float2(origin),
                    .float(elapsedTime),
                    .float(amplitude),
                    .float(frequency),
                    .float(decay),
                    .float(speed)
                ),
                maxSampleOffset: CGSize(width: amplitude, height: amplitude)
            )
        }
    }
}
```

### Pure SwiftUI Splash (No Metal)

Concentric expanding rings with fading opacity:

```swift
struct SplashEffect: View {
    let origin: CGPoint
    @State private var rings: [UUID] = []

    var body: some View {
        ZStack {
            ForEach(rings, id: \.self) { _ in
                SplashRing()
            }
        }
    }
}

struct SplashRing: View {
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 0.8

    var body: some View {
        Circle()
            .stroke(Color.cyan, lineWidth: 2)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    scale = 2.5
                    opacity = 0
                }
            }
    }
}
```

Trigger 2–3 rings in sequence (50ms delay between each) for a realistic splash.

### Tap Feedback Pattern for Logging

On tap:
1. Button scale bounce (scale down to 0.9, spring back to 1.0)
2. Splash rings emanate from tap point
3. Water drop falls into fill area
4. Fill level rises with spring animation
5. Haptic feedback fires

**Recommendation for AquaFaste:** Use pure SwiftUI splash rings for iOS 16 compatibility. Add the Metal ripple as an enhancement for iOS 17+ devices via `if #available`.

---

## 7. Haptic Feedback Patterns

### SwiftUI sensoryFeedback (iOS 17+)

The modern approach — declarative, trigger-based:

```swift
// Simple: trigger on state change
.sensoryFeedback(.success, trigger: waterLogged)

// Impact with weight for "water drop" feel
.sensoryFeedback(.impact(weight: .medium, intensity: 0.7), trigger: logCount)

// Dynamic: different haptics for different amounts
.sensoryFeedback(trigger: logAmount) { oldValue, newValue in
    let delta = newValue - oldValue
    if delta >= 500 {
        return .impact(weight: .heavy, intensity: 1.0)
    } else if delta >= 250 {
        return .impact(weight: .medium, intensity: 0.7)
    } else {
        return .impact(flexibility: .soft, intensity: 0.4)
    }
}
```

### Available Feedback Types

| Type | Use Case |
|------|----------|
| `.success` | Goal reached, water logged successfully |
| `.warning` | Approaching dehydration threshold |
| `.error` | Invalid input, logging failure |
| `.increase` | Water amount increasing (stepper) |
| `.decrease` | Water amount decreasing (stepper) |
| `.selection` | Picking cup size, beverage type |
| `.impact(weight:intensity:)` | Water drop landing, button press |
| `.impact(flexibility:intensity:)` | Soft splash feel |

### Recommended Haptic Map for AquaFaste

| Action | Haptic | Rationale |
|--------|--------|-----------|
| Log water (tap) | `.impact(weight: .medium, intensity: 0.7)` | Satisfying "drop" feel |
| Goal reached (100%) | `.success` | Clear achievement signal |
| Quick-add button | `.impact(flexibility: .soft, intensity: 0.5)` | Light, repeatable |
| Amount stepper up | `.increase` | Matches Apple convention |
| Amount stepper down | `.decrease` | Matches Apple convention |
| Cup size selection | `.selection` | Standard picker haptic |
| Reminder notification | `.warning` | Gentle attention grab |
| Milestone (25%, 50%, 75%) | `.impact(weight: .light, intensity: 0.5)` | Subtle progress marker |

### Core Haptics for Custom Patterns (Advanced)

For a "water pour" haptic sequence — ramp intensity over time:

```swift
import CoreHaptics

func playWaterPourHaptic() {
    guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

    do {
        let engine = try CHHapticEngine()
        try engine.start()

        var events: [CHHapticEvent] = []
        // Rising intensity over 0.5s — mimics water filling
        for i in 0..<5 {
            let time = Double(i) * 0.1
            let intensity = Float(i + 1) / 5.0
            events.append(CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: time,
                duration: 0.1
            ))
        }

        let pattern = try CHHapticPattern(events: events, parameters: [])
        let player = try engine.makePlayer(with: pattern)
        try player.start(atTime: 0)
    } catch {
        // Haptics not available — fail silently
    }
}
```

### Platform Notes

- **iPad:** Does not support haptic feedback — sensoryFeedback is silently ignored
- **Simulator:** Haptics don't fire — must test on physical device
- **Battery:** Excessive haptics drain battery; keep them purposeful
- **Accessibility:** Don't rely solely on haptics for information — always pair with visual feedback

**Recommendation for AquaFaste:** Use `.sensoryFeedback` modifier for all standard interactions (iOS 17+). Add Core Haptics "water pour" pattern only for the main logging action. Fall back gracefully on older iOS / iPad.

---

## 8. Libraries & Dependencies Summary

| Library | What It Does | iOS Min | SPM | Verdict |
|---------|-------------|---------|-----|---------|
| **Vortex** (twostraws) | High-perf particle effects | 17 | ✅ | Nice-to-have for confetti on goal |
| **EffectsLibrary** (Stream) | Snow, rain, confetti, fireworks | 14 | ✅ | Overkill for our use case |
| **SwiftUI-Particles** (ArthurGuibert) | CAEmitterLayer wrapper | 14 | ✅ | Simpler than SpriteKit approach |
| **CircularProgressSwiftUI** | Animated progress ring | 14 | ✅ | Unnecessary — trivial to build |
| **BAFluidView** | UIKit fluid fill animation | 8 | ❌ | UIKit only, not SwiftUI native |

**Decision: Zero external animation dependencies.** All effects (waves, fills, bubbles, rings, haptics) can be built with native SwiftUI + Canvas + Core Haptics. This keeps the bundle small, avoids dependency churn, and maintains full control.

---

## 9. Performance Considerations

- **Wave shape:** Stride by 2–3px instead of 1px on older devices. Profile in Instruments.
- **Bubble system:** Cap at 10–15 simultaneous bubbles. Use `Canvas` not individual `View`s.
- **Layered waves:** 2–3 layers max. Each layer = one path re-render per frame.
- **Animations:** Use `.drawingGroup()` to flatten wave views into Metal-backed layers.
- **Battery:** Pause wave/bubble animations when app is backgrounded or screen is off.
- **Reduce Motion:** Check `UIAccessibility.isReduceMotionEnabled` — replace waves with static gradients, remove bubbles, keep functional animations only.

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

if reduceMotion {
    // Static gradient fill instead of animated waves
    Circle().fill(LinearGradient(...))
} else {
    // Full animated liquid fill
    AnimatedLiquidView(percent: progress)
}
```

---

## 10. Recommended Visual Stack for AquaFaste

### Main Screen — Daily Progress
- **Circular progress ring** with AngularGradient (cyan → blue)
- **Liquid fill** inside the ring with dual-layer animated waves
- **Bubble particles** rising inside the liquid (Canvas-based)
- Center: percentage text + daily total in mL

### Log Water Action
1. Button press → `.impact(weight: .medium)` haptic
2. Water drop falls (scale + offset animation)
3. Splash rings at impact point
4. Fill level rises (spring animation)
5. Bubble burst at new water level
6. If goal reached → `.success` haptic + confetti/celebration

### Widget
- Static circular progress ring (no animation — WidgetKit limitation)
- Fill percentage + numeric value

### Key Animations API Surface
- `Shape` + `animatableData` for waves
- `TimelineView` + `Canvas` for particles
- `.trim()` + `AngularGradient` for rings
- `.sensoryFeedback()` for haptics
- `withAnimation(.spring())` for state transitions

---

## Sources

1. [Hacking with Swift — WaveView](https://www.hackingwithswift.com/plus/custom-swiftui-components/creating-a-waveview-to-draw-smooth-waveforms)
2. [Aayush Raghuvanshi — Wave Animation with CoreGraphics](https://medium.com/@aayushraghuvanshi21/crafting-a-mesmerizing-wave-animation-in-swiftui-with-coregraphics-dc509e147c27)
3. [Prafulla Singh — Filling Wave Animation](https://prafullkumar77.medium.com/swiftui-how-to-make-filling-wave-animation-cd135e33b3d8)
4. [Victoria Petrova — Ripple Effect with Metal Shaders](https://medium.com/@vickipetrova/ripple-effect-with-swiftui-and-metal-shaders-a-custom-water-scene-ba6ec524ca0d)
5. [Cindori — Introduction to Shaders: Wave Effect](https://cindori.com/developer/swiftui-shaders-wave)
6. [Augmented Code — Animating Custom Wave Shape](https://augmentedcode.io/2020/09/27/animating-a-custom-wave-shape-in-swiftui/)
7. [CodeMatcher — Circle Wave Fill Solution](https://codematcher.com/questions/fill-circle-with-wave-animation-in-swiftui)
8. [Kodeco — Combining Animations (Liquid Pour)](https://www.kodeco.com/books/swiftui-animations-by-tutorials/v1.0/chapters/9-combining-animations)
9. [Hacking with Swift — Special Effects / Particle System](https://www.hackingwithswift.com/articles/246/special-effects-with-swiftui)
10. [Vortex — High-performance SwiftUI particles](https://github.com/twostraws/Vortex)
11. [SwiftUI-Particles — CAEmitterLayer wrapper](https://github.com/ArthurGuibert/SwiftUI-Particles)
12. [Hacking with Swift — Haptic Effects](https://www.hackingwithswift.com/quick-start/swiftui/how-to-add-haptic-effects-using-sensory-feedback)
13. [CreateWithSwift — Sensory Feedback Modifier](https://www.createwithswift.com/providing-feedback-sensory-feedback-modifier/)
14. [Swift with Majid — Sensory Feedback](https://swiftwithmajid.com/2023/10/10/sensory-feedback-in-swiftui/)
15. [Sarunw — Activity Ring in SwiftUI](https://sarunw.com/posts/how-to-create-activity-ring-in-swiftui/)
16. [Cindori — Circular Progress Ring Animation](https://cindori.com/developer/swiftui-animation-rings)
17. [BleepingSwift — Sensory Feedback and Haptics](https://bleepingswift.com/blog/sensory-feedback-haptics-swiftui)
18. [Kodeco — Circular Progress Bar](https://www.kodeco.com/books/swiftui-cookbook/v1.0/chapters/4-create-a-circular-progress-bar-in-swiftui)
19. [GetStream — SwiftUI Effects Library](https://getstream.io/blog/using-swiftui-effects-library-how-to-add-particle-effects-to-ios-apps/)
20. [Apple — SpriteKit Particle Effects](https://developer.apple.com/documentation/spritekit/skemitternode/creating_particle_effects)

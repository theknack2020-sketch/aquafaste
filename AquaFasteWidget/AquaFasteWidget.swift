import SwiftUI
import WidgetKit

// MARK: - Timeline Entry

struct HydrationEntry: TimelineEntry {
    let date: Date
    let todayTotal: Double
    let dailyGoal: Double
    let progress: Double
    let streak: Int
    let drinkCount: Int
}

// MARK: - Timeline Provider

struct HydrationProvider: TimelineProvider {
    func placeholder(in _: Context) -> HydrationEntry {
        HydrationEntry(date: .now, todayTotal: 1800, dailyGoal: 2500, progress: 0.72, streak: 5, drinkCount: 6)
    }

    func getSnapshot(in _: Context, completion: @escaping (HydrationEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<HydrationEntry>) -> Void) {
        let entry = currentEntry()
        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func currentEntry() -> HydrationEntry {
        HydrationEntry(
            date: .now,
            todayTotal: WidgetDataManager.todayTotal,
            dailyGoal: WidgetDataManager.dailyGoal,
            progress: WidgetDataManager.progress,
            streak: WidgetDataManager.streak,
            drinkCount: WidgetDataManager.drinkCount
        )
    }
}

// MARK: - Small Widget

struct SmallHydrationView: View {
    let entry: HydrationEntry

    var body: some View {
        ZStack {
            // Progress ring
            Circle()
                .stroke(Color.cyan.opacity(0.15), lineWidth: 8)

            Circle()
                .trim(from: 0, to: entry.progress)
                .stroke(
                    LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Image(systemName: "drop.fill")
                    .font(.footnote)
                    .foregroundStyle(.cyan)
                    .accessibilityHidden(true)

                Text("\(Int(entry.todayTotal))")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)

                Text("of \(Int(entry.dailyGoal)) ml")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if entry.streak > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 8))
                            .accessibilityHidden(true)
                        Text("\(entry.streak)")
                            .font(.caption2.bold())
                    }
                    .foregroundStyle(.orange)
                }
            }
        }
        .padding(16)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Medium Widget

struct MediumHydrationView: View {
    let entry: HydrationEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left: Progress ring
            ZStack {
                Circle()
                    .stroke(Color.cyan.opacity(0.15), lineWidth: 6)

                Circle()
                    .trim(from: 0, to: entry.progress)
                    .stroke(
                        LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 1) {
                    Text("\(Int(entry.progress * 100))%")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                    Image(systemName: "drop.fill")
                        .font(.caption2)
                        .foregroundStyle(.cyan)
                        .accessibilityHidden(true)
                }
            }
            .frame(width: 70, height: 70)

            // Right: Stats
            VStack(alignment: .leading, spacing: 6) {
                Text("Hydration")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Text("\(Int(entry.todayTotal)) ml")
                    .font(.system(.title3, design: .rounded, weight: .bold))

                HStack(spacing: 12) {
                    Label("\(entry.drinkCount) drinks", systemImage: "drop.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if entry.streak > 0 {
                        Label("\(entry.streak) day streak", systemImage: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }

                let remaining = max(0, Int(entry.dailyGoal - entry.todayTotal))
                if remaining > 0 {
                    Text("\(remaining) ml remaining")
                        .font(.caption2)
                        .foregroundStyle(.cyan)
                } else {
                    Label("Goal reached!", systemImage: "checkmark.circle.fill")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.green)
                }
            }

            Spacer()
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Accessory Circular (Lock Screen)

struct AccessoryCircularView: View {
    let entry: HydrationEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Gauge(value: entry.progress) {
                Image(systemName: "drop.fill")
                    .accessibilityHidden(true)
            }
            .gaugeStyle(.accessoryCircular)
            .tint(.cyan)
        }
    }
}

// MARK: - Widget Configuration

struct AquaFasteWidget: Widget {
    let kind = "AquaFasteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HydrationProvider()) { entry in
            AquaFasteWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Hydration")
        .description("Track your daily water intake at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular])
    }
}

struct AquaFasteWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: HydrationEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallHydrationView(entry: entry)
        case .systemMedium:
            MediumHydrationView(entry: entry)
        case .accessoryCircular:
            AccessoryCircularView(entry: entry)
        default:
            SmallHydrationView(entry: entry)
        }
    }
}

// MARK: - Widget Bundle

@main
struct AquaFasteWidgets: WidgetBundle {
    var body: some Widget {
        AquaFasteWidget()
    }
}

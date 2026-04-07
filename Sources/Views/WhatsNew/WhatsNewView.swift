import SwiftUI

// MARK: - What's New Screen

/// Shows new features after an app update.
/// Presented as a full-screen cover when the stored version doesn't match the current bundle version.
struct WhatsNewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let haptics = HapticManager.shared

    @State private var visibleRows: Set<Int> = []
    @State private var showButton = false

    private let features: [WhatsNewFeature] = [
        WhatsNewFeature(icon: "ipad.landscape", title: "Beautiful iPad Experience", description: "Optimized layouts for every iPad size, including Split View and Stage Manager."),
        WhatsNewFeature(icon: "textformat.size", title: "Smarter Typography", description: "Dynamic Type scales beautifully across all screens and text sizes."),
        WhatsNewFeature(icon: "wand.and.stars", title: "Refined Animations", description: "Smoother spring transitions and delightful micro-interactions throughout."),
        WhatsNewFeature(icon: "moon.fill", title: "Dark Mode Polish", description: "Deeper contrast, softer glows, and improved readability at night."),
        WhatsNewFeature(icon: "bolt.fill", title: "Performance Improvements", description: "Faster launch, smoother scrolling, and reduced memory usage."),
    ]

    var body: some View {
        ZStack {
            background
            content
        }
        .onAppear {
            animateIn()
        }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.12, blue: 0.28),
                    Color(red: 0.05, green: 0.18, blue: 0.42),
                    Color(red: 0.08, green: 0.25, blue: 0.50),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Ambient glow — top
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.cyan.opacity(0.25), .clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: -80, y: -260)
                .blur(radius: 60)

            // Ambient glow — bottom
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.blue.opacity(0.2), .clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 160
                    )
                )
                .frame(width: 320, height: 320)
                .offset(x: 120, y: 300)
                .blur(radius: 50)
        }
    }

    // MARK: - Content

    private var content: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 60)

            // Header
            headerSection

            Spacer()
                .frame(height: 36)

            // Feature list
            featureList

            Spacer()

            // Continue button
            continueButton
                .padding(.bottom, 50)
        }
        .padding(.horizontal, 28)
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "drop.fill")
                .font(.largeTitle)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.cyan, .blue],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .cyan.opacity(0.5), radius: 12, y: 4)
                .accessibilityHidden(true)

            Text("What's New in\nAquaFaste 2.0")
                .font(.system(.title, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private var featureList: some View {
        VStack(spacing: 16) {
            ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                featureRow(feature, index: index)
                    .opacity(visibleRows.contains(index) ? 1 : 0)
                    .offset(y: visibleRows.contains(index) ? 0 : 20)
            }
        }
    }

    private func featureRow(_ feature: WhatsNewFeature, index _: Int) -> some View {
        HStack(spacing: 16) {
            Image(systemName: feature.icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.cyan)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.cyan.opacity(0.12))
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(feature.title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)

                Text(feature.description)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }

    private var continueButton: some View {
        Button {
            dismissAndSave()
        } label: {
            Text("Continue")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        colors: [.cyan, Color(red: 0.2, green: 0.5, blue: 1.0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .cyan.opacity(0.4), radius: 12, y: 6)
        }
        .opacity(showButton ? 1 : 0)
        .offset(y: showButton ? 0 : 20)
        .accessibilityHint("Dismiss What's New screen")
    }

    // MARK: - Actions

    private func dismissAndSave() {
        haptics.success()
        WhatsNewManager.markCurrentVersionSeen()
        dismiss()
    }

    private func animateIn() {
        guard !reduceMotion else {
            visibleRows = Set(0 ..< features.count)
            showButton = true
            return
        }

        for index in features.indices {
            let delay = 0.15 + Double(index) * 0.1
            _ = withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay)) {
                visibleRows.insert(index)
            }
        }

        let buttonDelay = 0.15 + Double(features.count) * 0.1 + 0.15
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(buttonDelay)) {
            showButton = true
        }
    }
}

// MARK: - Supporting Types

private struct WhatsNewFeature {
    let icon: String
    let title: String
    let description: String
}

// MARK: - What's New Manager

enum WhatsNewManager {
    private static let lastSeenKey = "af_last_seen_version"

    /// Returns `true` if the user hasn't seen the What's New screen for the current version.
    static var shouldShow: Bool {
        let current = currentAppVersion
        let lastSeen = UserDefaults.standard.string(forKey: lastSeenKey)
        return lastSeen != current
    }

    /// Saves the current bundle version so the screen won't show again this version.
    static func markCurrentVersionSeen() {
        UserDefaults.standard.set(currentAppVersion, forKey: lastSeenKey)
    }

    private static var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }
}

// MARK: - Preview

#Preview {
    WhatsNewView()
}

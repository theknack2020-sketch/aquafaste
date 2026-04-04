import SwiftUI

extension EnvironmentValues {
    @Entry var isRegularWidth: Bool = false
}

// MARK: - Adaptive Font Extension

extension Font {
    /// Minimum readable body text — never below caption on any device
    /// On iPad uses footnote (13pt) instead of caption (12pt)
    static func adaptiveCaption(isRegular: Bool) -> Font {
        isRegular ? .footnote : .caption
    }

    /// Smallest allowed text — caption on iPad, caption2 on iPhone
    /// ⚠️ Use sparingly — only for legal text, timestamps, axis labels
    static func adaptiveCaption2(isRegular: Bool) -> Font {
        isRegular ? .caption : .caption2
    }

    /// Detail text that needs to be comfortably readable
    static func adaptiveDetail(isRegular: Bool) -> Font {
        isRegular ? .subheadline : .footnote
    }

    /// Subheadline that scales up for iPad
    static func adaptiveSubheadline(isRegular: Bool) -> Font {
        isRegular ? .body : .subheadline
    }

    /// Headline that scales up for iPad
    static func adaptiveHeadline(isRegular: Bool) -> Font {
        isRegular ? .title3 : .headline
    }

    /// Title that scales for iPad
    static func adaptiveTitle3(isRegular: Bool) -> Font {
        isRegular ? .title2 : .title3
    }

    /// Large display number (progress, stats)
    static func adaptiveDisplay(size: CGFloat, weight: Font.Weight = .bold, design: Font.Design = .rounded, isRegular: Bool) -> Font {
        let scaledSize = isRegular ? size * 1.25 : size
        return .system(size: scaledSize, weight: weight, design: design)
    }

    /// Chart axis label — guaranteed readable on all devices
    static func chartAxisLabel(isRegular: Bool) -> Font {
        isRegular ? .caption : .system(size: 11, weight: .medium)
    }

    /// Badge / pill text — small but readable
    static func adaptiveBadge(isRegular: Bool) -> Font {
        isRegular ? .caption.weight(.semibold) : .system(size: 11, weight: .semibold)
    }
}

// MARK: - Adaptive Spacing

struct AdaptiveSpacing {
    let isRegular: Bool

    /// Minimum padding (8 iPhone, 12 iPad)
    var xs: CGFloat {
        isRegular ? 12 : 8
    }

    /// Small padding (12 iPhone, 16 iPad)
    var sm: CGFloat {
        isRegular ? 16 : 12
    }

    /// Standard padding (16 iPhone, 24 iPad)
    var md: CGFloat {
        isRegular ? 24 : 16
    }

    /// Large padding (20 iPhone, 32 iPad)
    var lg: CGFloat {
        isRegular ? 32 : 20
    }

    /// Extra large (24 iPhone, 40 iPad)
    var xl: CGFloat {
        isRegular ? 40 : 24
    }

    /// Section spacing (20 iPhone, 28 iPad)
    var section: CGFloat {
        isRegular ? 28 : 20
    }

    /// Card inner padding (16 iPhone, 20 iPad)
    var card: CGFloat {
        isRegular ? 20 : 16
    }
}

// MARK: - Adaptive Sizes

struct AdaptiveSizes {
    let isRegular: Bool

    /// Progress ring diameter
    var progressRing: CGFloat {
        isRegular ? 420 : 300
    }

    /// Progress ring container (glow area)
    var progressContainer: CGFloat {
        isRegular ? 480 : 340
    }

    /// Quick add button
    var quickAddButton: CGFloat {
        isRegular ? 88 : 72
    }

    /// Drink tile icon circle
    var drinkIcon: CGFloat {
        isRegular ? 64 : 52
    }

    /// Small icon circle (favorites, recent)
    var smallIcon: CGFloat {
        isRegular ? 48 : 40
    }

    /// Touch target minimum
    var touchTarget: CGFloat {
        isRegular ? 52 : 44
    }

    /// Timeline dot
    var timelineDot: CGFloat {
        isRegular ? 12 : 10
    }

    /// Max content width for readable layout on iPad
    var maxContentWidth: CGFloat {
        isRegular ? 680 : .infinity
    }

    /// Max card width
    var maxCardWidth: CGFloat {
        isRegular ? 600 : .infinity
    }

    /// Achievement badge size
    var achievementBadge: CGFloat {
        isRegular ? 100 : 80
    }

    /// Chart height
    var chartHeight: CGFloat {
        isRegular ? 240 : 200
    }

    /// Hero icon size
    var heroIcon: CGFloat {
        isRegular ? 72 : 60
    }

    /// Grid columns for drink picker
    var drinkGridColumns: Int {
        isRegular ? 5 : 4
    }

    /// Grid columns for stats
    var statsGridColumns: Int {
        isRegular ? 3 : 2
    }

    /// Grid columns for achievements
    var achievementGridColumns: Int {
        isRegular ? 4 : 3
    }
}

// MARK: - View Modifier: Adaptive Container

/// Wraps content in a centered, max-width container for iPad readability
struct AdaptiveContainerModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var sizeClass

    var maxWidth: CGFloat

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: sizeClass == .regular ? maxWidth : .infinity)
    }
}

extension View {
    /// Constrains width for iPad readability — centers content naturally
    func adaptiveContainer(maxWidth: CGFloat = 680) -> some View {
        modifier(AdaptiveContainerModifier(maxWidth: maxWidth))
    }
}

// MARK: - View Modifier: Size Class Injection

/// Reads horizontalSizeClass and provides convenience boolean
struct AdaptiveSizeClassReader<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var sizeClass

    let content: (_ isRegular: Bool) -> Content

    var body: some View {
        content(sizeClass == .regular)
    }
}

// MARK: - Adaptive Grid Helper

extension [GridItem] {
    /// Creates adaptive grid columns based on size class
    static func adaptive(
        compact compactCount: Int,
        regular regularCount: Int,
        spacing: CGFloat = 12,
        isRegular: Bool
    ) -> [GridItem] {
        let count = isRegular ? regularCount : compactCount
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: count)
    }
}

// MARK: - Convenience View Extension

extension View {
    /// Applies adaptive horizontal padding that scales with size class
    func adaptivePadding(_ isRegular: Bool) -> some View {
        padding(.horizontal, isRegular ? 32 : 16)
    }

    /// Limits Dynamic Type to prevent overflow in constrained spaces
    func limitDynamicType(_ limit: DynamicTypeSize = .accessibility1) -> some View {
        dynamicTypeSize(...limit)
    }
}

import SwiftUI

/// A screen's title and the line under it: "Round 4" / "of 8 · 6 cards each".
struct ScreenTitle: View {
    let title: String
    var subtitle: String? = nil
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        VStack(alignment: alignment, spacing: DS.Space.xs) {
            Text(title)
                .font(DS.Typography.screenTitle)
                .contentTransition(.numericText())
                .multilineTextAlignment(alignment == .center ? .center : .leading)
            if let subtitle {
                Text(subtitle)
                    .font(DS.Typography.screenSubtitle)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(alignment == .center ? .center : .leading)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// A card's heading, with an optional footnote under it.
struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            Text(title)
                .font(DS.Typography.sectionTitle)
                .accessibilityAddTraits(.isHeader)
            if let subtitle {
                Text(subtitle)
                    .font(DS.Typography.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// Every score in the app: one of five sizes, monospaced digits, and a rolling transition
/// when the number changes.
struct ScoreNumeral: View {
    let value: Int?
    var style: ScoreStyle = .medium
    /// "+12" rather than "12"; negatives always show their sign.
    var showsPlus = false

    init(_ value: Int?, style: ScoreStyle = .medium, showsPlus: Bool = false) {
        self.value = value
        self.style = style
        self.showsPlus = showsPlus
    }

    var body: some View {
        Text(text)
            .font(style.font)
            .contentTransition(.numericText(value: Double(value ?? 0)))
    }

    private var text: String {
        guard let value else { return "–" }
        return showsPlus && value > 0 ? "+\(value)" : "\(value)"
    }
}

/// A value in a gold capsule: "+10", "6 letters", with an optional symbol in front.
/// VoiceOver reads `accessibilityText` when given, so a star is never read aloud as a glyph.
struct ValueBadge: View {
    let text: String
    var systemImage: String? = nil
    var accessibilityText: String? = nil

    var body: some View {
        HStack(spacing: DS.Space.xxs) {
            if let systemImage {
                Image(systemName: systemImage)
                    .imageScale(.small)
            }
            Text(text)
        }
        .font(DS.Typography.badge)
        .foregroundStyle(DS.Colors.bonusText)
        .padding(.horizontal, DS.Space.s)
        .padding(.vertical, 3)
        .background(DS.Colors.tint(DS.Colors.bonusFill), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText ?? text)
    }
}

/// One bonus: a gold star, its name, an optional line about who and why, and what trails it.
struct BonusHeaderRow<Trailing: View>: View {
    let title: String
    var detail: String? = nil
    /// Outlined while the cards haven't decided yet.
    var isDecided = true
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: DS.Space.s) {
            Image(systemName: isDecided ? "star.fill" : "star")
                .foregroundStyle(DS.Colors.bonusText)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: DS.Space.xxs) {
                Text(title)
                    .font(DS.Typography.label)
                if let detail {
                    Text(detail)
                        .font(DS.Typography.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            trailing
        }
    }
}

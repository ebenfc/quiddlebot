import SwiftUI

/// A player's colored circle with their monogram, so each player is recognisable at a glance.
/// Decorative: the name always sits next to it, so VoiceOver skips it.
struct PlayerAvatar: View {
    let seat: Int
    let monogram: String
    var size: CGFloat = DS.Avatar.regular

    /// The avatar for `seat` at a table of `names`, two letters where initials clash.
    init(seat: Int, in names: [String], size: CGFloat = DS.Avatar.regular) {
        self.seat = seat
        let monograms = Monogram.make(for: names)
        monogram = monograms.indices.contains(seat) ? monograms[seat] : "?"
        self.size = size
    }

    var body: some View {
        Text(monogram)
            .font(.system(size: size * (monogram.count > 1 ? 0.4 : 0.46), weight: .bold, design: .rounded))
            .foregroundStyle(DS.Colors.onPlayer)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(width: size, height: size)
            .background(DS.Colors.player(seat), in: Circle())
            .accessibilityHidden(true)
    }
}

/// A finishing place: gold, silver, bronze, then plain. The number is on the medal, so the
/// rank never depends on telling the colors apart.
struct RankMedal: View {
    let rank: Int
    @ScaledMetric(relativeTo: .footnote) private var side: CGFloat = 28

    var body: some View {
        Text("\(rank)")
            .font(.footnote.weight(.bold).monospacedDigit())
            .foregroundStyle(rank <= 3 ? DS.Colors.onBonus : Color.secondary)
            .frame(width: side, height: side)
            .background(fill, in: Circle())
            .accessibilityHidden(true)
    }

    private var fill: Color {
        switch rank {
        case 1: DS.Colors.bonusFill
        case 2: DS.Colors.silver
        case 3: DS.Colors.bronze
        default: DS.Colors.surfaceSunken
        }
    }
}

/// One player and their total: the live scoreboard and the final standings.
/// The leader's row gets a gold wash and edge, plus a crown or the first-place medal.
struct PlayerScoreRow: View {
    let names: [String]
    let seat: Int
    let total: Int
    /// Final standings show a medal in front.
    var rank: Int? = nil
    /// A second line, such as "+12 last round".
    var detail: String? = nil
    var isLeader = false
    /// The scoreboard marks the leader with a crown; the standings use the medal instead.
    var showsCrown = false
    var avatarSize: CGFloat = DS.Avatar.large

    var body: some View {
        HStack(spacing: DS.Space.m) {
            if let rank { RankMedal(rank: rank) }
            PlayerAvatar(seat: seat, in: names, size: avatarSize)

            VStack(alignment: .leading, spacing: DS.Space.xxs) {
                HStack(spacing: DS.Space.s) {
                    Text(names[seat])
                        .font(DS.Typography.rowTitle)
                        .lineLimit(1)
                    if showsCrown && isLeader {
                        Image(systemName: "crown.fill")
                            .font(.subheadline)
                            .foregroundStyle(DS.Colors.bonusText)
                            .symbolEffect(.bounce, value: total)
                            .motionSafeTransition(.scale.combined(with: .opacity))
                    }
                }
                if let detail {
                    Text(detail)
                        .font(DS.Typography.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: DS.Space.s)

            ScoreNumeral(total, style: .large)
        }
        .padding(.horizontal, DS.Space.m)
        .padding(.vertical, DS.Space.m)
        .background {
            if isLeader {
                RoundedRectangle.ds(DS.Radius.control)
                    .fill(DS.Colors.tint(DS.Colors.bonusFill))
            }
        }
        .overlay {
            if isLeader {
                RoundedRectangle.ds(DS.Radius.control)
                    .strokeBorder(DS.Colors.bonusFill, lineWidth: 1.5)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var parts: [String] = []
        if let rank { parts.append("Rank \(rank)") }
        parts.append(names[seat])
        parts.append("\(total) points")
        if isLeader && showsCrown { parts.append("leading") }
        if let detail { parts.append(detail) }
        return parts.joined(separator: ", ")
    }
}

/// A small fact in its own card: "8 rounds", "+10 per bonus".
struct StatTile: View {
    let value: String
    let label: String
    var isBonus = false

    var body: some View {
        VStack(spacing: DS.Space.xxs) {
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(isBonus ? DS.Colors.bonusText : Color.primary)
            Text(label)
                .font(DS.Typography.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .dsCard(padding: DS.Space.m)
    }
}

/// A choice in a row of choices, such as who gets a bonus. Filled when picked, with a
/// checkmark so the pick doesn't rest on color.
struct SelectableChip: View {
    let title: String
    let isSelected: Bool
    var fill: Color = DS.Colors.accent
    var onFill: Color = DS.Colors.onAccent
    /// A dot in `fill`'s color ahead of the title: the player's seat color.
    var showsDot = false
    /// A trailing symbol and what VoiceOver says for it, such as the cards' suggestion.
    var badge: (symbol: String, label: String)? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Space.xs + 2) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .accessibilityHidden(true)
                } else if showsDot {
                    Circle()
                        .fill(fill)
                        .frame(width: 8, height: 8)
                        .accessibilityHidden(true)
                }
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if let badge {
                    Image(systemName: badge.symbol)
                        .font(.caption2)
                        .accessibilityLabel(badge.label)
                }
            }
            .font(DS.Typography.label)
            .foregroundStyle(isSelected ? onFill : Color.primary)
            .frame(maxWidth: .infinity, minHeight: DS.Size.minTap)
            .background(isSelected ? fill : DS.Colors.surfaceSunken, in: Capsule())
            .animation(DS.Motion.quick, value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

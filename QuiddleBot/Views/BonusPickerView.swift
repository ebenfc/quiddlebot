import SwiftUI

/// Who gets a bonus this round: one chip per player, in their color, plus "Tie / none".
struct BonusPickerView: View {
    let title: String
    let bonus: Int
    let players: [String]
    @Binding var selection: BonusAward
    /// What the word calculator's counted cards say, marked with sparkles. nil unless every
    /// player's hand was counted.
    var suggestion: BonusAward? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .foregroundStyle(Theme.gold)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("+\(bonus)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(Theme.gold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.gold.opacity(0.15), in: Capsule())
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: columnCount),
                      spacing: 8) {
                ForEach(players.indices, id: \.self) { player in
                    chip(players[player], value: .player(player), color: Theme.playerColor(player), showsDot: true)
                }
                chip("Tie / none", value: .tie, color: Color(.systemGray), showsDot: false)
            }

            if let suggestion {
                Label(suggestion == selection ? "Picked from the counted cards. Tap to change."
                                              : "Sparkles mark what the counted cards say.",
                      systemImage: "sparkles")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }
        }
        .animation(.snappy, value: suggestion)
        .sensoryFeedback(.selection, trigger: selection)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(title) bonus")
    }

    /// Two players plus "Tie" fit in one row of three; more players wrap into a tidy grid.
    private var columnCount: Int {
        let chips = players.count + 1
        if chips <= 3 { return chips }
        return chips == 4 ? 2 : 3
    }

    private func chip(_ label: String, value: BonusAward, color: Color, showsDot: Bool) -> some View {
        let isSelected = selection == value
        return Button {
            selection = value
        } label: {
            HStack(spacing: 6) {
                if showsDot {
                    Circle()
                        .fill(isSelected ? Color.white : color)
                        .frame(width: 8, height: 8)
                }
                Text(label)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if suggestion == value {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                        .accessibilityLabel("suggested by the counted cards")
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background {
                if isSelected {
                    Capsule().fill(color.gradient)
                } else {
                    Capsule().fill(Color(.tertiarySystemFill))
                }
            }
            .animation(.snappy(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

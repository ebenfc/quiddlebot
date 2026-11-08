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
        VStack(alignment: .leading, spacing: DS.Space.m) {
            BonusHeaderRow(title: title) {
                ValueBadge(text: "+\(bonus)", accessibilityText: "\(bonus) points")
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DS.Space.s), count: columnCount),
                      spacing: DS.Space.s) {
                ForEach(players.indices, id: \.self) { player in
                    chip(players[player], value: .player(player),
                         fill: DS.Colors.player(player), onFill: DS.Colors.onPlayer, showsDot: true)
                }
                chip("Tie / none", value: .tie, fill: DS.Colors.accent, onFill: DS.Colors.onAccent, showsDot: false)
            }

            if let suggestion {
                Label(suggestion == selection ? "Picked from the counted cards. Tap to change."
                                              : "Sparkles mark what the counted cards say.",
                      systemImage: "sparkles")
                    .font(DS.Typography.caption)
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }
        }
        .animation(DS.Motion.standard, value: suggestion)
        .sensoryFeedback(DS.Haptic.select, trigger: selection)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(title) bonus")
    }

    /// Two players plus "Tie" fit in one row of three; more players wrap into a tidy grid.
    private var columnCount: Int {
        let chips = players.count + 1
        if chips <= 3 { return chips }
        return chips == 4 ? 2 : 3
    }

    private func chip(_ label: String, value: BonusAward, fill: Color, onFill: Color,
                      showsDot: Bool) -> some View {
        SelectableChip(title: label,
                       isSelected: selection == value,
                       fill: fill,
                       onFill: onFill,
                       showsDot: showsDot,
                       badge: suggestion == value ? ("sparkles", "suggested by the counted cards") : nil) {
            selection = value
        }
    }
}

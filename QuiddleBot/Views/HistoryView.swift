import SwiftUI

/// The scorecard: a compact grid with one row per round and a totals row.
/// A gold star marks a round where the player won a bonus.
struct HistoryView: View {
    let game: Game
    /// When set, each round gets an edit button.
    var onEdit: ((Int) -> Void)? = nil

    var body: some View {
        let totals = Scoring.totals(for: game)

        Grid(alignment: .center, horizontalSpacing: DS.Space.xs + 2, verticalSpacing: DS.Space.s) {
            GridRow {
                Text("Rd")
                    .font(DS.Typography.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Round")
                ForEach(game.players.indices, id: \.self) { player in
                    PlayerAvatar(seat: player, in: game.players, size: DS.Avatar.small)
                        .frame(maxWidth: .infinity)
                }
                if onEdit != nil {
                    Color.clear.frame(width: DS.Size.minTap, height: 1)
                }
            }

            Divider().gridCellUnsizedAxes(.horizontal)

            ForEach(Array(game.rounds.enumerated()), id: \.offset) { offset, round in
                GridRow {
                    Text("\(offset + 1)")
                        .font(DS.Typography.label.monospacedDigit())
                        .foregroundStyle(.secondary)
                    ForEach(game.players.indices, id: \.self) { player in
                        cell(round: round, player: player)
                    }
                    if let onEdit {
                        Button {
                            onEdit(offset + 1)
                        } label: {
                            Image(systemName: "pencil")
                                .font(.subheadline.weight(.semibold))
                                .frame(width: DS.Size.minTap, height: DS.Size.minTap)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(DS.Colors.accent)
                        .accessibilityLabel("Edit round \(offset + 1)")
                    }
                }
            }

            Divider().gridCellUnsizedAxes(.horizontal)

            GridRow {
                Text("Total")
                    .font(DS.Typography.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                ForEach(game.players.indices, id: \.self) { player in
                    ScoreNumeral(totals[player], style: .cellTotal)
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel("\(game.players[player]) total \(totals[player])")
                }
                if onEdit != nil {
                    Color.clear.frame(width: DS.Size.minTap, height: 1)
                }
            }
        }
        // A grid of up to four players plus an edit column: beyond this size it overflows.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    private func cell(round: Round, player: Int) -> some View {
        let points = Scoring.handTotal(round: round, player: player, rules: game.rules)
        let bonus = Scoring.bonuses(in: round, for: player, rules: game.rules)
        return HStack(spacing: DS.Space.xxs) {
            ScoreNumeral(points, style: .cell)
            if bonus > 0 {
                Image(systemName: "star.fill")
                    .font(.caption2.weight(.bold))
                    .imageScale(.small)
                    .foregroundStyle(DS.Colors.bonusText)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(game.players[player]): \(points)\(bonus > 0 ? ", including a bonus" : "")")
    }
}

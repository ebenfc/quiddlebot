import SwiftUI

/// The scorecard: a compact grid with one row per round and a totals row.
/// A gold star marks a round where the player won a bonus.
struct HistoryView: View {
    let game: Game
    /// When set, each round gets an edit button.
    var onEdit: ((Int) -> Void)? = nil

    var body: some View {
        let totals = Scoring.totals(for: game)

        Grid(alignment: .center, horizontalSpacing: 6, verticalSpacing: 8) {
            GridRow {
                Text("Rd")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                ForEach(game.players.indices, id: \.self) { player in
                    PlayerAvatar(name: game.players[player], index: player, size: 26)
                        .frame(maxWidth: .infinity)
                }
                if onEdit != nil {
                    Color.clear.frame(width: 44, height: 1)
                }
            }

            Divider().gridCellUnsizedAxes(.horizontal)

            ForEach(Array(game.rounds.enumerated()), id: \.offset) { offset, round in
                GridRow {
                    Text("\(offset + 1)")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
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
                                .frame(width: 44, height: 36)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.accentColor)
                        .accessibilityLabel("Edit round \(offset + 1)")
                    }
                }
            }

            Divider().gridCellUnsizedAxes(.horizontal)

            GridRow {
                Text("Total")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                ForEach(game.players.indices, id: \.self) { player in
                    Text("\(totals[player])")
                        .font(.body.weight(.bold).monospacedDigit())
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel("\(game.players[player]) total \(totals[player])")
                }
                if onEdit != nil {
                    Color.clear.frame(width: 44, height: 1)
                }
            }
        }
    }

    private func cell(round: Round, player: Int) -> some View {
        let points = Scoring.handTotal(round: round, player: player, rules: game.rules)
        let bonus = Scoring.bonuses(in: round, for: player, rules: game.rules)
        return HStack(spacing: 2) {
            Text("\(points)")
                .font(.body.monospacedDigit())
            if bonus > 0 {
                Image(systemName: "star.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Theme.gold)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(game.players[player]): \(points)\(bonus > 0 ? ", including a bonus" : "")")
    }
}

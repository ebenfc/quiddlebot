import SwiftUI

/// Running totals, one row per player, with the leader marked in gold.
struct ScoreboardView: View {
    let game: Game

    var body: some View {
        let totals = Scoring.totals(for: game)
        let leaders = Scoring.leaders(for: game)

        VStack(spacing: 6) {
            ForEach(game.players.indices, id: \.self) { player in
                let isLeader = leaders.contains(player)
                HStack(spacing: 12) {
                    PlayerAvatar(name: game.players[player], index: player, size: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(game.players[player])
                                .font(.headline)
                                .lineLimit(1)
                            if isLeader {
                                Image(systemName: "crown.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.gold)
                                    .transition(.scale.combined(with: .opacity))
                                    .accessibilityLabel("Leading")
                            }
                        }
                        if let last = lastRound(player) {
                            Text(last >= 0 ? "+\(last) last round" : "\(last) last round")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer(minLength: 8)

                    Text("\(totals[player])")
                        .font(.title.weight(.bold).monospacedDigit())
                        .contentTransition(.numericText(value: Double(totals[player])))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background {
                    if isLeader {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Theme.gold.opacity(0.12))
                    }
                }
                .overlay {
                    if isLeader {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Theme.gold.opacity(0.45), lineWidth: 1.5)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .card(padding: 8)
        .animation(.snappy, value: totals)
    }

    private func lastRound(_ player: Int) -> Int? {
        game.rounds.last.map { Scoring.handTotal(round: $0, player: player, rules: game.rules) }
    }
}

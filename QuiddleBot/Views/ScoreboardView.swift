import SwiftUI

/// Running totals, one row per player, with the leader marked in gold.
struct ScoreboardView: View {
    let game: Game

    var body: some View {
        let totals = Scoring.totals(for: game)
        let leaders = Scoring.leaders(for: game)

        VStack(spacing: DS.Space.xs) {
            ForEach(game.players.indices, id: \.self) { player in
                PlayerScoreRow(names: game.players,
                               seat: player,
                               total: totals[player],
                               detail: lastRound(player).map { $0 >= 0 ? "+\($0) last round" : "\($0) last round" },
                               isLeader: leaders.contains(player),
                               showsCrown: true)
            }
        }
        .dsCard(padding: DS.Space.s)
        .animation(DS.Motion.standard, value: totals)
    }

    private func lastRound(_ player: Int) -> Int? {
        game.rounds.last.map { Scoring.handTotal(round: $0, player: player, rules: game.rules) }
    }
}

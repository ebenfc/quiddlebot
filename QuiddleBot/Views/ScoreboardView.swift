import SwiftUI

/// Running totals, with the leader(s) marked.
struct ScoreboardView: View {
    let game: Game

    var body: some View {
        let totals = Scoring.totals(for: game)
        let leaders = Scoring.leaders(for: game)

        VStack(spacing: 0) {
            ForEach(game.players.indices, id: \.self) { player in
                HStack(spacing: 8) {
                    if leaders.contains(player) {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.yellow)
                            .accessibilityLabel("Leading")
                    }
                    Text(game.players[player])
                        .fontWeight(leaders.contains(player) ? .semibold : .regular)
                        .lineLimit(1)
                    Spacer()
                    Text("\(totals[player])")
                        .font(.title3.monospacedDigit().weight(.semibold))
                }
                .padding(.vertical, 10)
                .accessibilityElement(children: .combine)

                if player < game.players.count - 1 {
                    Divider()
                }
            }
        }
        .padding(.horizontal)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

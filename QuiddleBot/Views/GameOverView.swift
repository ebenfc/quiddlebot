import SwiftUI

struct GameOverView: View {
    @Environment(GameStore.self) private var store
    let game: Game

    @State private var showsHistory = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text("Game Over")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text(headline)
                            .font(.largeTitle.weight(.bold))
                            .multilineTextAlignment(.center)
                        if let margin = Scoring.margin(for: game) {
                            Text("Margin of victory: ^[\(margin) point](inflect: true)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top)

                    standingsList

                    Button {
                        store.reset()
                    } label: {
                        Text("New Game")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 32)
                    }
                    .buttonStyle(.borderedProminent)

                    if !game.rounds.isEmpty {
                        DisclosureGroup("Round History", isExpanded: $showsHistory) {
                            HistoryView(game: game, showsTitle: false)
                                .padding(.top, 8)
                        }
                        .font(.headline)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Final Scores")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var headline: String {
        if let winner = Scoring.winner(for: game) {
            return "\(game.players[winner]) wins!"
        }
        return "It's a tie!"
    }

    private var standingsList: some View {
        let standings = Scoring.standings(for: game)
        return VStack(spacing: 0) {
            ForEach(Array(standings.enumerated()), id: \.element.id) { index, standing in
                HStack(spacing: 12) {
                    Text("\(standing.rank)")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 28)
                    if standing.rank == 1 {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(.yellow)
                            .accessibilityLabel("Winner")
                    }
                    Text(standing.name)
                        .fontWeight(standing.rank == 1 ? .semibold : .regular)
                        .lineLimit(1)
                    Spacer()
                    Text("\(standing.total)")
                        .font(.title3.monospacedDigit().weight(.semibold))
                }
                .padding(.vertical, 12)
                .accessibilityElement(children: .combine)

                if index < standings.count - 1 {
                    Divider()
                }
            }
        }
        .padding(.horizontal)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#if DEBUG
#Preview {
    let store = GameStore.preview(players: ["Ada", "Ben", "Cy"], rounds: 8)
    return GameOverView(game: store.game!).environment(store)
}
#endif

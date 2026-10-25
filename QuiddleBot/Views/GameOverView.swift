import SwiftUI

struct GameOverView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let game: Game

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    hero
                    standingsCard
                    if !game.rounds.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Scorecard").font(.title3.bold())
                            HistoryView(game: game)
                        }
                        .card()
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .safeAreaInset(edge: .bottom) {
                BottomActionBar {
                    HStack(spacing: 12) {
                        Button("New Players") { store.reset() }
                            .buttonStyle(SecondaryButtonStyle())
                        Button {
                            withAnimation(.snappy) { store.rematch() }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise")
                                Text("Rematch")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
            }
            .overlay {
                if !reduceMotion {
                    ConfettiView()
                        .allowsHitTesting(false)
                        .ignoresSafeArea()
                }
            }
            .navigationTitle("Final Scores")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sensoryFeedback(.success, trigger: game.isFinished)
    }

    private var winner: Int? { Scoring.winner(for: game) }

    private var hero: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Theme.gold.gradient)
                    .frame(width: 92, height: 92)
                    .shadow(color: Theme.gold.opacity(0.45), radius: 18, x: 0, y: 6)
                Image(systemName: winner == nil ? "equal" : "trophy.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.top, 8)
            .accessibilityHidden(true)

            Text(headline)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            if let margin = Scoring.margin(for: game) {
                Text("by ^[\(margin) point](inflect: true)")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            } else {
                Text("Shared at the top")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var headline: String {
        if let winner { return "\(game.players[winner]) wins!" }
        return "It's a tie!"
    }

    private var standingsCard: some View {
        let standings = Scoring.standings(for: game)
        return VStack(spacing: 6) {
            ForEach(standings) { standing in
                HStack(spacing: 12) {
                    Text("\(standing.rank)")
                        .font(.subheadline.weight(.bold).monospacedDigit())
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(medalColor(for: standing.rank).gradient, in: Circle())
                    PlayerAvatar(name: standing.name, index: standing.player, size: 36)
                    Text(standing.name)
                        .font(standing.rank == 1 ? .headline : .body)
                        .lineLimit(1)
                    Spacer()
                    Text("\(standing.total)")
                        .font(.title2.weight(.bold).monospacedDigit())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background {
                    if standing.rank == 1 {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Theme.gold.opacity(0.12))
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Rank \(standing.rank), \(standing.name), \(standing.total) points")
            }
        }
        .card(padding: 8)
    }

    private func medalColor(for rank: Int) -> Color {
        switch rank {
        case 1: Theme.gold
        case 2: Color(.systemGray2)
        case 3: Color(red: 0.72, green: 0.45, blue: 0.20)
        default: Color(.systemGray4)
        }
    }
}

#if DEBUG
#Preview {
    let store = GameStore.preview(players: ["Ada", "Ben", "Cy"], rounds: 8)
    return GameOverView(game: store.game!).environment(store)
}
#endif

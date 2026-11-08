import SwiftUI

struct GameOverView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let game: Game

    /// True only when this game finished just now, not when the app reopens on final scores.
    @State private var isCelebrating = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Space.xl) {
                    hero
                    standingsCard
                    if let highlights = GameHighlights(game: game) {
                        highlightsCard(highlights)
                    }
                    if !game.rounds.isEmpty {
                        VStack(alignment: .leading, spacing: DS.Space.m) {
                            SectionHeader(title: "Scorecard")
                            HistoryView(game: game)
                        }
                        .dsCard()
                    }
                }
                .padding(DS.Space.screen)
            }
            .dsCanvas()
            .bottomActionBar {
                HStack(spacing: DS.Space.m) {
                    Button("New Players") { store.reset() }
                        .buttonStyle(SecondaryButtonStyle())
                    Button {
                        withAnimation(DS.Motion.standard) { store.rematch() }
                    } label: {
                        HStack(spacing: DS.Space.s) {
                            Image(systemName: "arrow.clockwise")
                            Text("Rematch")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .overlay {
                if isCelebrating && !reduceMotion {
                    ConfettiView()
                        .allowsHitTesting(false)
                        .ignoresSafeArea()
                }
            }
            .navigationTitle("Final Scores")
            .navigationBarTitleDisplayMode(.inline)
        }
        // Fires on the change from false to true, which `onAppear` makes once per finish.
        .sensoryFeedback(DS.Haptic.success, trigger: isCelebrating)
        .onAppear {
            if store.takeCelebration() { isCelebrating = true }
        }
    }

    private var winner: Int? { Scoring.winner(for: game) }

    private var hero: some View {
        VStack(spacing: DS.Space.m) {
            ZStack {
                Circle()
                    .fill(DS.Colors.bonusFill)
                    .frame(width: 92, height: 92)
                    .shadow(color: DS.Colors.bonusFill.opacity(0.45), radius: 18, x: 0, y: 6)
                Image(systemName: winner == nil ? "equal" : "trophy.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(DS.Colors.onBonus)
                    .symbolEffect(.bounce, value: isCelebrating)
            }
            .padding(.top, DS.Space.s)
            .accessibilityHidden(true)

            ScreenTitle(title: headline, subtitle: marginText, alignment: .center)
        }
    }

    private var headline: String {
        if let winner { return "\(game.players[winner]) wins!" }
        return "It's a tie!"
    }

    private var marginText: String {
        guard let margin = Scoring.margin(for: game) else { return "Shared at the top" }
        return margin == 1 ? "by 1 point" : "by \(margin) points"
    }

    private var standingsCard: some View {
        let standings = Scoring.standings(for: game)
        return VStack(spacing: DS.Space.xs) {
            ForEach(standings) { standing in
                PlayerScoreRow(names: game.players,
                               seat: standing.player,
                               total: standing.total,
                               rank: standing.rank,
                               isLeader: standing.rank == 1,
                               avatarSize: DS.Avatar.regular)
            }
        }
        .dsCard(padding: DS.Space.s)
    }

    /// The game's standout words, from the counted hands. Hidden for a game of typed scores.
    private func highlightsCard(_ highlights: GameHighlights) -> some View {
        let longest = highlights.longestWord
        let best = highlights.bestWord
        return VStack(alignment: .leading, spacing: DS.Space.l) {
            SectionHeader(title: "Highlights")
            if longest == best {
                // One word won both: say it once.
                highlight("Longest and best word", longest,
                          detail: "\(longest.word.letters) letters · \(best.word.points) points")
            } else {
                highlight("Longest word", longest, detail: "\(longest.word.letters) letters")
                highlight("Best word", best, detail: "\(best.word.points) points")
            }
        }
        .dsCard()
    }

    private func highlight(_ title: String, _ pick: GameHighlights.Pick, detail: String) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.s) {
            BonusHeaderRow(title: title) {
                ValueBadge(text: detail)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DS.Space.xs) {
                    ForEach(pick.word.faces.indices, id: \.self) { position in
                        LetterTile(face: pick.word.faces[position])
                    }
                }
                .padding(.bottom, DS.Space.xxs)
            }
            HStack(spacing: DS.Space.xs + 2) {
                PlayerAvatar(seat: pick.player, in: game.players, size: DS.Avatar.tiny)
                Text("\(game.players[pick.player]) · round \(pick.round)")
                    .font(DS.Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(pick.word.text), \(detail), \(game.players[pick.player]), round \(pick.round)")
    }
}

#if DEBUG
#Preview {
    let store = GameStore.preview(players: ["Ada", "Ben", "Cy"], rounds: 8)
    return GameOverView(game: store.game!).environment(store)
}
#endif

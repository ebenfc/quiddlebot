import SwiftUI

struct GameView: View {
    @Environment(GameStore.self) private var store
    let game: Game

    /// Typed-but-unsubmitted input, keyed by round number, so starting an edit of an
    /// earlier round does not throw away what was typed for the current one.
    @State private var drafts: [Int: RoundDraft] = [:]
    @State private var confirmEndEarly = false
    @State private var confirmNewGame = false
    /// Who the round counter opens on, while it is showing.
    @State private var counting: CountingStart?

    private struct CountingStart: Identifiable {
        let player: Int
        var id: Int { player }
    }

    private var activeRound: Int { store.editingRound ?? game.currentRound }
    private var isEditing: Bool { store.editingRound != nil }
    private var activeDraft: RoundDraft { drafts[activeRound] ?? RoundDraft(playerCount: game.players.count) }

    var body: some View {
        NavigationStack {
            ScrollViewReader { scroller in
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        RoundNavView(game: game, editingRound: store.editingRound, onSelect: beginEditing)
                        ScoreboardView(game: game)
                        RoundEntryView(game: game,
                                       isEditing: isEditing,
                                       draft: draftBinding(for: activeRound),
                                       onCount: startCounting(at:))
                            .id(activeRound)
                            .background(alignment: .top) {
                                Color.clear.frame(height: 1).id(Self.roundAnchor)
                            }
                        if !game.rounds.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Scorecard").font(.title3.bold())
                                HistoryView(game: game, onEdit: beginEditing)
                            }
                            .card()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .fullScreenCover(item: $counting, onDismiss: {
                    // Back from counting: show the round's results, not the scoreboard.
                    withAnimation(.snappy) { scroller.scrollTo(Self.roundAnchor, anchor: .top) }
                }) { start in
                    RoundCounterView(players: game.players,
                                     roundNumber: activeRound,
                                     draft: activeDraft,
                                     startingAt: start.player) { drafts[activeRound] = $0 }
                }
            }
            .background(Color(.systemGroupedBackground))
            .safeAreaInset(edge: .bottom) { actionBar }
            .navigationTitle("QuiddleBot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("End Game Early", systemImage: "flag.checkered", role: .destructive) {
                            confirmEndEarly = true
                        }
                        Button("Start New Game", systemImage: "arrow.counterclockwise", role: .destructive) {
                            confirmNewGame = true
                        }
                    } label: {
                        Label("Menu", systemImage: "ellipsis.circle")
                    }
                }
            }
            .confirmationDialog("End the game early and see final scores?",
                                isPresented: $confirmEndEarly, titleVisibility: .visible) {
                Button("End Game", role: .destructive) { store.endEarly() }
            }
            .confirmationDialog("Start a new game? Current progress will be lost.",
                                isPresented: $confirmNewGame, titleVisibility: .visible) {
                Button("Start New Game", role: .destructive) { store.reset() }
            }
        }
        .sensoryFeedback(.success, trigger: game.rounds.count)
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    private static let roundAnchor = "round"

    /// The main action, pinned above the home indicator. One button walks the round:
    /// Count Hands until everyone has a score, then Next Round.
    private var actionBar: some View {
        let draft = activeDraft
        let round = draft.round(rules: game.rules)
        let uncounted = draft.uncountedPlayers
        return BottomActionBar {
            if let hint = hint(round: round, uncounted: uncounted) {
                Text(hint)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            if !isEditing, let first = uncounted.first {
                Button {
                    startCounting(at: first)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.grid.3x3.fill")
                        Text(uncounted.count == game.players.count
                             ? "Count Hands" : "Count \(game.players[first])'s Hand")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
            } else if isEditing {
                HStack(spacing: 12) {
                    Button("Cancel", action: cancelEdit)
                        .buttonStyle(SecondaryButtonStyle())
                    Button("Save Changes") {
                        if let round { saveEdit(round) }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(round == nil)
                }
            } else {
                Button {
                    if let round { submit(round) }
                } label: {
                    HStack(spacing: 8) {
                        Text(game.isOnFinalRound ? "Finish Game" : "Next Round")
                        Image(systemName: game.isOnFinalRound ? "flag.checkered" : "arrow.right")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(round == nil)
            }
        }
        .animation(.snappy, value: round == nil)
        .animation(.snappy, value: uncounted)
    }

    /// What's still missing, when the button alone doesn't say.
    private func hint(round: Round?, uncounted: [Int]) -> String? {
        if !uncounted.isEmpty {
            if isEditing { return "Count every hand to save." }
            return uncounted.count == game.players.count
                ? "When the round ends, count each player's cards." : nil
        }
        return round == nil ? "Pick each bonus to continue." : nil
    }

    private func startCounting(at player: Int) {
        counting = CountingStart(player: player)
    }

    private func draftBinding(for round: Int) -> Binding<RoundDraft> {
        Binding(
            get: { drafts[round] ?? RoundDraft(playerCount: game.players.count) },
            set: { drafts[round] = $0 })
    }

    private func beginEditing(_ round: Int) {
        guard game.rounds.indices.contains(round - 1) else { return }
        drafts[round] = RoundDraft(from: game.rounds[round - 1])
        store.editingRound = round
    }

    private func submit(_ round: Round) {
        drafts[game.currentRound] = nil
        withAnimation(.snappy) { store.submit(round) }
    }

    private func saveEdit(_ round: Round) {
        guard let editing = store.editingRound else { return }
        drafts[editing] = nil
        withAnimation(.snappy) { store.save(round, forRound: editing) }
    }

    private func cancelEdit() {
        if let editing = store.editingRound { drafts[editing] = nil }
        store.editingRound = nil
    }
}

#if DEBUG
#Preview("Round 4 of 8") {
    let store = GameStore.preview(players: ["Ada", "Ben", "Cy"], rounds: 3)
    return RootView().environment(store)
}
#endif

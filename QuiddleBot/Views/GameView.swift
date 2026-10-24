import SwiftUI

struct GameView: View {
    @Environment(GameStore.self) private var store
    let game: Game

    /// Typed-but-unsubmitted input, keyed by round number, so starting an edit of an
    /// earlier round does not throw away what was typed for the current one.
    @State private var drafts: [Int: RoundDraft] = [:]
    @State private var confirmEndEarly = false
    @State private var confirmNewGame = false

    private var activeRound: Int { store.editingRound ?? game.currentRound }
    private var isEditing: Bool { store.editingRound != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    RoundNavView(game: game, editingRound: store.editingRound, onSelect: beginEditing)
                    ScoreboardView(game: game)
                    RoundEntryView(game: game,
                                   roundNumber: activeRound,
                                   isEditing: isEditing,
                                   draft: draftBinding(for: activeRound),
                                   onSubmit: submit,
                                   onSave: saveEdit,
                                   onCancel: cancelEdit)
                        .id(activeRound)
                    if !game.rounds.isEmpty {
                        HistoryView(game: game, onEdit: beginEditing)
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
            .navigationTitle(title)
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

    private var title: String {
        if let editing = store.editingRound {
            return "Editing Round \(editing)"
        }
        return "Round \(game.currentRound) of \(game.rules.roundCount)"
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
        store.submit(round)
    }

    private func saveEdit(_ round: Round) {
        guard let editing = store.editingRound else { return }
        drafts[editing] = nil
        store.save(round, forRound: editing)
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

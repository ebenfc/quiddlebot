import SwiftUI

/// The round counter: the scorekeeper goes round the table, tapping each player's words and
/// leftover cards. "Next: Ben" moves on; Done hands the round back to the game screen.
struct RoundCounterView: View {
    let players: [String]
    let roundNumber: Int
    var onDone: (RoundDraft) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var session: RoundCountSession
    @State private var confirmDiscard = false
    @State private var askPenalty = false
    @State private var penaltyText = ""
    /// Under 700 pt tall (iPhone SE), the keys and totals shrink so the words stay in view.
    @State private var isCompact = false

    init(players: [String], roundNumber: Int, draft: RoundDraft, startingAt player: Int,
         onDone: @escaping (RoundDraft) -> Void) {
        self.players = players
        self.roundNumber = roundNumber
        self.onDone = onDone
        _session = State(initialValue: RoundCountSession(
            round: draft, cardsDealt: Game.cardsDealt(inRound: roundNumber), startingAt: player))
    }

    private var current: Int { session.current }
    private var name: String { players[current] }
    private var isTyping: Bool { session.entry[current] == .typed }

    var body: some View {
        NavigationStack {
            ScrollViewReader { scroller in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        summary
                            .id(HandScrollTarget.top)
                        if isTyping {
                            typedNote
                        } else {
                            HandEditorView(draft: $session.currentHand)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .animation(.snappy(duration: 0.2), value: session)
                }
                // The keypad covers the lower half, so keep wherever cards are going in view,
                // scrolling only as far as needed; a new player starts at the top.
                .onChange(of: session) { old, new in
                    withAnimation(.snappy) {
                        if old.current != new.current {
                            scroller.scrollTo(HandScrollTarget.top, anchor: .top)
                        } else if new.currentHand.target == .leftovers {
                            scroller.scrollTo(HandScrollTarget.leftovers)
                        } else {
                            scroller.scrollTo(HandScrollTarget.word(new.currentHand.currentWord))
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .safeAreaInset(edge: .bottom) { keypadBar }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if session.hasChanges { confirmDiscard = true } else { dismiss() }
                    }
                }
                ToolbarItem(placement: .principal) { playerStrip }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: finish)
                        .disabled(!session.canLeaveCurrent)
                }
            }
            .confirmationDialog("Discard the hands you counted?",
                                isPresented: $confirmDiscard, titleVisibility: .visible) {
                Button("Discard", role: .destructive) { dismiss() }
            }
            .alert("Lost a challenge", isPresented: $askPenalty) {
                TextField("Points", text: $penaltyText)
                    .keyboardType(.numberPad)
                Button("Subtract") { session.setPenalty(penaltyText) }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("How many points does \(name) lose? It comes off after the zero floor.")
            }
        }
        .fontDesign(.rounded)
        .onGeometryChange(for: Bool.self) { $0.size.height < 700 } action: { isCompact = $0 }
    }

    // MARK: - Players

    /// Everyone at the table: ✓ counted, # typed, a ring on whoever is being counted.
    private var playerStrip: some View {
        HStack(spacing: 8) {
            ForEach(players.indices, id: \.self) { player in
                Button { session.select(player) } label: { stripAvatar(player) }
                    .buttonStyle(.plain)
                    .disabled(player != current && !session.canLeaveCurrent)
                    .accessibilityLabel(stripLabel(player))
                    .accessibilityAddTraits(player == current ? .isSelected : [])
            }
        }
    }

    private func stripAvatar(_ player: Int) -> some View {
        let isCurrent = player == current
        let isCounted = session.round.countedHand(for: player) != nil
        let isTyped = session.round.isTyped(player)
        return PlayerAvatar(name: players[player], index: player, size: 28)
            .padding(3)
            .overlay {
                Circle().strokeBorder(Theme.playerColor(player), lineWidth: isCurrent ? 2.5 : 0)
            }
            .overlay(alignment: .bottomTrailing) {
                if isCounted || isTyped {
                    Image(systemName: isCounted ? "checkmark.circle.fill" : "number.circle.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white, isCounted ? Color.green : Color.gray)
                        .offset(x: 2, y: 2)
                }
            }
            .opacity(isCurrent || isCounted || isTyped ? 1 : 0.5)
    }

    private func stripLabel(_ player: Int) -> String {
        let state = session.round.countedHand(for: player) != nil ? "counted"
            : session.round.isTyped(player) ? "typed" : "not counted yet"
        return "\(players[player]), \(state)"
    }

    // MARK: - Total

    /// Whose hand this is and what it comes to, kept to two lines so the words get the room.
    private var summary: some View {
        VStack(alignment: .leading, spacing: isCompact ? 4 : 8) {
            HStack(spacing: 10) {
                PlayerAvatar(name: name, index: current, size: isCompact ? 28 : 34)
                Text("\(name)'s hand")
                    .font(.headline)
                    .lineLimit(1)
                Spacer(minLength: 0)
                optionsMenu
            }
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(scoreText)
                    .font(.system(size: isCompact ? 30 : 36, weight: .bold, design: .rounded).monospacedDigit())
                    .contentTransition(.numericText())
                VStack(alignment: .leading, spacing: 2) {
                    Text(breakdown)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if session.round.penalty(for: current) > 0 {
                        Text("−\(session.round.penalty(for: current)) lost challenge")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                }
                Spacer(minLength: 0)
                if !isTyping { cardCount }
            }
        }
        .card(padding: isCompact ? 12 : 16)
        .accessibilityElement(children: .contain)
    }

    private var scoreText: String {
        if isTyping {
            guard let score = session.round.score(for: current) else { return "–" }
            return score.formatted()
        }
        return session.currentHand.preview.score.formatted()
    }

    private var breakdown: String {
        if isTyping { return "typed score" }
        let hand = session.currentHand.preview
        return "words \(hand.wordPoints) − leftovers \(hand.leftoverPoints)"
    }

    /// "6 of 6": a quick check that nothing was missed. Only a hint, never a block.
    private var cardCount: some View {
        let draft = session.currentHand
        let isRight = draft.placedCount == draft.cardsDealt
        return Label {
            Text("\(draft.placedCount) of \(draft.cardsDealt)").monospacedDigit()
        } icon: {
            Image(systemName: isRight ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(isRight ? Color.green : draft.isEmpty ? Color.secondary : Color.orange)
        .accessibilityLabel("\(draft.placedCount) of \(draft.cardsDealt) cards")
    }

    /// The rare cases, kept out of the way: typing a score, and a lost challenge.
    private var optionsMenu: some View {
        let penalty = session.round.penalty(for: current)
        return Menu {
            if isTyping {
                Button("Count cards instead", systemImage: "square.grid.3x3") { session.countInstead() }
            } else {
                Button("Type a score instead", systemImage: "number") { session.typeInstead() }
            }
            Button(penalty == 0 ? "Lost a challenge…" : "Change challenge penalty…", systemImage: "flag") {
                penaltyText = penalty == 0 ? "" : String(penalty)
                askPenalty = true
            }
            if penalty > 0 {
                Button("Remove challenge penalty", systemImage: "flag.slash", role: .destructive) {
                    session.setPenalty("")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("More options for \(name)")
    }

    private var typedNote: some View {
        Label {
            Text("Type \(name)'s score on the pad below. With a typed score, the bonuses for this round are picked by hand.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } icon: {
            Image(systemName: "number")
                .foregroundStyle(.secondary)
        }
        .card()
    }

    // MARK: - Keypad and Next

    private var keypadBar: some View {
        BottomActionBar {
            if isTyping {
                NumberPadView(isNegative: session.round.isNegative[current],
                              onDigit: { session.typeDigit($0) },
                              onDelete: { session.deleteDigit() },
                              onToggleSign: { session.toggleSign() },
                              keyHeight: isCompact ? 40 : 44)
                    .padding(.vertical, 4)
            } else {
                Picker("Cards go to", selection: $session.currentHand.target) {
                    Text("Words").tag(HandDraft.Target.words)
                    Text("Leftovers").tag(HandDraft.Target.leftovers)
                }
                .pickerStyle(.segmented)

                CardKeypadView(onCard: { session.currentHand.add($0) },
                               onNextWord: { session.currentHand.nextWord() },
                               onBackspace: { session.currentHand.backspace() },
                               keyHeight: isCompact ? 40 : 44)
                    .padding(.vertical, 4)
            }

            Button {
                if session.nextPlayer != nil { session.advance() } else { finish() }
            } label: {
                HStack(spacing: 8) {
                    if let next = session.nextPlayer {
                        Text("Next: \(players[next])")
                        Image(systemName: "arrow.right")
                    } else {
                        Text("Done")
                        Image(systemName: "checkmark")
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!session.canLeaveCurrent)
        }
    }

    private func finish() {
        onDone(session.finish())
        dismiss()
    }
}

#if DEBUG
#Preview("Counting a round") {
    var draft = RoundDraft(playerCount: 3)
    draft.apply(Hand(words: [Word(["QU", "I", "Z"]), Word(["TH", "E"])], leftovers: ["R"]), for: 0)
    return RoundCounterView(players: ["Ada", "Ben", "Cy"], roundNumber: 4, draft: draft,
                            startingAt: 1, onDone: { _ in })
}
#endif

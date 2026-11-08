import SwiftUI

/// The round counter: the scorekeeper goes round the table, tapping each player's words and
/// leftover cards. "Next: Ben" moves on; Done hands the round back to the game screen.
struct RoundCounterView: View {
    let players: [String]
    let roundNumber: Int
    /// The scores committed so far, handed out as the app goes to the background so a
    /// half-counted round survives iOS closing the app.
    var onSnapshot: (RoundDraft) -> Void
    var onDone: (RoundDraft) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var session: RoundCountSession
    @State private var confirmDiscard = false
    @State private var askPenalty = false
    @State private var penaltyText = ""
    /// Under 700 pt tall (iPhone SE), the keys and totals shrink so the words stay in view.
    @State private var isCompact = false
    /// The built-in word list, once it has loaded. Until then the rows show no verdicts.
    @State private var wordList: WordList?

    init(players: [String], roundNumber: Int, draft: RoundDraft, startingAt player: Int,
         onSnapshot: @escaping (RoundDraft) -> Void = { _ in },
         onDone: @escaping (RoundDraft) -> Void) {
        self.players = players
        self.roundNumber = roundNumber
        self.onSnapshot = onSnapshot
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
                    VStack(alignment: .leading, spacing: DS.Space.l) {
                        summary
                            .id(HandScrollTarget.top)
                        if isTyping {
                            typedNote
                        } else {
                            HandEditorView(draft: $session.currentHand, wordList: wordList)
                        }
                    }
                    .padding(.horizontal, DS.Space.screen)
                    .padding(.vertical, DS.Space.m)
                    .animation(DS.Motion.quick, value: session)
                }
                // The keypad covers the lower half, so keep wherever cards are going in view,
                // scrolling only as far as needed; a new player starts at the top.
                .onChange(of: session) { old, new in
                    withAnimation(DS.Motion.movement(reduceMotion: reduceMotion)) {
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
            .dsCanvas()
            .bottomActionBar(solid: true) { keypadBar }
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
        .tint(DS.Colors.accent)
        .onGeometryChange(for: Bool.self) { $0.size.height < DS.Size.compactHeight } action: { isCompact = $0 }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { onSnapshot(session.round) }
        }
        .task {
            // The first counter ever opened pays the load once, off the main actor; after
            // that `WordList.shared` is a plain static read.
            wordList = await Task.detached(priority: .userInitiated) { WordList.shared }.value
        }
    }

    // MARK: - Players

    /// Everyone at the table: ✓ counted, # typed, a ring on whoever is being counted.
    private var playerStrip: some View {
        HStack(spacing: DS.Space.xxs) {
            ForEach(players.indices, id: \.self) { player in
                Button { session.select(player) } label: {
                    stripAvatar(player)
                        .frame(minWidth: DS.Size.minTap, minHeight: DS.Size.minTap)
                        .contentShape(Rectangle())
                }
                    .buttonStyle(.plain)
                    .disabled(player != current && !session.canLeaveCurrent)
                    .accessibilityLabel(stripLabel(player))
                    .accessibilityAddTraits(player == current ? .isSelected : [])
                    .accessibilityShowsLargeContentViewer {
                        Label(stripLabel(player), systemImage: "person.circle")
                    }
            }
        }
    }

    private func stripAvatar(_ player: Int) -> some View {
        let isCurrent = player == current
        let isCounted = session.round.countedHand(for: player) != nil
        let isTyped = session.round.isTyped(player)
        return PlayerAvatar(seat: player, in: players, size: DS.Avatar.strip)
            .padding(3)
            .overlay {
                Circle().strokeBorder(DS.Colors.player(player), lineWidth: isCurrent ? 2.5 : 0)
            }
            .overlay(alignment: .bottomTrailing) {
                if isCounted || isTyped {
                    Image(systemName: isCounted ? "checkmark.circle.fill" : "number.circle.fill")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white, isCounted ? DS.Colors.positive : Color.gray)
                        .symbolEffect(.bounce, value: isCounted)
                        .offset(x: 2, y: 2)
                }
            }
            .opacity(isCurrent || isCounted || isTyped ? 1 : DS.Opacity.dimmed)
    }

    private func stripLabel(_ player: Int) -> String {
        let state = session.round.countedHand(for: player) != nil ? "counted"
            : session.round.isTyped(player) ? "typed" : "not counted yet"
        return "\(players[player]), \(state)"
    }

    // MARK: - Total

    /// Whose hand this is and what it comes to, kept to two lines so the words get the room.
    private var summary: some View {
        VStack(alignment: .leading, spacing: isCompact ? DS.Space.xs : DS.Space.s) {
            HStack(spacing: DS.Space.m) {
                PlayerAvatar(seat: current, in: players, size: isCompact ? DS.Avatar.strip : DS.Avatar.regular)
                Text("\(name)'s hand")
                    .font(DS.Typography.rowTitle)
                    .lineLimit(1)
                Spacer(minLength: 0)
                optionsMenu
            }
            HStack(alignment: .firstTextBaseline, spacing: DS.Space.m) {
                ScoreNumeral(score, style: isCompact ? .large : .hero)
                VStack(alignment: .leading, spacing: DS.Space.xxs) {
                    Text(breakdown)
                        .font(DS.Typography.detail)
                        .foregroundStyle(.secondary)
                    if session.round.penalty(for: current) > 0 {
                        Label("−\(session.round.penalty(for: current)) lost challenge", systemImage: "flag.fill")
                            .font(DS.Typography.caption.weight(.semibold))
                            .foregroundStyle(DS.Colors.warning)
                    }
                }
                Spacer(minLength: 0)
                if !isTyping { cardCount }
            }
        }
        .dsCard(padding: isCompact ? DS.Space.m : DS.Space.l)
        // The hand total is the one number read from across the table; past this size the
        // card would push the words off an iPhone SE.
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .accessibilityElement(children: .contain)
    }

    /// nil while a typed score is still blank.
    private var score: Int? {
        isTyping ? session.round.score(for: current) : session.currentHand.preview.score
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
        .font(DS.Typography.label)
        .foregroundStyle(isRight ? DS.Colors.positive : draft.isEmpty ? Color.secondary : DS.Colors.warning)
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
                .frame(width: DS.Size.minTap, height: DS.Size.minTap)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("More options for \(name)")
    }

    private var typedNote: some View {
        NoticeBanner(text: "Type \(name)'s score on the pad below. With a typed score, the bonuses for this round are picked by hand.",
                     systemImage: "number")
    }

    // MARK: - Keypad and Next

    @ViewBuilder
    private var keypadBar: some View {
        if isTyping {
            NumberPadView(isNegative: session.round.isNegative[current],
                          onDigit: { session.typeDigit($0) },
                          onDelete: { session.deleteDigit() },
                          onToggleSign: { session.toggleSign() },
                          keyHeight: isCompact ? DS.Size.keyCompact : DS.Size.key)
                .padding(.vertical, DS.Space.xs)
        } else {
            Picker("Cards go to", selection: $session.currentHand.target) {
                Text("Words").tag(HandDraft.Target.words)
                Text("Leftovers").tag(HandDraft.Target.leftovers)
            }
            .pickerStyle(.segmented)

            CardKeypadView(onCard: { session.currentHand.add($0) },
                           onNextWord: { session.currentHand.nextWord() },
                           onBackspace: { session.currentHand.backspace() },
                           keyHeight: isCompact ? DS.Size.keyCompact : DS.Size.key)
                .padding(.vertical, DS.Space.xs)
        }

        Button {
            if session.nextPlayer != nil { session.advance() } else { finish() }
        } label: {
            HStack(spacing: DS.Space.s) {
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

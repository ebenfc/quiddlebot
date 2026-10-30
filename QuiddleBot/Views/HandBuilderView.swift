import SwiftUI

/// The word calculator: one player taps the cards of each word they laid down and the cards
/// they could not use, and gets their hand score. Shown as a sheet from the round entry.
struct HandBuilderView: View {
    let playerName: String
    let player: Int
    let roundNumber: Int
    var onUse: (Hand) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: HandDraft
    @State private var confirmDiscard = false
    /// What the sheet opened with, so Cancel and swipe-down only ask when something changed.
    private let original: HandDraft

    init(playerName: String, player: Int, roundNumber: Int, hand: Hand?,
         onUse: @escaping (Hand) -> Void) {
        self.playerName = playerName
        self.player = player
        self.roundNumber = roundNumber
        self.onUse = onUse
        let start = HandDraft(hand: hand, cardsDealt: Game.cardsDealt(inRound: roundNumber))
        original = start
        _draft = State(initialValue: start)
    }

    private var hasChanges: Bool { draft != original }

    private enum ScrollTarget: Hashable {
        case word(Int)
        case leftovers
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { scroller in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        totals
                        ForEach(shortWords, id: \.self, content: shortWordNote)
                        wordsSection
                        leftoversSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .animation(.snappy(duration: 0.2), value: draft)
                }
                // The keypad covers the lower half, so keep wherever cards are going in view.
                // No anchor: scroll only as far as needed, so the total stays put when it can.
                .onChange(of: draft) {
                    withAnimation(.snappy) {
                        if draft.target == .leftovers {
                            scroller.scrollTo(ScrollTarget.leftovers)
                        } else {
                            scroller.scrollTo(ScrollTarget.word(draft.currentWord))
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .safeAreaInset(edge: .bottom) { keypadBar }
            .navigationTitle("\(playerName)'s hand")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasChanges { confirmDiscard = true } else { dismiss() }
                    }
                }
            }
            .confirmationDialog("Discard the cards you entered?",
                                isPresented: $confirmDiscard, titleVisibility: .visible) {
                Button("Discard", role: .destructive) { dismiss() }
            }
        }
        .fontDesign(.rounded)
        // A stray swipe down must not throw away a counted hand.
        .interactiveDismissDisabled(hasChanges)
    }

    // MARK: - Totals

    private var totals: some View {
        let hand = draft.preview
        return HStack(alignment: .center, spacing: 12) {
            PlayerAvatar(name: playerName, index: player, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(hand.score, format: .number)
                    .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
                    .contentTransition(.numericText(value: Double(hand.score)))
                Text("Words \(hand.wordPoints) − leftovers \(hand.leftoverPoints)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            cardCount
        }
        .card()
        .accessibilityElement(children: .combine)
    }

    /// "6 of 6 cards": a quick check that nothing was missed. Only a hint, never a block.
    private var cardCount: some View {
        let isRight = draft.placedCount == draft.cardsDealt
        return VStack(alignment: .trailing, spacing: 2) {
            Label {
                Text("\(draft.placedCount) of \(draft.cardsDealt)")
                    .monospacedDigit()
            } icon: {
                Image(systemName: isRight ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isRight ? Color.green : draft.isEmpty ? Color.secondary : Color.orange)
            Text("cards in round \(roundNumber)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Words

    private var shortWords: [Int] {
        draft.issues.compactMap { issue in
            if case .shortWord(let index) = issue { index } else { nil }
        }
    }

    private func shortWordNote(_ index: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text("“\(draft.words[index].joined())” is one card. Words need at least two.")
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Move to leftovers") { draft.moveWordToLeftovers(index) }
                .font(.subheadline.weight(.semibold))
                .buttonStyle(.borderless)
        }
        .padding(14)
        .background(Color.orange.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var wordsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Words", points: draft.preview.wordPoints)
            ForEach(draft.words.indices, id: \.self, content: wordRow)
        }
        .card()
    }

    /// The first word with the most letters gets the star: it is what Longest Word compares.
    private var longestWordIndex: Int? {
        let lengths = draft.words.map { $0.count >= 2 ? Word($0).letters : 0 }
        guard let most = lengths.max(), most > 0 else { return nil }
        return lengths.firstIndex(of: most)
    }

    private func wordRow(_ index: Int) -> some View {
        let faces = draft.words[index]
        let word = Word(faces)
        let isCurrent = draft.target == .words && draft.currentWord == index

        return HStack(spacing: 10) {
            if faces.isEmpty {
                Text(draft.words.count == 1 ? "Tap the cards of a word" : "Next word")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(faces.indices, id: \.self) { position in
                            Button {
                                draft.removeCard(word: index, at: position)
                            } label: {
                                CardTile(face: faces[position])
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(faces[position])
                            .accessibilityHint("Removes this card")
                        }
                    }
                }
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(word.points)")
                        .font(.headline.monospacedDigit())
                    if index == longestWordIndex {
                        Text("★ \(word.letters) letters")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Theme.gold)
                    } else {
                        Text("\(word.letters) letters")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .fixedSize()
            }
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(isCurrent ? Color.accentColor : Color(.separator).opacity(0.5),
                              style: StrokeStyle(lineWidth: isCurrent ? 2 : 1, dash: faces.isEmpty ? [5, 4] : []))
        }
        .contentShape(Rectangle())
        .onTapGesture { draft.selectWord(index) }
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
        .id(ScrollTarget.word(index))
    }

    // MARK: - Leftovers

    private var leftoversSection: some View {
        let isTarget = draft.target == .leftovers
        return VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Leftovers", points: -draft.preview.leftoverPoints)
            if draft.leftovers.isEmpty {
                Text(isTarget ? "Tap the cards you couldn't use" : "Cards you couldn't use go here")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(draft.leftovers.indices, id: \.self) { position in
                            Button {
                                draft.removeLeftover(at: position)
                            } label: {
                                CardTile(face: draft.leftovers[position], tint: .red)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(draft.leftovers[position])
                            .accessibilityHint("Removes this card")
                        }
                    }
                }
            }
        }
        .card()
        .overlay {
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .strokeBorder(Color.accentColor, lineWidth: isTarget ? 2 : 0)
        }
        .contentShape(Rectangle())
        .onTapGesture { draft.target = .leftovers }
        .id(ScrollTarget.leftovers)
    }

    private func sectionHeader(_ title: String, points: Int) -> some View {
        HStack {
            Text(title).font(.headline)
            Spacer()
            Text(points, format: .number.sign(strategy: .always(includingZero: false)))
                .font(.headline.monospacedDigit())
                .foregroundStyle(points < 0 ? Color.red : Color.secondary)
        }
    }

    // MARK: - Keypad

    private var keypadBar: some View {
        BottomActionBar {
            Picker("Cards go to", selection: $draft.target) {
                Text("Words").tag(HandDraft.Target.words)
                Text("Leftovers").tag(HandDraft.Target.leftovers)
            }
            .pickerStyle(.segmented)

            CardKeypadView(onCard: { draft.add($0) },
                           onNextWord: { draft.nextWord() },
                           onBackspace: { draft.backspace() })
                .padding(.vertical, 4)

            Button {
                if let hand = draft.hand {
                    onUse(hand)
                    dismiss()
                }
            } label: {
                Text(draft.hand.map { "Use \($0.score.formatted())" } ?? "Use")
                    .contentTransition(.numericText())
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(draft.hand == nil)
        }
    }
}

#if DEBUG
#Preview("Counting a hand") {
    Color.clear.sheet(isPresented: .constant(true)) {
        HandBuilderView(playerName: "Ada", player: 0, roundNumber: 4,
                        hand: Hand(words: [Word(["QU", "I", "Z"]), Word(["TH", "E"])], leftovers: ["R"]),
                        onUse: { _ in })
    }
}
#endif

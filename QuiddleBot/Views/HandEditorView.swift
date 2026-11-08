import SwiftUI

/// Scroll anchors inside the round counter, so it can keep the word being built in view.
enum HandScrollTarget: Hashable {
    case top
    case word(Int)
    case leftovers
}

/// One player's cards in the round counter: a note for any one-card word, the words as
/// rows of tiles with a word-check mark, and the leftover tray. The keypad lives in
/// `RoundCounterView`.
struct HandEditorView: View {
    @Binding var draft: HandDraft
    /// The built-in word list; nil (still loading, or missing) shows no marks at all.
    var wordList: WordList? = nil

    /// The word whose options sheet is open, by row.
    nonisolated private struct WordReview: Identifiable {
        let index: Int
        var id: Int { index }
    }

    @State private var reviewing: WordReview?

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.l) {
            ForEach(shortWords, id: \.self, content: shortWordNote)
            wordsSection
            leftoversSection
        }
        .sheet(item: $reviewing) { review in
            if let verdict = verdict(for: review.index) {
                WordVerdictSheet(word: Word(draft.words[review.index],
                                            tableAccepted: draft.isTableAccepted(review.index)),
                                 verdict: verdict,
                                 onAccept: { draft.setTableAccepted($0, forWord: review.index) })
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Word check

    /// The mark for a row, or nil for a one-card word or while the list hasn't loaded.
    private func verdict(for index: Int) -> WordVerdict? {
        guard let wordList, draft.words.indices.contains(index), draft.words[index].count >= 2 else {
            return nil
        }
        let word = Word(draft.words[index], tableAccepted: draft.isTableAccepted(index))
        return WordVerdict(word: word, isListed: wordList.contains(word.text))
    }

    // MARK: - Words

    private var shortWords: [Int] {
        draft.issues.compactMap { issue in
            if case .shortWord(let index) = issue { index } else { nil }
        }
    }

    private func shortWordNote(_ index: Int) -> some View {
        NoticeBanner(text: "“\(draft.words[index].joined())” is one card. Words need at least two.",
                     systemImage: "exclamationmark.triangle.fill",
                     tone: .warning,
                     actionTitle: "Move to leftovers") { draft.moveWordToLeftovers(index) }
    }

    private var wordsSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.s) {
            sectionHeader("Words", points: draft.preview.wordPoints)
            ForEach(draft.words.indices, id: \.self, content: wordRow)
        }
        .dsCard()
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

        return HStack(spacing: DS.Space.s) {
            if faces.isEmpty {
                Text(draft.words.count == 1 ? "Tap the cards of a word" : "Next word")
                    .font(DS.Typography.detail)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: DS.Size.tile, alignment: .leading)
                    .accessibilityAddTraits(isCurrent ? [] : .isButton)
            } else {
                // Leading, not a third line on the trailing side: the rows are tile-high and
                // the tiles already scroll, so a 44 pt target here costs nothing that matters.
                if let verdict = verdict(for: index) {
                    WordVerdictBadge(verdict: verdict) { reviewing = WordReview(index: index) }
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.Space.xs) {
                        ForEach(faces.indices, id: \.self) { position in
                            Button {
                                draft.removeCard(word: index, at: position)
                            } label: {
                                LetterTile(face: faces[position])
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(faces[position])
                            .accessibilityHint("Removes this card")
                            // Selecting a row is a tap on its background, which VoiceOver
                            // can't reach past the tiles; offer it on every tile instead.
                            .accessibilityAction(named: "Add cards to this word") { draft.selectWord(index) }
                        }
                    }
                    .padding(.vertical, DS.Space.xxs)
                }
                VStack(alignment: .trailing, spacing: DS.Space.xxs) {
                    ScoreNumeral(word.points, style: .small)
                    if index == longestWordIndex {
                        Label("\(word.letters) letters", systemImage: "star.fill")
                            .labelStyle(.titleAndIcon)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(DS.Colors.bonusText)
                            .accessibilityLabel("Longest word, \(word.letters) letters")
                    } else {
                        Text("\(word.letters) letters")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .fixedSize()
            }
        }
        .padding(DS.Space.s)
        .background {
            RoundedRectangle.ds(DS.Radius.control)
                .strokeBorder(isCurrent ? DS.Colors.accent : DS.Colors.outline,
                              style: StrokeStyle(lineWidth: isCurrent ? 2 : 1, dash: faces.isEmpty ? [5, 4] : []))
        }
        .contentShape(Rectangle())
        .onTapGesture { draft.selectWord(index) }
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
        .id(HandScrollTarget.word(index))
    }

    // MARK: - Leftovers

    private var leftoversSection: some View {
        let isTarget = draft.target == .leftovers
        return VStack(alignment: .leading, spacing: DS.Space.s) {
            sectionHeader("Leftovers", points: -draft.preview.leftoverPoints)
            if draft.leftovers.isEmpty {
                Text(isTarget ? "Tap the cards you couldn't use" : "Cards you couldn't use go here")
                    .font(DS.Typography.detail)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: DS.Size.tile, alignment: .leading)
                    .accessibilityAddTraits(isTarget ? [] : .isButton)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.Space.xs) {
                        ForEach(draft.leftovers.indices, id: \.self) { position in
                            Button {
                                draft.removeLeftover(at: position)
                            } label: {
                                LetterTile(face: draft.leftovers[position], tone: .leftover)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(draft.leftovers[position])
                            .accessibilityHint("Removes this card")
                            .accessibilityAction(named: "Put cards in leftovers") { draft.target = .leftovers }
                        }
                    }
                    .padding(.vertical, DS.Space.xxs)
                }
            }
        }
        .dsCard()
        .selectionOutline(isTarget, radius: DS.Radius.card)
        .contentShape(Rectangle())
        .onTapGesture { draft.target = .leftovers }
        .id(HandScrollTarget.leftovers)
    }

    private func sectionHeader(_ title: String, points: Int) -> some View {
        HStack {
            Text(title)
                .font(DS.Typography.rowTitle)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Text(points, format: .number.sign(strategy: .always(includingZero: false)))
                .font(ScoreStyle.small.font)
                .foregroundStyle(points < 0 ? DS.Colors.negative : Color.secondary)
        }
    }
}

import SwiftUI

/// Scroll anchors inside the round counter, so it can keep the word being built in view.
enum HandScrollTarget: Hashable {
    case top
    case word(Int)
    case leftovers
}

/// One player's cards in the round counter: a note for any one-card word, the words as
/// rows of tiles, and the leftover tray. The keypad lives in `RoundCounterView`.
struct HandEditorView: View {
    @Binding var draft: HandDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(shortWords, id: \.self, content: shortWordNote)
            wordsSection
            leftoversSection
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
        .id(HandScrollTarget.word(index))
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
        .id(HandScrollTarget.leftovers)
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
}

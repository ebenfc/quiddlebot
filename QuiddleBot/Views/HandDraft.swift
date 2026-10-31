import Foundation

/// The word calculator's working copy of one player's hand, before it becomes a `Hand`.
/// Every keypad tap is one of these methods, so the editing rules are unit-tested.
struct HandDraft: Equatable {
    /// Where the next tapped card goes.
    enum Target: Hashable {
        case words
        case leftovers
    }

    enum Issue: Equatable {
        /// A word of one card. No legal word is one card, so this blocks Use.
        case shortWord(index: Int)
        /// More or fewer cards than the round deals. Only a warning: a lost challenge can change it.
        case cardCount(placed: Int, dealt: Int)
    }

    /// Each word as card faces. Only the current word may be empty: it is the one being built.
    private(set) var words: [[String]]
    private(set) var leftovers: [String]
    private(set) var currentWord: Int
    /// Words the table ruled good although the built-in list lacks them, as they read ("ZA").
    /// Keyed by text, not position, so the mark survives rows moving and lifts itself when
    /// the cards change: a ruling on ZA says nothing about ZAP.
    private(set) var acceptedWords: Set<String>
    var target: Target = .words
    let cardsDealt: Int

    /// Starts from a saved hand (to recount it) or from nothing, with an empty word ready.
    init(hand: Hand?, cardsDealt: Int) {
        words = (hand?.words.map(\.faces) ?? []) + [[]]
        leftovers = hand?.leftovers ?? []
        currentWord = words.count - 1
        acceptedWords = Set(hand?.words.filter(\.tableAccepted).map(\.text) ?? [])
        self.cardsDealt = cardsDealt
    }

    // MARK: - Keypad

    mutating func add(_ face: String) {
        switch target {
        case .words: words[currentWord].append(face)
        case .leftovers: leftovers.append(face)
        }
    }

    /// Like a space bar: moves on to a fresh word. Does nothing while the current word is empty.
    mutating func nextWord() {
        target = .words
        guard !words[currentWord].isEmpty else { return }
        if words.last?.isEmpty != true { words.append([]) }
        currentWord = words.count - 1
        dropEmptyWords()
    }

    /// Removes the last card where cards are going. In an empty word it steps back into the
    /// previous word; in an empty leftover tray it goes back to the words.
    mutating func backspace() {
        switch target {
        case .leftovers:
            if leftovers.isEmpty {
                target = .words
            } else {
                leftovers.removeLast()
            }
        case .words:
            if !words[currentWord].isEmpty {
                words[currentWord].removeLast()
            } else if currentWord > 0 {
                words.remove(at: currentWord)
                currentWord -= 1
            }
        }
    }

    // MARK: - Fixing mistakes

    /// Tap a word to add more cards to it.
    mutating func selectWord(_ index: Int) {
        guard words.indices.contains(index) else { return }
        target = .words
        currentWord = index
        dropEmptyWords()
    }

    mutating func removeCard(word: Int, at position: Int) {
        guard words.indices.contains(word), words[word].indices.contains(position) else { return }
        words[word].remove(at: position)
        dropEmptyWords()
    }

    mutating func removeLeftover(at position: Int) {
        guard leftovers.indices.contains(position) else { return }
        leftovers.remove(at: position)
    }

    /// The fix for a one-card "word": those cards were really left over.
    mutating func moveWordToLeftovers(_ index: Int) {
        guard words.indices.contains(index) else { return }
        leftovers += words[index]
        words[index] = []
        dropEmptyWords()
    }

    // MARK: - Word check

    /// Whether the table has ruled this word good. See `WordVerdict`.
    func isTableAccepted(_ index: Int) -> Bool {
        words.indices.contains(index) && acceptedWords.contains(words[index].joined())
    }

    /// "Table says it's good", or taking that back. A one-card word is never a word.
    mutating func setTableAccepted(_ accepted: Bool, forWord index: Int) {
        guard words.indices.contains(index), words[index].count >= 2 else { return }
        let text = words[index].joined()
        if accepted {
            acceptedWords.insert(text)
        } else {
            acceptedWords.remove(text)
        }
    }

    /// Keeps "only the current word may be empty" true, and keeps `currentWord` pointing at
    /// the same word as the ones before it disappear.
    private mutating func dropEmptyWords() {
        var index = words.count - 1
        while index >= 0 {
            if words[index].isEmpty && index != currentWord {
                words.remove(at: index)
                if index < currentWord { currentWord -= 1 }
            }
            index -= 1
        }
    }

    // MARK: - Results

    var placedCount: Int { words.reduce(0) { $0 + $1.count } + leftovers.count }

    var isEmpty: Bool { placedCount == 0 }

    /// The hand as it stands, even with a mistake in it, for the running totals.
    var preview: Hand {
        Hand(words: words.filter { !$0.isEmpty }
                         .map { Word($0, tableAccepted: acceptedWords.contains($0.joined())) },
             leftovers: leftovers)
    }

    var issues: [Issue] {
        var issues: [Issue] = words.indices
            .filter { words[$0].count == 1 }
            .map { Issue.shortWord(index: $0) }
        if !isEmpty && placedCount != cardsDealt {
            issues.append(.cardCount(placed: placedCount, dealt: cardsDealt))
        }
        return issues
    }

    /// The hand to use, or nil while there is nothing to use or a word is one card long.
    var hand: Hand? {
        let blocked = issues.contains { if case .shortWord = $0 { true } else { false } }
        return isEmpty || blocked ? nil : preview
    }
}

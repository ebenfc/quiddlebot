import Foundation

/// One word laid down, as the cards it was made from, in order: ["QU", "I", "Z"].
/// Faces, not letters: a two-letter card is one card worth its own printed value.
nonisolated struct Word: Codable, Equatable, Hashable, Sendable {
    var faces: [String]
    /// The table ruled this word good although the built-in word list lacks it. A note on
    /// the receipt, nothing more: scoring never reads it.
    var tableAccepted: Bool

    // Two inits rather than one with a default: `map(Word.init)` in HandDraft and the tests
    // takes an unapplied reference, and that never fills in a default argument.
    init(_ faces: [String]) {
        self.faces = faces
        tableAccepted = false
    }

    init(_ faces: [String], tableAccepted: Bool) {
        self.faces = faces
        self.tableAccepted = tableAccepted
    }

    nonisolated private enum CodingKeys: String, CodingKey {
        case faces
        case tableAccepted
    }

    /// 1.1 saves have no `tableAccepted`. `try?`, as in `Round.init(from:)`: the store starts
    /// a fresh game when a save fails to load, so a damaged flag must cost only the mark.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        faces = try c.decode([String].self, forKey: .faces)
        tableAccepted = (try? c.decodeIfPresent(Bool.self, forKey: .tableAccepted)) ?? false
    }

    /// Writes the flag only when it is set, so an unmarked word encodes exactly as 1.1 did.
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(faces, forKey: .faces)
        if tableAccepted { try c.encode(true, forKey: .tableAccepted) }
    }

    var points: Int { CardValues.points(ofFaces: faces) }

    /// The word as it reads: "QUIZ" from QU·I·Z.
    var text: String { faces.joined() }

    /// Length for the Longest Word bonus, in letters: TH·E is 3.
    var letters: Int { CardValues.letterCount(ofFaces: faces) }
}

/// One player's hand as counted in the word calculator: the words they laid down and the
/// cards they could not use. `score` is the number they would otherwise have typed.
nonisolated struct Hand: Codable, Equatable, Sendable {
    var words: [Word] = []
    var leftovers: [String] = []

    var wordPoints: Int { words.reduce(0) { $0 + $1.points } }
    var leftoverPoints: Int { CardValues.points(ofFaces: leftovers) }

    /// Word points minus leftovers. May be negative: `Scoring.handTotal` applies the zero floor.
    var score: Int { wordPoints - leftoverPoints }

    /// Letters in this hand's longest word, for the Longest Word bonus. 0 with no words.
    var longestWordLetters: Int { words.map(\.letters).max() ?? 0 }

    /// The first of this hand's longest words, to show why a bonus went where it did.
    var longestWord: Word? { words.first { $0.letters == longestWordLetters } }

    var wordCount: Int { words.count }

    var cardCount: Int { words.reduce(0) { $0 + $1.faces.count } + leftovers.count }
}

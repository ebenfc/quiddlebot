import Foundation

/// One word laid down, as the cards it was made from, in order: ["QU", "I", "Z"].
/// Faces, not letters: a two-letter card is one card worth its own printed value.
nonisolated struct Word: Codable, Equatable, Hashable, Sendable {
    var faces: [String]

    init(_ faces: [String]) {
        self.faces = faces
    }

    var points: Int { CardValues.points(ofFaces: faces) }

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

    var wordCount: Int { words.count }

    var cardCount: Int { words.reduce(0) { $0 + $1.faces.count } + leftovers.count }
}

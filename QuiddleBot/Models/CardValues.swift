import Foundation

/// The 118-card Quiddler deck: face, point value, how many in the deck.
/// Used by the v1.1 word calculator. Values and counts are game mechanics;
/// the card artwork is not reproduced anywhere in this app.
nonisolated enum CardValues {
    nonisolated struct Card: Hashable, Sendable {
        let face: String
        let points: Int
        let count: Int
    }

    static let deck: [Card] = [
        Card(face: "A", points: 2, count: 10),
        Card(face: "B", points: 8, count: 2),
        Card(face: "C", points: 8, count: 2),
        Card(face: "D", points: 5, count: 4),
        Card(face: "E", points: 2, count: 12),
        Card(face: "F", points: 6, count: 2),
        Card(face: "G", points: 6, count: 4),
        Card(face: "H", points: 7, count: 2),
        Card(face: "I", points: 2, count: 8),
        Card(face: "J", points: 13, count: 2),
        Card(face: "K", points: 8, count: 2),
        Card(face: "L", points: 3, count: 4),
        Card(face: "M", points: 5, count: 2),
        Card(face: "N", points: 5, count: 6),
        Card(face: "O", points: 2, count: 8),
        Card(face: "P", points: 6, count: 2),
        Card(face: "Q", points: 15, count: 2),
        Card(face: "R", points: 5, count: 6),
        Card(face: "S", points: 3, count: 4),
        Card(face: "T", points: 3, count: 6),
        Card(face: "U", points: 4, count: 6),
        Card(face: "V", points: 11, count: 2),
        Card(face: "W", points: 10, count: 2),
        Card(face: "X", points: 12, count: 2),
        Card(face: "Y", points: 4, count: 4),
        Card(face: "Z", points: 14, count: 2),
        // Two-letter cards. Each is one card worth its printed value, and two letters long.
        Card(face: "QU", points: 9, count: 2),
        Card(face: "IN", points: 7, count: 2),
        Card(face: "ER", points: 7, count: 2),
        Card(face: "CL", points: 10, count: 2),
        Card(face: "TH", points: 9, count: 2),
    ]

    static let points: [String: Int] = Dictionary(uniqueKeysWithValues: deck.map { ($0.face, $0.points) })

    static let totalCards: Int = deck.reduce(0) { $0 + $1.count }

    /// Length of a word for the Longest Word bonus: counted in letters, so "TH" is 2.
    static func letterCount(ofFaces faces: [String]) -> Int {
        faces.reduce(0) { $0 + $1.count }
    }
}

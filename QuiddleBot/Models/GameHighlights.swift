import Foundation

/// The standout words of a game, from the hands counted card by card.
nonisolated struct GameHighlights: Equatable, Sendable {
    nonisolated struct Pick: Equatable, Sendable {
        let word: Word
        let player: Int
        /// 1-based, like the round pills.
        let round: Int
    }

    /// Most letters (TH counts two), the measure the Longest Word bonus uses.
    let longestWord: Pick
    /// Most points.
    let bestWord: Pick

    /// nil when no round was counted card by card, such as a game entered by typing scores.
    /// A tie goes to the word played first: earlier round, then earlier seat.
    init?(game: Game) {
        var longest: Pick?
        var best: Pick?
        for (index, round) in game.rounds.enumerated() {
            for (player, hand) in round.hands.enumerated() {
                for word in hand?.words ?? [] {
                    let pick = Pick(word: word, player: player, round: index + 1)
                    // Strictly greater, so an equal word later on never takes the spot.
                    if word.letters > longest?.word.letters ?? 0 { longest = pick }
                    if word.points > best?.word.points ?? 0 { best = pick }
                }
            }
        }
        guard let longest, let best else { return nil }
        longestWord = longest
        bestWord = best
    }
}

import Foundation

/// Who received a bonus in a round.
nonisolated enum BonusAward: Codable, Equatable, Hashable, Sendable {
    /// Index into `Game.players`.
    case player(Int)
    /// Two or more players tied, so nobody gets the bonus. That is the official rule.
    case tie
    /// Not chosen yet.
    case unset

    var isChosen: Bool { self != .unset }
}

/// One hand. Every array is indexed by player, in `Game.players` order.
nonisolated struct Round: Codable, Equatable, Sendable {
    /// Word points minus unused-card points, exactly as the scorekeeper typed it. May be negative.
    var scores: [Int]
    /// Points lost to a failed challenge this hand. Zero for almost everyone, almost always.
    var penalties: [Int]
    var longestWord: BonusAward
    var mostWords: BonusAward
    /// The hand each player counted in the word calculator; nil where the score was typed.
    /// A record of how `scores` was reached: scoring itself only ever reads `scores`.
    var hands: [Hand?]

    init(scores: [Int],
         penalties: [Int]? = nil,
         longestWord: BonusAward = .unset,
         mostWords: BonusAward = .unset,
         hands: [Hand?]? = nil) {
        self.scores = scores
        self.penalties = penalties ?? Array(repeating: 0, count: scores.count)
        self.longestWord = longestWord
        self.mostWords = mostWords
        self.hands = hands ?? Array(repeating: nil, count: scores.count)
    }

    /// Saves written before a field existed still load: missing keys take their defaults.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        scores = try c.decode([Int].self, forKey: .scores)
        penalties = try c.decodeIfPresent([Int].self, forKey: .penalties)
            ?? Array(repeating: 0, count: scores.count)
        longestWord = try c.decodeIfPresent(BonusAward.self, forKey: .longestWord) ?? .unset
        mostWords = try c.decodeIfPresent(BonusAward.self, forKey: .mostWords) ?? .unset
        // `try?`, not `try`: the store starts a fresh game when a save fails to load, so a
        // damaged hand must cost only the cards, never the scores.
        if let saved = try? c.decodeIfPresent([Hand?].self, forKey: .hands), saved.count == scores.count {
            hands = saved
        } else {
            hands = Array(repeating: nil, count: scores.count)
        }
    }
}

/// The table's conventions. The defaults are the official rules.
nonisolated struct RuleSet: Codable, Equatable, Sendable {
    var roundCount: Int = 8
    var bonusValue: Int = 10
    var longestWordEnabled: Bool = true
    var mostWordsEnabled: Bool = true
    /// Official: "no player can score less than zero in any hand."
    var floorHandAtZero: Bool = true

    /// Official rules for a table of `playerCount`. Two players use a single bonus
    /// (Longest Word) unless `mostWordsForTwo` turns the second one on.
    static func official(playerCount: Int, mostWordsForTwo: Bool = false) -> RuleSet {
        RuleSet(mostWordsEnabled: playerCount > 2 || mostWordsForTwo)
    }
}

nonisolated struct Game: Codable, Equatable, Sendable {
    var players: [String]
    var rules: RuleSet
    var rounds: [Round] = []
    var isFinished: Bool = false

    /// 1-based number of the hand being entered next.
    var currentRound: Int { rounds.count + 1 }
    var isOnFinalRound: Bool { currentRound >= rules.roundCount }

    /// Cards dealt in `round` under the official 3-to-10 progression.
    static func cardsDealt(inRound round: Int) -> Int { min(round + 2, 10) }
}

import Foundation

/// What the scorekeeper has typed for one round, before it becomes a `Round`.
/// Text fields hold strings; this type turns them into numbers.
struct RoundDraft: Equatable {
    var scoreText: [String]
    var isNegative: [Bool]
    var penaltyText: [String]
    var showsPenalty: [Bool]
    var longestWord: BonusAward = .unset
    var mostWords: BonusAward = .unset

    init(playerCount: Int) {
        scoreText = Array(repeating: "", count: playerCount)
        isNegative = Array(repeating: false, count: playerCount)
        penaltyText = Array(repeating: "", count: playerCount)
        showsPenalty = Array(repeating: false, count: playerCount)
    }

    /// Prefilled from a saved round, for editing.
    init(from round: Round) {
        scoreText = round.scores.map { String(abs($0)) }
        isNegative = round.scores.map { $0 < 0 }
        penaltyText = round.penalties.map { $0 == 0 ? "" : String($0) }
        showsPenalty = round.penalties.map { $0 != 0 }
        longestWord = round.longestWord
        mostWords = round.mostWords
    }

    var playerCount: Int { scoreText.count }

    /// The typed score with its sign applied, or nil while the field is empty.
    func score(for player: Int) -> Int? {
        guard let magnitude = Int(scoreText[player]) else { return nil }
        return isNegative[player] ? -magnitude : magnitude
    }

    func penalty(for player: Int) -> Int {
        Int(penaltyText[player]) ?? 0
    }

    /// Can this draft be submitted?
    ///
    /// Every player needs a typed score: a blank field blocks submission instead of silently
    /// becoming 0, which is the bug the web version had. Each bonus the table plays needs a
    /// pick, a player or "Tie / None"; a bonus the table isn't using never blocks. An open
    /// penalty field left empty counts as 0, so an accidental tap on the flag costs nothing.
    func isComplete(rules: RuleSet) -> Bool {
        let everyScoreTyped = (0..<playerCount).allSatisfy { score(for: $0) != nil }
        guard everyScoreTyped else { return false }
        if rules.longestWordEnabled && !longestWord.isChosen { return false }
        if rules.mostWordsEnabled && !mostWords.isChosen { return false }
        return true
    }

    /// The round to save, or nil while incomplete.
    func round(rules: RuleSet) -> Round? {
        guard isComplete(rules: rules) else { return nil }
        return Round(
            scores: (0..<playerCount).map { score(for: $0) ?? 0 },
            penalties: (0..<playerCount).map { penalty(for: $0) },
            longestWord: rules.longestWordEnabled ? longestWord : .unset,
            mostWords: rules.mostWordsEnabled ? mostWords : .unset)
    }
}

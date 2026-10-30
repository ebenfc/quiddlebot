import Foundation

/// What the scorekeeper has typed for one round, before it becomes a `Round`.
/// Text fields hold strings; this type turns them into numbers.
struct RoundDraft: Equatable {
    var scoreText: [String]
    var isNegative: [Bool]
    var penaltyText: [String]
    var showsPenalty: [Bool]
    /// The scorekeeper's own bonus picks. `.unset` means "follow the cards" when every hand
    /// was counted; read `effectiveLongestWord` / `effectiveMostWords` for what to show.
    var longestWord: BonusAward = .unset
    var mostWords: BonusAward = .unset
    /// Hands built in the word calculator. Read them through `countedHand(for:)`.
    var hands: [Hand?]

    init(playerCount: Int) {
        scoreText = Array(repeating: "", count: playerCount)
        isNegative = Array(repeating: false, count: playerCount)
        penaltyText = Array(repeating: "", count: playerCount)
        showsPenalty = Array(repeating: false, count: playerCount)
        hands = Array(repeating: nil, count: playerCount)
    }

    /// Prefilled from a saved round, for editing.
    init(from round: Round) {
        scoreText = round.scores.map { String(abs($0)) }
        isNegative = round.scores.map { $0 < 0 }
        penaltyText = round.penalties.map { $0 == 0 ? "" : String($0) }
        showsPenalty = round.penalties.map { $0 != 0 }
        hands = round.hands
        // Through the same rule as a tap, so a saved pick that matches the cards keeps
        // following them while the round is being fixed.
        pickLongestWord(round.longestWord)
        pickMostWords(round.mostWords)
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

    // MARK: - Word calculator

    /// The calculator's hand for `player`, but only while the score field still shows its
    /// total. Typing a different number over it means the typed number wins.
    func countedHand(for player: Int) -> Hand? {
        guard let hand = hands[player], score(for: player) == hand.score else { return nil }
        return hand
    }

    var countedHands: [Hand?] { (0..<playerCount).map(countedHand(for:)) }

    /// Fills a player's score from the calculator and keeps the hand that produced it.
    mutating func apply(_ hand: Hand, for player: Int) {
        scoreText[player] = String(abs(hand.score))
        isNegative[player] = hand.score < 0
        hands[player] = hand
    }

    /// Back to "not counted yet": no number and no cards.
    mutating func clearScore(for player: Int) {
        scoreText[player] = ""
        isNegative[player] = false
        hands[player] = nil
    }

    /// Players with no score yet, counted or typed, in seat order.
    var uncountedPlayers: [Int] { (0..<playerCount).filter { score(for: $0) == nil } }

    /// Where "Count hands" starts.
    var firstUncounted: Int? { uncountedPlayers.first }

    /// A player whose score was typed rather than counted.
    func isTyped(_ player: Int) -> Bool {
        score(for: player) != nil && countedHand(for: player) == nil
    }

    // MARK: - Why the cards picked a bonus

    /// Why Longest Word went where it did, or nil until every hand is counted.
    func longestWordReason(names: [String]) -> String? {
        guard let hands = allCounted else { return nil }
        let letters = hands.map(\.longestWordLetters)
        let top = Scoring.topPlayers(of: letters)
        switch top.count {
        case 0: return "Nobody laid down a word"
        case 1: return "\(hands[top[0]].longestWord?.text ?? "") · \(letters[top[0]]) letters"
        default: return "\(Self.list(top, names)) tie at \(letters[top[0]]) letters, so nobody scores"
        }
    }

    /// Why Most Words went where it did, or nil until every hand is counted.
    func mostWordsReason(names: [String]) -> String? {
        guard let hands = allCounted else { return nil }
        let counts = hands.map(\.wordCount)
        let top = Scoring.topPlayers(of: counts)
        guard let most = top.first.map({ counts[$0] }) else { return "Nobody laid down a word" }
        let words = most == 1 ? "1 word" : "\(most) words"
        return top.count == 1 ? words : "\(Self.list(top, names)) tie with \(words), so nobody scores"
    }

    private var allCounted: [Hand]? {
        let hands = countedHands.compactMap { $0 }
        return hands.count == playerCount && playerCount > 0 ? hands : nil
    }

    private static func list(_ players: [Int], _ names: [String]) -> String {
        players.map { names[$0] }.formatted(.list(type: .and))
    }

    var suggestedLongestWord: BonusAward? { Scoring.suggestedLongestWord(for: countedHands) }
    var suggestedMostWords: BonusAward? { Scoring.suggestedMostWords(for: countedHands) }

    /// What the picker shows and what gets saved: the scorekeeper's own pick, else the cards'.
    var effectiveLongestWord: BonusAward {
        longestWord.isChosen ? longestWord : suggestedLongestWord ?? .unset
    }

    var effectiveMostWords: BonusAward {
        mostWords.isChosen ? mostWords : suggestedMostWords ?? .unset
    }

    /// A tap on a bonus chip. Agreeing with the cards keeps following them, so fixing a word
    /// later moves the bonus too; disagreeing is an override that always wins.
    mutating func pickLongestWord(_ award: BonusAward) {
        longestWord = award == suggestedLongestWord ? .unset : award
    }

    mutating func pickMostWords(_ award: BonusAward) {
        mostWords = award == suggestedMostWords ? .unset : award
    }

    // MARK: - Submitting

    /// Can this draft be submitted?
    ///
    /// Every player needs a typed score: a blank field blocks submission instead of silently
    /// becoming 0, which is the bug the web version had. Each bonus the table plays needs a
    /// pick, a player or "Tie / None", made by hand or by the counted cards; a bonus the table
    /// isn't using never blocks. An open penalty field left empty counts as 0, so an
    /// accidental tap on the flag costs nothing.
    func isComplete(rules: RuleSet) -> Bool {
        let everyScoreTyped = (0..<playerCount).allSatisfy { score(for: $0) != nil }
        guard everyScoreTyped else { return false }
        if rules.longestWordEnabled && !effectiveLongestWord.isChosen { return false }
        if rules.mostWordsEnabled && !effectiveMostWords.isChosen { return false }
        return true
    }

    /// The round to save, or nil while incomplete.
    func round(rules: RuleSet) -> Round? {
        guard isComplete(rules: rules) else { return nil }
        return Round(
            scores: (0..<playerCount).map { score(for: $0) ?? 0 },
            penalties: (0..<playerCount).map { penalty(for: $0) },
            longestWord: rules.longestWordEnabled ? effectiveLongestWord : .unset,
            mostWords: rules.mostWordsEnabled ? effectiveMostWords : .unset,
            hands: countedHands)
    }
}

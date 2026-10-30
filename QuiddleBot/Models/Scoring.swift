import Foundation

/// The scoring rules, as pure functions. No UI, no persistence, fully unit-tested.
nonisolated enum Scoring {

    // MARK: - Hand and game totals

    /// Points one player earns in one round, following the official rules in order:
    ///  1. `round.scores[player]` is word points minus unused-card points, as typed.
    ///  2. "No player can score less than zero in any hand": floor it when the rules say so.
    ///  3. A lost challenge subtracts the word's value **after** the floor. docs/rules.md:
    ///     "A lost challenge is the only way a hand can end up negative."
    ///  4. Add whichever bonuses the table plays.
    static func handTotal(round: Round, player: Int, rules: RuleSet) -> Int {
        var cardScore = round.scores[player]
        if rules.floorHandAtZero {
            cardScore = max(cardScore, 0)
        }
        let afterChallenge = cardScore - round.penalties[player]
        return afterChallenge + bonuses(in: round, for: player, rules: rules)
    }

    /// Running total per player across every completed round, in `game.players` order.
    /// A game with no rounds yet is all zeros.
    static func totals(for game: Game) -> [Int] {
        game.players.indices.map { player in
            game.rounds.reduce(0) { sum, round in
                sum + handTotal(round: round, player: player, rules: game.rules)
            }
        }
    }

    // MARK: - Bonuses and standings

    /// +`value` when `award` names `player`, otherwise 0. Ties and unset awards pay nobody.
    static func bonus(for award: BonusAward, player: Int, value: Int) -> Int {
        if case .player(let winner) = award, winner == player { return value }
        return 0
    }

    /// Every bonus `player` earned in `round`, honouring which bonuses the rule set uses.
    /// A two-player table that plays Longest Word only ignores a stray Most Words award.
    static func bonuses(in round: Round, for player: Int, rules: RuleSet) -> Int {
        var total = 0
        if rules.longestWordEnabled {
            total += bonus(for: round.longestWord, player: player, value: rules.bonusValue)
        }
        if rules.mostWordsEnabled {
            total += bonus(for: round.mostWords, player: player, value: rules.bonusValue)
        }
        return total
    }

    nonisolated struct Standing: Equatable, Identifiable, Sendable {
        let player: Int
        let name: String
        let total: Int
        /// Shared rank: two players tied for first are both rank 1 and the next is rank 3.
        let rank: Int
        var id: Int { player }
    }

    /// Players ordered by total, highest first, with shared ranks for ties.
    static func standings(for game: Game) -> [Standing] {
        let totals = totals(for: game)
        let order = totals.indices.sorted { a, b in
            totals[a] > totals[b] || (totals[a] == totals[b] && a < b)
        }
        var result: [Standing] = []
        for (position, player) in order.enumerated() {
            let rank: Int
            if let previous = result.last, previous.total == totals[player] {
                rank = previous.rank
            } else {
                rank = position + 1
            }
            result.append(Standing(player: player, name: game.players[player],
                                   total: totals[player], rank: rank))
        }
        return result
    }

    /// The winner's player index, or nil when the top score is shared.
    static func winner(for game: Game) -> Int? {
        let standings = standings(for: game)
        let leaders = standings.filter { $0.rank == 1 }
        return leaders.count == 1 ? leaders[0].player : nil
    }

    /// The winner's lead over second place, or nil for a tie or a one-player game.
    static func margin(for game: Game) -> Int? {
        let standings = standings(for: game)
        guard winner(for: game) != nil, standings.count > 1 else { return nil }
        return standings[0].total - standings[1].total
    }

    /// Everyone sharing the top total right now. Empty until somebody has scored.
    static func leaders(for game: Game) -> Set<Int> {
        let totals = totals(for: game)
        guard let top = totals.max(), top > 0 else { return [] }
        return Set(totals.indices.filter { totals[$0] == top })
    }

    // MARK: - Word calculator bonus suggestions

    /// Everyone sharing the highest number, in player order. Empty when nobody is above zero
    /// (or there are no players): nobody laid a word, so nobody is in the running.
    static func topPlayers(of values: [Int]) -> [Int] {
        guard let top = values.max(), top > 0 else { return [] }
        return values.indices.filter { values[$0] == top }
    }

    /// Who earns a bonus, given each player's number for it, in player order: letters in
    /// their longest word, or how many words they laid down.
    /// The single highest number wins. A shared top, or nobody above zero, pays nobody (.tie).
    static func soleLeader(of values: [Int]) -> BonusAward {
        // Only a tie for first matters; two players sharing a lower number change nothing.
        let leaders = topPlayers(of: values)
        return leaders.count == 1 ? .player(leaders[0]) : .tie
    }

    /// Longest Word from the counted cards, or nil unless every player's hand was counted:
    /// one typed score means we cannot know that player's words.
    static func suggestedLongestWord(for hands: [Hand?]) -> BonusAward? {
        allCounted(hands).map { soleLeader(of: $0.map(\.longestWordLetters)) }
    }

    /// Most Words from the counted cards, or nil unless every player's hand was counted.
    static func suggestedMostWords(for hands: [Hand?]) -> BonusAward? {
        allCounted(hands).map { soleLeader(of: $0.map(\.wordCount)) }
    }

    private static func allCounted(_ hands: [Hand?]) -> [Hand]? {
        let counted = hands.compactMap { $0 }
        return !hands.isEmpty && counted.count == hands.count ? counted : nil
    }
}

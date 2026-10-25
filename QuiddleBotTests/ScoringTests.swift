import Testing
import Foundation
@testable import QuiddleBot

// Each test here describes one rule from docs/rules.md or one bug the web version had.
// They fail until Scoring.handTotal and Scoring.totals are implemented.

@Suite("Scoring rules")
struct ScoringTests {
    /// Two players, official rules: Longest Word only.
    let twoPlayer = RuleSet.official(playerCount: 2)
    /// Three players, official rules: both bonuses.
    let threePlayer = RuleSet.official(playerCount: 3)

    @Test("A plain hand scores what was typed")
    func plainHand() {
        let round = Round(scores: [12, 7])
        #expect(Scoring.handTotal(round: round, player: 0, rules: twoPlayer) == 12)
        #expect(Scoring.handTotal(round: round, player: 1, rules: twoPlayer) == 7)
    }

    @Test("No hand can score below zero (official rule)")
    func floorAtZero() {
        let round = Round(scores: [-5, 3])
        #expect(Scoring.handTotal(round: round, player: 0, rules: twoPlayer) == 0)
        #expect(Scoring.handTotal(round: round, player: 1, rules: twoPlayer) == 3)
    }

    @Test("The zero floor is a house-rule switch")
    func floorOff() {
        var rules = twoPlayer
        rules.floorHandAtZero = false
        #expect(Scoring.handTotal(round: Round(scores: [-5, 3]), player: 0, rules: rules) == -5)
    }

    @Test("A lost challenge is subtracted after the floor and can go negative")
    func challengePenalty() {
        // docs/rules.md: "A lost challenge is the only way a hand can end up negative."
        let round = Round(scores: [-5, 3], penalties: [8, 0])
        #expect(Scoring.handTotal(round: round, player: 0, rules: twoPlayer) == -8)
        #expect(Scoring.handTotal(round: round, player: 1, rules: twoPlayer) == 3)
    }

    @Test("Longest Word pays its winner the bonus")
    func longestWord() {
        let round = Round(scores: [10, 10], longestWord: .player(1))
        #expect(Scoring.handTotal(round: round, player: 0, rules: twoPlayer) == 10)
        #expect(Scoring.handTotal(round: round, player: 1, rules: twoPlayer) == 20)
    }

    @Test("A tied bonus pays nobody")
    func tiePaysNobody() {
        let round = Round(scores: [10, 10, 10], longestWord: .tie, mostWords: .tie)
        for player in 0..<3 {
            #expect(Scoring.handTotal(round: round, player: player, rules: threePlayer) == 10)
        }
    }

    @Test("Both bonuses can go to one player")
    func bothBonuses() {
        let round = Round(scores: [10, 10, 10], longestWord: .player(2), mostWords: .player(2))
        #expect(Scoring.handTotal(round: round, player: 2, rules: threePlayer) == 30)
        #expect(Scoring.handTotal(round: round, player: 0, rules: threePlayer) == 10)
    }

    @Test("Two players use one bonus: Most Words is ignored unless enabled")
    func twoPlayerSingleBonus() {
        let round = Round(scores: [10, 10], longestWord: .tie, mostWords: .player(0))
        #expect(Scoring.handTotal(round: round, player: 0, rules: twoPlayer) == 10)

        let both = RuleSet.official(playerCount: 2, mostWordsForTwo: true)
        #expect(Scoring.handTotal(round: round, player: 0, rules: both) == 20)
    }

    @Test("The bonus value follows the rule set")
    func customBonusValue() {
        var rules = twoPlayer
        rules.bonusValue = 15
        let round = Round(scores: [0, 0], longestWord: .player(0))
        #expect(Scoring.handTotal(round: round, player: 0, rules: rules) == 15)
    }

    @Test("Totals include every round, including the eighth")
    func eighthRoundCounts() {
        // The web version dropped round 8 from every final score.
        var game = Game(players: ["Ada", "Ben"], rules: twoPlayer)
        for n in 1...8 {
            game.rounds.append(Round(scores: [n, 1], longestWord: .tie))
        }
        #expect(Scoring.totals(for: game) == [36, 8])
    }

    @Test("Totals for an unstarted game are all zero")
    func emptyTotals() {
        let game = Game(players: ["Ada", "Ben", "Cy"], rules: threePlayer)
        #expect(Scoring.totals(for: game) == [0, 0, 0])
    }

    @Test("Editing a round changes the totals")
    func editRecomputes() {
        var game = Game(players: ["Ada", "Ben"], rules: twoPlayer,
                        rounds: [Round(scores: [5, 5]), Round(scores: [5, 5])])
        #expect(Scoring.totals(for: game) == [10, 10])
        game.rounds[0].scores[1] = 20
        #expect(Scoring.totals(for: game) == [10, 25])
    }
}

@Suite("Standings")
struct StandingsTests {
    @Test("Winner, shared ranks, and margin")
    func standings() {
        let game = Game(players: ["Ada", "Ben", "Cy", "Di"], rules: .official(playerCount: 4),
                        rounds: [Round(scores: [30, 20, 20, 5])])
        let standings = Scoring.standings(for: game)
        #expect(standings.map(\.name) == ["Ada", "Ben", "Cy", "Di"])
        #expect(standings.map(\.rank) == [1, 2, 2, 4])
        #expect(Scoring.winner(for: game) == 0)
        #expect(Scoring.margin(for: game) == 10)
    }

    @Test("A tie for first has no winner and no margin")
    func tieForFirst() {
        let game = Game(players: ["Ada", "Ben"], rules: .official(playerCount: 2),
                        rounds: [Round(scores: [12, 12])])
        #expect(Scoring.winner(for: game) == nil)
        #expect(Scoring.margin(for: game) == nil)
        #expect(Scoring.standings(for: game).map(\.rank) == [1, 1])
    }

    @Test("Leaders are everyone sharing the top total")
    func leaders() {
        let game = Game(players: ["Ada", "Ben", "Cy"], rules: .official(playerCount: 3),
                        rounds: [Round(scores: [9, 9, 2])])
        #expect(Scoring.leaders(for: game) == [0, 1])
    }

    @Test("Nobody leads before anyone has scored")
    func noLeadersAtStart() {
        let game = Game(players: ["Ada", "Ben"], rules: .official(playerCount: 2))
        #expect(Scoring.leaders(for: game).isEmpty)
    }
}

@Suite("Persistence")
struct PersistenceTests {
    private func temporaryFile() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: "quiddlebot-test-\(UUID().uuidString).json")
    }

    @Test("A game survives a save and reload")
    func roundTrip() {
        let url = temporaryFile()
        defer { try? FileManager.default.removeItem(at: url) }

        let store = GameStore(fileURL: url)
        store.start(players: ["Ada", "Ben"], rules: .official(playerCount: 2))
        store.submit(Round(scores: [12, 7], longestWord: .player(0)))

        let reloaded = GameStore(fileURL: url)
        #expect(reloaded.game == store.game)
        #expect(reloaded.game?.rounds.count == 1)
    }

    @Test("Submitting the last round finishes the game and keeps that round")
    func finishOnLastRound() {
        let url = temporaryFile()
        defer { try? FileManager.default.removeItem(at: url) }

        let store = GameStore(fileURL: url)
        store.start(players: ["Ada", "Ben"], rules: .official(playerCount: 2))
        for n in 1...8 {
            store.submit(Round(scores: [n, 1], longestWord: .tie))
        }
        #expect(store.game?.isFinished == true)
        #expect(store.game?.rounds.count == 8)

        // And a relaunch lands on the finished game, not back on round 8.
        #expect(GameStore(fileURL: url).game?.isFinished == true)
    }

    @Test("A rematch keeps the players and rules and starts over")
    func rematch() {
        let url = temporaryFile()
        defer { try? FileManager.default.removeItem(at: url) }

        var rules = RuleSet.official(playerCount: 3)
        rules.bonusValue = 15
        let store = GameStore(fileURL: url)
        store.start(players: ["Ada", "Ben", "Cy"], rules: rules)
        for n in 1...8 {
            store.submit(Round(scores: [n, 1, 2], longestWord: .tie, mostWords: .tie))
        }
        #expect(store.game?.isFinished == true)

        store.rematch()
        #expect(store.game?.players == ["Ada", "Ben", "Cy"])
        #expect(store.game?.rules == rules)
        #expect(store.game?.rounds.isEmpty == true)
        #expect(store.game?.isFinished == false)
        #expect(GameStore(fileURL: url).game?.rounds.isEmpty == true)
    }

    @Test("Resetting removes the saved game")
    func resetClearsDisk() {
        let url = temporaryFile()
        let store = GameStore(fileURL: url)
        store.start(players: ["Ada", "Ben"], rules: .official(playerCount: 2))
        #expect(FileManager.default.fileExists(atPath: url.path))
        store.reset()
        #expect(!FileManager.default.fileExists(atPath: url.path))
        #expect(GameStore(fileURL: url).game == nil)
    }

    @Test("A save written before challenge penalties existed still loads")
    func decodesLegacyRound() throws {
        let json = """
        {"scores":[12,7],"longestWord":{"player":{"_0":0}},"mostWords":{"unset":{}}}
        """
        let round = try JSONDecoder().decode(Round.self, from: Data(json.utf8))
        #expect(round.penalties == [0, 0])
        #expect(round.longestWord == .player(0))
        #expect(round.mostWords == .unset)
    }
}

@Suite("Card values")
struct CardValueTests {
    @Test("The deck has 118 cards")
    func deckSize() {
        #expect(CardValues.totalCards == 118)
    }

    @Test("Two-letter cards are worth their printed value and count as two letters")
    func digraphs() {
        #expect(CardValues.points["QU"] == 9)
        #expect(CardValues.points["TH"] == 9)
        #expect(CardValues.points["Q"] == 15)
        #expect(CardValues.letterCount(ofFaces: ["TH", "E"]) == 3)
    }
}

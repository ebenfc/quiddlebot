import Testing
import Foundation
@testable import QuiddleBot

// Count-first round entry: going round the table, the reasons shown for bonuses, and the
// game-over highlights. See docs/word-calculator.md.

/// Shorthand: hand(["QU","I","Z"], ["TH","E"], left: ["R"]).
private func hand(_ words: [String]..., left: [String] = []) -> Hand {
    Hand(words: words.map(Word.init), leftovers: left)
}

/// A fresh session for `players` people in a round that deals 3 cards.
private func session(players: Int = 3, startingAt start: Int = 0,
                     round: RoundDraft? = nil) -> RoundCountSession {
    RoundCountSession(round: round ?? RoundDraft(playerCount: players), cardsDealt: 3,
                      startingAt: start)
}

@Suite("Going round the table")
struct RoundCountSessionTests {
    @Test("Count hands starts at the first player without a score")
    func firstUncounted() {
        var draft = RoundDraft(playerCount: 3)
        #expect(draft.firstUncounted == 0)
        draft.scoreText[0] = "12"
        draft.apply(hand(["A", "T"]), for: 2)
        #expect(draft.firstUncounted == 1)
        #expect(draft.uncountedPlayers == [1])
        draft.scoreText[1] = "0"
        #expect(draft.firstUncounted == nil)
    }

    @Test("Next keeps a usable hand and moves to the next seat")
    func nextKeepsHand() {
        var count = session()
        ["A", "T"].forEach { count.currentHand.add($0) }
        count.advance()
        #expect(count.current == 1)
        #expect(count.round.countedHand(for: 0) == hand(["A", "T"]))
    }

    @Test("The last player has no next seat, and Done keeps their hand")
    func doneOnLastPlayer() {
        var count = session(startingAt: 2)
        #expect(count.nextPlayer == nil)
        ["O", "X"].forEach { count.currentHand.add($0) }
        count.advance()
        #expect(count.current == 2)
        #expect(count.finish().countedHand(for: 2) == hand(["O", "X"]))
    }

    @Test("An empty hand moves on and stays uncounted")
    func emptyHandMovesOn() {
        var count = session()
        count.advance()
        #expect(count.current == 1)
        #expect(count.round.score(for: 0) == nil)
    }

    @Test("Passing a typed player leaves their number alone")
    func typedScoreUntouched() {
        var draft = RoundDraft(playerCount: 2)
        draft.scoreText[0] = "12"
        var count = session(round: draft)
        #expect(count.entry[0] == .typed)
        count.advance()
        #expect(count.round.score(for: 0) == 12)
    }

    @Test("Passing a counted player keeps their cards and score")
    func countedHandUntouched() {
        var draft = RoundDraft(playerCount: 2)
        draft.apply(hand(["QU", "I", "Z"]), for: 0)
        var count = session(round: draft)
        count.advance()
        #expect(count.round.countedHand(for: 0) == hand(["QU", "I", "Z"]))
        #expect(!count.hasChanges)
    }

    @Test("A one-card word blocks moving on until it's fixed")
    func shortWordBlocks() {
        var count = session()
        count.currentHand.add("A")
        #expect(!count.canLeaveCurrent)
        count.advance()
        count.select(2)
        #expect(count.current == 0)
        count.currentHand.add("T")
        count.advance()
        #expect(count.current == 1)
    }

    @Test("Jumping between players keeps each one's cards")
    func jumpingKeepsCards() {
        var count = session()
        ["A", "T"].forEach { count.currentHand.add($0) }
        count.select(2)
        count.select(0)
        #expect(count.currentHand.preview == hand(["A", "T"]))
    }

    @Test("Deleting every card makes a counted player uncounted again")
    func deletingUncounts() {
        var draft = RoundDraft(playerCount: 2)
        draft.apply(hand(["A", "T"]), for: 0)
        var count = session(round: draft)
        count.currentHand.backspace()   // steps back into A·T
        count.currentHand.backspace()
        count.currentHand.backspace()
        count.advance()
        #expect(count.round.score(for: 0) == nil)
    }

    @Test("Typing a score instead replaces the cards")
    func typingReplacesCards() {
        var count = session()
        ["A", "T"].forEach { count.currentHand.add($0) }
        count.typeInstead()
        #expect(count.round.score(for: 0) == nil)
        count.typeDigit(1)
        count.typeDigit(2)
        count.toggleSign()
        count.advance()
        #expect(count.round.score(for: 0) == -12)
        #expect(count.round.countedHand(for: 0) == nil)
    }

    @Test("Going back to the cards drops the typed number")
    func countingReplacesTyping() {
        var count = session()
        ["A", "T"].forEach { count.currentHand.add($0) }
        count.typeInstead()
        count.typeDigit(9)
        count.countInstead()
        #expect(count.round.countedHand(for: 0) == hand(["A", "T"]))
    }

    @Test("Typing over a counted hand keeps the cards for later")
    func typingKeepsCards() {
        var draft = RoundDraft(playerCount: 2)
        draft.apply(hand(["QU", "I", "Z"]), for: 0)
        var count = session(round: draft)
        count.typeInstead()
        count.typeDigit(9)
        let typed = count.finish()
        #expect(typed.score(for: 0) == 9)
        #expect(typed.isTyped(0))

        var recount = session(round: typed)
        #expect(recount.entry[0] == .typed)
        recount.countInstead()
        #expect(recount.finish().countedHand(for: 0) == hand(["QU", "I", "Z"]))
    }

    @Test("A hand brought back from under a typed score is used on Next")
    func restoredHandIsUsed() {
        var draft = RoundDraft(playerCount: 2)
        draft.apply(hand(["A", "T"]), for: 0)
        draft.scoreText[0] = ""   // its number was cleared, as typing instead does
        var count = session(round: draft)
        #expect(count.entry[0] == .cards)
        count.advance()
        #expect(count.round.countedHand(for: 0) == hand(["A", "T"]))
    }

    @Test("A typed score is at most three digits")
    func typedDigitsCapped() {
        var count = session()
        count.typeInstead()
        [1, 2, 3, 4].forEach { count.typeDigit($0) }
        #expect(count.round.score(for: 0) == 123)
        count.deleteDigit()
        #expect(count.round.score(for: 0) == 12)
    }

    @Test("A lost challenge is kept, and 0 removes it")
    func penalty() {
        var count = session()
        count.setPenalty("8")
        #expect(count.round.penalty(for: 0) == 8)
        #expect(count.round.showsPenalty[0])
        count.setPenalty("0")
        #expect(count.round.penalty(for: 0) == 0)
        #expect(!count.round.showsPenalty[0])
    }

    @Test("Only real changes count as changes, so Cancel asks only when needed")
    func hasChanges() {
        var count = session()
        count.select(1)
        count.currentHand.target = .leftovers
        #expect(!count.hasChanges)
        count.currentHand.add("Q")
        #expect(count.hasChanges)
    }
}

@Suite("Why the cards picked a bonus")
struct BonusReasonTests {
    let names = ["Ada", "Ben", "Cy"]

    @Test("Top players are everyone sharing the highest number above zero")
    func topPlayers() {
        #expect(Scoring.topPlayers(of: [4, 7, 3]) == [1])
        #expect(Scoring.topPlayers(of: [7, 7, 3]) == [0, 1])
        #expect(Scoring.topPlayers(of: [0, 0]) == [])
        #expect(Scoring.topPlayers(of: []) == [])
    }

    @Test("A sole winner shows their word and its length")
    func longestWordWinner() {
        var draft = RoundDraft(playerCount: 3)
        draft.apply(hand(["QU", "I", "Z"], ["TH", "E"]), for: 0)
        draft.apply(hand(["CL", "A", "W", "S"], ["O", "N"]), for: 1)
        draft.apply(hand(["A", "T"], ["O", "X"], ["E", "N"]), for: 2)
        #expect(draft.longestWordReason(names: names) == "CLAWS · 5 letters")
        #expect(draft.mostWordsReason(names: names) == "3 words")
    }

    @Test("A tie explains that nobody scores")
    func tieReason() {
        var draft = RoundDraft(playerCount: 3)
        draft.apply(hand(["QU", "I", "Z"]), for: 0)
        draft.apply(hand(["TH", "E", "N"]), for: 1)
        draft.apply(hand(["A", "T"]), for: 2)
        #expect(draft.longestWordReason(names: names) == "Ada and Ben tie at 4 letters, so nobody scores")
        #expect(draft.mostWordsReason(names: names) == "Ada, Ben, and Cy tie with 1 word, so nobody scores")
    }

    @Test("No reason until every hand is counted")
    func noReasonWhileTyped() {
        var draft = RoundDraft(playerCount: 2)
        draft.apply(hand(["A", "T"]), for: 0)
        draft.scoreText[1] = "10"
        #expect(draft.longestWordReason(names: names) == nil)
        #expect(draft.isTyped(1))
        #expect(!draft.isTyped(0))
    }
}

@Suite("Game highlights")
struct GameHighlightsTests {
    private func game(_ rounds: [Round]) -> Game {
        Game(players: ["Ada", "Ben"], rules: .official(playerCount: 2), rounds: rounds)
    }

    @Test("Longest word counts letters, best word counts points")
    func picks() throws {
        let highlights = try #require(GameHighlights(game: game([
            Round(scores: [36, 9], hands: [hand(["QU", "I", "Z"], ["TH", "E"]), hand(["T", "H", "E", "N"])]),
        ])))
        #expect(highlights.longestWord.word.text == "QUIZ")   // 4 letters, played first
        #expect(highlights.longestWord.player == 0)
        #expect(highlights.bestWord.word.text == "QUIZ")      // 25 points
        #expect(highlights.bestWord.round == 1)
    }

    @Test("A two-letter card counts two letters")
    func digraphLength() throws {
        let highlights = try #require(GameHighlights(game: game([
            Round(scores: [16, 11], hands: [hand(["TH", "E", "N"]), hand(["Q", "U", "I"])]),
        ])))
        #expect(highlights.longestWord.word.text == "THEN")
        #expect(highlights.bestWord.word.text == "QUI")
    }

    @Test("The word played first wins a tie")
    func earlierWins() throws {
        let highlights = try #require(GameHighlights(game: game([
            Round(scores: [5, 0], hands: [hand(["A", "T"]), nil]),
            Round(scores: [0, 5], hands: [nil, hand(["T", "A"])]),
        ])))
        #expect(highlights.longestWord.round == 1)
        #expect(highlights.bestWord.player == 0)
    }

    @Test("A game of typed scores has no highlights")
    func typedGame() {
        #expect(GameHighlights(game: game([Round(scores: [12, 7])])) == nil)
    }
}

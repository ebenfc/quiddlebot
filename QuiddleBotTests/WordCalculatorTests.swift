import Testing
import Foundation
@testable import QuiddleBot

// The v1.1 word calculator. See docs/word-calculator.md.
// Tests marked "needs soleLeader" also depend on the tie rule in Scoring.soleLeader(of:).

/// Shorthand for building hands in tests: hand(["QU","I","Z"], ["TH","E"], left: ["R"]).
private func hand(_ words: [String]..., left: [String] = []) -> Hand {
    Hand(words: words.map(Word.init), leftovers: left)
}

@Suite("Words and hands")
struct HandTests {
    @Test("Two-letter cards score their printed value and count two letters")
    func wordValues() {
        #expect(Word(["QU", "I", "Z"]).points == 25)
        #expect(Word(["QU", "I", "Z"]).letters == 4)
        #expect(Word(["TH", "E"]).points == 11)
        #expect(Word(["TH", "E"]).letters == 3)
    }

    @Test("A hand is word points minus leftovers")
    func handScore() {
        let counted = hand(["QU", "I", "Z"], ["TH", "E"], left: ["R"])
        #expect(counted.wordPoints == 36)
        #expect(counted.leftoverPoints == 5)
        #expect(counted.score == 31)
        #expect(counted.longestWordLetters == 4)
        #expect(counted.wordCount == 2)
        #expect(counted.cardCount == 6)
    }

    @Test("A negative hand stays negative here and is floored by the scoring rules")
    func negativeHand() {
        let counted = hand(["A", "T"], left: ["Z"])
        #expect(counted.score == -9)
        let round = Round(scores: [counted.score, 4], hands: [counted, nil])
        #expect(Scoring.handTotal(round: round, player: 0, rules: .official(playerCount: 2)) == 0)
    }

    @Test("A 1.0 save, with no hands, still loads")
    func decodesWithoutHands() throws {
        let json = #"{"scores":[12,7],"penalties":[0,0],"longestWord":{"tie":{}},"mostWords":{"unset":{}}}"#
        let round = try JSONDecoder().decode(Round.self, from: Data(json.utf8))
        #expect(round.hands == [nil, nil])
        #expect(round.scores == [12, 7])
    }

    @Test("Damaged hands cost the cards, never the scores")
    func damagedHands() throws {
        let garbage = #"{"scores":[12,7],"hands":"oops"}"#
        let round = try JSONDecoder().decode(Round.self, from: Data(garbage.utf8))
        #expect(round.scores == [12, 7])
        #expect(round.hands == [nil, nil])

        let wrongCount = #"{"scores":[12,7],"hands":[null]}"#
        #expect(try JSONDecoder().decode(Round.self, from: Data(wrongCount.utf8)).hands == [nil, nil])
    }

    @Test("Counted hands survive a save and reload, table-accepted marks included")
    func handsRoundTrip() {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "quiddlebot-test-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let counted = hand(["QU", "I", "Z"], ["TH", "E"], left: ["R"])
        let marked = Hand(words: [Word(["Z", "A"], tableAccepted: true)], leftovers: [])

        let store = GameStore(fileURL: url)
        store.start(players: ["Ada", "Ben"], rules: .official(playerCount: 2))
        store.submit(Round(scores: [31, 16], longestWord: .player(0), hands: [counted, marked]))

        #expect(GameStore(fileURL: url).game?.rounds.first?.hands == [counted, marked])
    }

    @Test("A 1.1 word, with no table-accepted flag, decodes as unmarked")
    func wordWithoutFlagDecodes() throws {
        let word = try JSONDecoder().decode(Word.self, from: Data(#"{"faces":["Z","A"]}"#.utf8))
        #expect(word.faces == ["Z", "A"])
        #expect(!word.tableAccepted)
    }

    @Test("A damaged table-accepted flag costs only the mark, never the scores")
    func damagedFlagCostsOnlyTheMark() throws {
        let word = try JSONDecoder().decode(Word.self, from: Data(#"{"faces":["Z","A"],"tableAccepted":"yes"}"#.utf8))
        #expect(word.faces == ["Z", "A"])
        #expect(!word.tableAccepted)

        let json = #"{"scores":[16],"hands":[{"words":[{"faces":["Z","A"],"tableAccepted":"yes"}],"leftovers":[]}]}"#
        let round = try JSONDecoder().decode(Round.self, from: Data(json.utf8))
        #expect(round.scores == [16])
        #expect(round.hands.first??.words.first?.tableAccepted == false)
    }

    @Test("An unmarked word encodes exactly as 1.1 did; a marked one carries its flag")
    func unmarkedWordEncodesLike1_1() throws {
        let plain = try String(decoding: JSONEncoder().encode(Word(["Z", "A"])), as: UTF8.self)
        #expect(!plain.contains("tableAccepted"))

        let marked = Word(["Z", "A"], tableAccepted: true)
        let json = try String(decoding: JSONEncoder().encode(marked), as: UTF8.self)
        #expect(json.contains(#""tableAccepted":true"#))
        #expect(try JSONDecoder().decode(Word.self, from: Data(json.utf8)) == marked)
    }
}

@Suite("Tie rule: Scoring.soleLeader")
struct SoleLeaderTests {
    @Test("The single highest number wins")
    func soleWinner() {
        #expect(Scoring.soleLeader(of: [4, 7, 3]) == .player(1))
    }

    @Test("A tie lower down doesn't matter")
    func tieBelowTheTop() {
        #expect(Scoring.soleLeader(of: [7, 3, 3]) == .player(0))
    }

    @Test("A shared top pays nobody")
    func sharedTop() {
        #expect(Scoring.soleLeader(of: [7, 7, 3]) == .tie)
    }

    @Test("Nobody above zero pays nobody")
    func allZero() {
        #expect(Scoring.soleLeader(of: [0, 0, 0]) == .tie)
    }

    @Test("No players, no winner")
    func empty() {
        #expect(Scoring.soleLeader(of: []) == .tie)
    }
}

@Suite("Bonus suggestions")
struct SuggestionTests {
    @Test("Longest Word counts letters, not cards (needs soleLeader)")
    func lettersNotCards() {
        // Both words are three cards; TH·E·N is four letters, A·T·E is three.
        let hands = [hand(["TH", "E", "N"]), hand(["A", "T", "E"])]
        #expect(Scoring.suggestedLongestWord(for: hands) == .player(0))
    }

    @Test("Most Words goes to whoever laid down the most words (needs soleLeader)")
    func mostWords() {
        let hands = [hand(["A", "T"]), hand(["A", "T"], ["O", "N"])]
        #expect(Scoring.suggestedMostWords(for: hands) == .player(1))
    }

    @Test("No suggestion while anyone's score was typed")
    func typedScoreBlocksSuggestion() {
        #expect(Scoring.suggestedLongestWord(for: [hand(["A", "T"]), nil]) == nil)
        #expect(Scoring.suggestedMostWords(for: [hand(["A", "T"]), nil]) == nil)
    }
}

@Suite("Round draft with counted hands")
struct CountedDraftTests {
    let twoPlayer = RuleSet.official(playerCount: 2)

    @Test("Using a negative hand fills the score and flips the sign")
    func applyNegative() {
        var draft = RoundDraft(playerCount: 2)
        draft.apply(hand(["A", "T"], left: ["Z"]), for: 0)
        #expect(draft.scoreText[0] == "9")
        #expect(draft.isNegative[0])
        #expect(draft.score(for: 0) == -9)
        #expect(draft.countedHand(for: 0) != nil)
    }

    @Test("Typing a different number over a counted hand drops the cards")
    func typedNumberWins() {
        var draft = RoundDraft(playerCount: 2)
        draft.apply(hand(["QU", "I", "Z"]), for: 0)
        draft.scoreText[0] = "40"
        draft.scoreText[1] = "10"
        draft.longestWord = .player(0)
        #expect(draft.countedHand(for: 0) == nil)
        #expect(draft.round(rules: twoPlayer)?.hands == [nil, nil])
    }

    @Test("With every hand counted, the bonus fills itself in (needs soleLeader)")
    func suggestionFillsPick() {
        var draft = RoundDraft(playerCount: 2)
        draft.apply(hand(["QU", "I", "Z"]), for: 0)
        draft.apply(hand(["A", "T"]), for: 1)
        #expect(draft.longestWord == .unset)
        #expect(draft.effectiveLongestWord == .player(0))
        #expect(draft.isComplete(rules: twoPlayer))
        #expect(draft.round(rules: twoPlayer)?.longestWord == .player(0))
    }

    @Test("A pick that agrees with the cards follows them when a word is fixed (needs soleLeader)")
    func agreeingPickFollows() {
        var draft = RoundDraft(playerCount: 2)
        draft.apply(hand(["QU", "I", "Z"]), for: 0)
        draft.apply(hand(["A", "T"]), for: 1)
        draft.pickLongestWord(.player(0))
        #expect(draft.longestWord == .unset)

        draft.apply(hand(["Z", "E", "B", "R", "A"]), for: 1)
        #expect(draft.effectiveLongestWord == .player(1))
    }

    @Test("An override beats the cards")
    func overrideWins() {
        var draft = RoundDraft(playerCount: 2)
        draft.apply(hand(["QU", "I", "Z"]), for: 0)
        draft.apply(hand(["A", "T"]), for: 1)
        draft.pickLongestWord(.player(1))
        draft.apply(hand(["QU", "I", "Z", "Z"]), for: 0)
        #expect(draft.effectiveLongestWord == .player(1))
    }

    @Test("A bonus the table doesn't play is never saved")
    func disabledBonusIgnored() {
        var draft = RoundDraft(playerCount: 2)
        draft.apply(hand(["A", "T"]), for: 0)
        draft.apply(hand(["A", "T"], ["O", "N"]), for: 1)
        draft.pickLongestWord(.tie)
        #expect(!twoPlayer.mostWordsEnabled)
        #expect(draft.round(rules: twoPlayer)?.mostWords == .unset)
    }

    @Test("Re-editing a saved round keeps following the cards (needs soleLeader)")
    func reEditKeepsSuggestion() throws {
        var draft = RoundDraft(playerCount: 2)
        draft.apply(hand(["QU", "I", "Z"]), for: 0)
        draft.apply(hand(["A", "T"]), for: 1)
        let saved = try #require(draft.round(rules: twoPlayer))

        var editing = RoundDraft(from: saved)
        #expect(editing.hands == saved.hands)
        #expect(editing.longestWord == .unset)
        editing.apply(hand(["Z", "E", "B", "R", "A"]), for: 1)
        #expect(editing.effectiveLongestWord == .player(1))
    }

    @Test("Re-editing a typed round keeps its picks as they were")
    func reEditTypedRound() {
        let saved = Round(scores: [12, 7], longestWord: .player(1))
        let editing = RoundDraft(from: saved)
        #expect(editing.longestWord == .player(1))
        #expect(editing.hands == [nil, nil])
    }
}

@Suite("Counting a hand")
struct HandDraftTests {
    @Test("Words, next word and leftovers build the hand")
    func buildsHand() {
        var draft = HandDraft(hand: nil, cardsDealt: 6)
        ["QU", "I", "Z"].forEach { draft.add($0) }
        draft.nextWord()
        ["TH", "E"].forEach { draft.add($0) }
        draft.target = .leftovers
        draft.add("R")
        #expect(draft.hand == hand(["QU", "I", "Z"], ["TH", "E"], left: ["R"]))
        #expect(draft.issues.isEmpty)
    }

    @Test("Next word on an empty word does nothing")
    func nextWordOnEmpty() {
        var draft = HandDraft(hand: nil, cardsDealt: 3)
        draft.nextWord()
        draft.nextWord()
        #expect(draft.words == [[]])
    }

    @Test("Delete in an empty word steps back into the previous word")
    func backspaceAcrossWords() {
        var draft = HandDraft(hand: nil, cardsDealt: 3)
        ["A", "T"].forEach { draft.add($0) }
        draft.nextWord()
        draft.backspace()
        #expect(draft.words == [["A", "T"]])
        #expect(draft.currentWord == 0)
        draft.backspace()
        #expect(draft.words == [["A"]])
    }

    @Test("Delete in an empty leftover tray goes back to the words")
    func backspaceFromLeftovers() {
        var draft = HandDraft(hand: nil, cardsDealt: 3)
        draft.target = .leftovers
        draft.backspace()
        #expect(draft.target == .words)
    }

    @Test("A one-card word blocks Use until it moves to the leftovers")
    func shortWord() {
        var draft = HandDraft(hand: nil, cardsDealt: 3)
        draft.add("A")
        draft.nextWord()
        ["T", "O"].forEach { draft.add($0) }
        #expect(draft.issues.contains(.shortWord(index: 0)))
        #expect(draft.hand == nil)

        draft.moveWordToLeftovers(0)
        #expect(draft.hand == hand(["T", "O"], left: ["A"]))
    }

    @Test("The wrong number of cards is a warning, not a block")
    func cardCountWarning() {
        var draft = HandDraft(hand: nil, cardsDealt: Game.cardsDealt(inRound: 5))
        ["Q", "U", "I", "T", "E", "S"].forEach { draft.add($0) }
        #expect(draft.issues == [.cardCount(placed: 6, dealt: 7)])
        #expect(draft.hand != nil)
    }

    @Test("Removing a word's last card removes the word")
    func removeEmptiesWord() {
        var draft = HandDraft(hand: hand(["A", "T"], ["O", "N"]), cardsDealt: 4)
        draft.removeCard(word: 0, at: 0)
        draft.removeCard(word: 0, at: 0)
        #expect(draft.preview == hand(["O", "N"]))
    }

    @Test("Reopening a counted hand gives the same hand back")
    func reopen() {
        let counted = hand(["QU", "I", "Z"], ["TH", "E"], left: ["R"])
        #expect(HandDraft(hand: counted, cardsDealt: 6).hand == counted)
    }
}

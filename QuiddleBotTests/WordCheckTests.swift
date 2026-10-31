import Testing
import Foundation
@testable import QuiddleBot

// The v1.2 word check: the built-in list, the three-state verdict, and "Table says it's good".
// See docs/word-calculator.md. The check is a hint: nothing here touches a score.

@Suite("Word list")
struct WordListTests {
    @Test("Lookups ignore case, so a word's card faces can be passed straight in")
    func caseInsensitive() {
        let list = WordList(words: ["quiz", "the"])
        #expect(list.count == 2)
        #expect(list.contains("QUIZ"))
        #expect(list.contains("quiz"))
        #expect(list.contains("The"))
        #expect(!list.contains("ZA"))
    }

    @Test("The resource's header and blank lines are skipped")
    func skipsHeaderAndBlankLines() {
        let list = WordList(text: "# header\n# more\n\nquiz\nthe\n\n")
        #expect(list.count == 2)
        #expect(list.contains("THE"))
        #expect(!list.contains("#"))
    }

    @Test("The bundled list loads, with the additions merged in")
    func bundledListLoads() throws {
        let list = try WordList.bundled()
        #expect(list.count > 168_000)
        for word in ["THE", "QUIZ", "CLAWS", "ZEBRA", "IN", "ER"] {
            #expect(list.contains(word), "\(word) should be listed")
        }
        // From additions.txt: ENABLE1 predates these.
        #expect(list.contains("QI"))
        #expect(list.contains("ZA"))
        #expect(list.contains("OK"))
        // Card faces are not words on their own.
        for face in ["QU", "CL", "TH"] {
            #expect(!list.contains(face), "\(face) should not be listed")
        }
    }

    @Test("The bundled list is lowercase a–z, 2 to 15 letters, sorted and deduplicated")
    func bundledListIsClean() throws {
        let url = try #require(Bundle.main.url(forResource: "words", withExtension: "txt"))
        let text = try String(contentsOf: url, encoding: .utf8)
        let lines = text.split(separator: "\n").filter { !$0.hasPrefix("#") }
        #expect(lines.count > 168_000)
        var previous = ""
        for line in lines {
            let word = String(line)
            #expect(word.count >= 2 && word.count <= 15, "\(word) has the wrong length")
            #expect(word.allSatisfy { ("a"..."z").contains($0) }, "\(word) is not lowercase a–z")
            #expect(word > previous, "\(word) is out of order or repeated")
            previous = word
        }
    }
}

@Suite("Word verdict")
struct WordVerdictTests {
    @Test("A listed word is found")
    func foundWhenListed() {
        #expect(WordVerdict(word: Word(["QU", "I", "Z"]), isListed: true) == .found)
    }

    @Test("An unlisted word is not in the list until the table rules")
    func notInListByDefault() {
        #expect(WordVerdict(word: Word(["Z", "A"]), isListed: false) == .notInList)
    }

    @Test("The table's acceptance shows for an unlisted word")
    func tableAcceptedWhenMarked() {
        #expect(WordVerdict(word: Word(["Z", "A"], tableAccepted: true), isListed: false) == .tableAccepted)
    }

    @Test("The list wins over a stale mark")
    func listBeatsStaleMark() {
        #expect(WordVerdict(word: Word(["T", "O"], tableAccepted: true), isListed: true) == .found)
    }
}

@Suite("Table says it's good")
struct TableAcceptedTests {
    @Test("The mark is saved on the hand and never changes the score")
    func markIsSavedOnTheHand() {
        var draft = HandDraft(hand: nil, cardsDealt: 3)
        ["Z", "A"].forEach { draft.add($0) }
        #expect(!draft.isTableAccepted(0))
        draft.setTableAccepted(true, forWord: 0)
        #expect(draft.isTableAccepted(0))
        #expect(draft.hand?.words.first?.tableAccepted == true)
        #expect(draft.hand?.score == 16)
    }

    @Test("Changing the cards lifts the mark: a ruling on ZA says nothing about ZAP")
    func changingTheCardsLiftsTheMark() {
        var draft = HandDraft(hand: nil, cardsDealt: 3)
        ["Z", "A"].forEach { draft.add($0) }
        draft.setTableAccepted(true, forWord: 0)
        draft.add("P")
        #expect(!draft.isTableAccepted(0))
        draft.backspace()
        #expect(draft.isTableAccepted(0))
    }

    @Test("Taking the ruling back, and ignoring rows that can't be ruled on")
    func undo() {
        var draft = HandDraft(hand: nil, cardsDealt: 3)
        ["Z", "A"].forEach { draft.add($0) }
        draft.setTableAccepted(true, forWord: 0)
        draft.setTableAccepted(false, forWord: 0)
        #expect(!draft.isTableAccepted(0))

        draft.setTableAccepted(true, forWord: 5)
        #expect(!draft.isTableAccepted(5))

        draft.nextWord()
        draft.add("Q")
        draft.setTableAccepted(true, forWord: 1)
        #expect(!draft.isTableAccepted(1))
    }

    @Test("Reopening a counted hand keeps the mark")
    func reopeningKeepsTheMark() {
        let counted = Hand(words: [Word(["Z", "A"], tableAccepted: true), Word(["T", "O"])], leftovers: [])
        let draft = HandDraft(hand: counted, cardsDealt: 4)
        #expect(draft.isTableAccepted(0))
        #expect(!draft.isTableAccepted(1))
        #expect(draft.hand == counted)
    }

    @Test("Marking a word counts as a change and is written into the round")
    func markIsAChangeAndIsCommitted() {
        var count = RoundCountSession(round: RoundDraft(playerCount: 1), cardsDealt: 3, startingAt: 0)
        ["Z", "A"].forEach { count.currentHand.add($0) }
        count.currentHand.setTableAccepted(true, forWord: 0)
        #expect(count.hasChanges)

        let round = count.finish()
        #expect(round.countedHand(for: 0)?.words.first?.tableAccepted == true)
        #expect(round.score(for: 0) == 16)
    }
}

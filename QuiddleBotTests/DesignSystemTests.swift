import Testing
import Foundation
@testable import QuiddleBot

@Suite("Avatar monograms")
struct MonogramTests {
    @Test("Different initials stay one letter")
    func distinct() {
        #expect(Monogram.make(for: ["Ada", "Ben", "Cy"]) == ["A", "B", "C"])
    }

    @Test("A shared initial becomes two letters, so color isn't the only difference")
    func shared() {
        #expect(Monogram.make(for: ["Ben", "Bo", "Cy"]) == ["Be", "Bo", "C"])
        #expect(Monogram.make(for: ["Ben", "bea"]) == ["B1", "B2"])
    }

    @Test("When two letters still clash, the seat number tells them apart")
    func clashAgain() {
        #expect(Monogram.make(for: ["Ben", "Bennett"]) == ["B1", "B2"])
    }

    @Test("A blank name shows its seat number")
    func blank() {
        #expect(Monogram.make(for: ["", "Ada"]) == ["1", "A"])
    }
}

@Suite("Rounds in progress")
struct DraftPersistenceTests {
    private func temporaryFile() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: "quiddlebot-test-\(UUID().uuidString).json")
    }

    private func counted(_ store: GameStore) -> RoundDraft {
        var draft = RoundDraft(playerCount: 2)
        draft.apply(Hand(words: [Word(["QU", "I", "Z"])], leftovers: []), for: 0)
        return draft
    }

    @Test("A half-counted round survives the app being closed")
    func survivesRelaunch() {
        let url = temporaryFile()
        let store = GameStore(fileURL: url)
        store.start(players: ["Ada", "Ben"], rules: .official(playerCount: 2))
        let draft = counted(store)
        store.saveDrafts([1: draft])

        let reopened = GameStore(fileURL: url)
        #expect(reopened.restoredDrafts() == [1: draft])
        reopened.reset()
    }

    @Test("Submitting the round throws its saved progress away")
    func clearedOnSubmit() {
        let url = temporaryFile()
        let store = GameStore(fileURL: url)
        store.start(players: ["Ada", "Ben"], rules: .official(playerCount: 2))
        store.saveDrafts([1: counted(store)])
        store.submit(Round(scores: [12, 7], longestWord: .player(0)))

        #expect(GameStore(fileURL: url).restoredDrafts().isEmpty)
        store.reset()
    }

    @Test("Progress on another round, or for another table, is ignored")
    func onlyCurrentRound() {
        let url = temporaryFile()
        let store = GameStore(fileURL: url)
        store.start(players: ["Ada", "Ben"], rules: .official(playerCount: 2))
        store.saveDrafts([3: counted(store)])
        #expect(store.restoredDrafts().isEmpty)
        store.reset()
    }
}

@Suite("Celebration")
struct CelebrationTests {
    @Test("Finishing a game celebrates once; reopening on final scores doesn't")
    func once() {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "quiddlebot-test-\(UUID().uuidString).json")
        let store = GameStore(fileURL: url)
        store.start(players: ["Ada", "Ben"], rules: .official(playerCount: 2))
        store.endEarly()
        #expect(store.takeCelebration())
        #expect(!store.takeCelebration())
        #expect(!GameStore(fileURL: url).takeCelebration())
        store.reset()
    }
}

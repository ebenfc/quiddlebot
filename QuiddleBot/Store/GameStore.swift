import Foundation
import Observation
import os

/// The one source of truth for the current game, saved to disk after every change.
@Observable
final class GameStore {
    /// nil means no game in progress: show the setup screen.
    private(set) var game: Game?
    /// Round being edited (1-based), or nil while entering the current round.
    var editingRound: Int?
    /// Set when this session finishes a game, so the confetti and the success haptic play
    /// once, for the finish itself, and not every time the app reopens on final scores.
    private(set) var celebrationPending = false

    private let fileURL: URL
    private let log = Logger(subsystem: "com.ebencarey.quiddlebot", category: "store")

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultFileURL
        load()
    }

    // MARK: - Game lifecycle

    func start(players: [String], rules: RuleSet) {
        game = Game(players: players, rules: rules)
        editingRound = nil
        celebrationPending = false
        persist()
        clearDrafts()
    }

    /// Records the current round. The same path handles every round, including the last,
    /// which is what the web version got wrong: its final round was never saved.
    func submit(_ round: Round) {
        guard var current = game else { return }
        current.rounds.append(round)
        if current.rounds.count >= current.rules.roundCount {
            current.isFinished = true
            celebrationPending = true
        }
        game = current
        persist()
        clearDrafts()
    }

    func save(_ round: Round, forRound number: Int) {
        guard var current = game, current.rounds.indices.contains(number - 1) else { return }
        current.rounds[number - 1] = round
        game = current
        editingRound = nil
        persist()
    }

    func endEarly() {
        game?.isFinished = true
        editingRound = nil
        celebrationPending = true
        persist()
        clearDrafts()
    }

    /// True once after a game finishes in this session; reading it uses it up.
    func takeCelebration() -> Bool {
        defer { celebrationPending = false }
        return celebrationPending
    }

    /// A fresh game with the same players and rules, for "one more".
    func rematch() {
        guard let current = game else { return }
        start(players: current.players, rules: current.rules)
    }

    func reset() {
        game = nil
        editingRound = nil
        celebrationPending = false
        persist()
        clearDrafts()
    }

    // MARK: - Rounds in progress

    /// Saves the current round's unsubmitted scores and counted hands. Called when the app
    /// goes to the background: the phone gets passed round the table, and iOS may close the
    /// app before it comes back. Edits of earlier rounds are not kept.
    func saveDrafts(_ drafts: [Int: RoundDraft]) {
        guard let game, !game.isFinished,
              let draft = drafts[game.currentRound], draft != RoundDraft(playerCount: game.players.count)
        else {
            clearDrafts()
            return
        }
        do {
            try FileManager.default.createDirectory(at: draftsURL.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(SavedDraft(round: game.currentRound, draft: draft))
            try data.write(to: draftsURL, options: .atomic)
        } catch {
            // Losing a half-counted round is a nuisance, not a reason to stop the game.
            log.error("Could not save the round in progress: \(error.localizedDescription)")
        }
    }

    /// The round in progress saved by `saveDrafts`, if it still fits the current game.
    func restoredDrafts() -> [Int: RoundDraft] {
        guard let game, !game.isFinished,
              let data = try? Data(contentsOf: draftsURL),
              let saved = try? JSONDecoder().decode(SavedDraft.self, from: data),
              saved.round == game.currentRound,
              saved.draft.playerCount == game.players.count
        else { return [:] }
        return [saved.round: saved.draft]
    }

    private func clearDrafts() {
        try? FileManager.default.removeItem(at: draftsURL)
    }

    private nonisolated struct SavedDraft: Codable {
        let round: Int
        let draft: RoundDraft
    }

    /// Next to the game file: game.json, game-drafts.json.
    private var draftsURL: URL {
        let name = fileURL.deletingPathExtension().lastPathComponent + "-drafts.json"
        return fileURL.deletingLastPathComponent().appending(path: name)
    }

    // MARK: - Persistence

    private static var defaultFileURL: URL {
        let base = (try? FileManager.default.url(for: .applicationSupportDirectory,
                                                 in: .userDomainMask,
                                                 appropriateFor: nil,
                                                 create: true))
            ?? FileManager.default.temporaryDirectory
        return base.appending(path: "QuiddleBot", directoryHint: .isDirectory)
                   .appending(path: "game.json")
    }

    private func persist() {
        do {
            if let game {
                try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                        withIntermediateDirectories: true)
                let data = try JSONEncoder().encode(game)
                try data.write(to: fileURL, options: .atomic)
            } else if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch {
            log.error("Could not save game: \(error.localizedDescription)")
            assertionFailure("Could not save game: \(error)")
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            game = try JSONDecoder().decode(Game.self, from: data)
        } catch {
            // A corrupt or incompatible save should not brick the app: start fresh.
            log.error("Could not load saved game, starting fresh: \(error.localizedDescription)")
            game = nil
        }
    }
}

#if DEBUG
extension GameStore {
    /// A throwaway store for SwiftUI previews, with `rounds` hands already played.
    static func preview(players: [String] = ["Ada", "Ben"], rounds: Int = 0) -> GameStore {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "quiddlebot-preview-\(UUID().uuidString).json")
        let store = GameStore(fileURL: url)
        store.start(players: players, rules: .official(playerCount: players.count))
        for n in 0..<rounds {
            let scores = players.indices.map { 6 + ($0 + n) * 3 }
            store.submit(Round(scores: scores, longestWord: .player(n % players.count),
                               mostWords: .tie))
        }
        return store
    }
}
#endif

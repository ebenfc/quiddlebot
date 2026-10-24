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
        persist()
    }

    /// Records the current round. The same path handles every round, including the last,
    /// which is what the web version got wrong: its final round was never saved.
    func submit(_ round: Round) {
        guard var current = game else { return }
        current.rounds.append(round)
        if current.rounds.count >= current.rules.roundCount {
            current.isFinished = true
        }
        game = current
        persist()
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
        persist()
    }

    func reset() {
        game = nil
        editingRound = nil
        persist()
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

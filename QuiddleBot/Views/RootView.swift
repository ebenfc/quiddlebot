import SwiftUI

/// Picks the screen from the store: setup, playing, or finished.
struct RootView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        if let game = store.game {
            if game.isFinished {
                GameOverView(game: game)
            } else {
                GameView(game: game)
            }
        } else {
            SetupView()
        }
    }
}

// Previews use debug-only fixtures, so they compile only in Debug builds.
#if DEBUG
#Preview("Setup") {
    RootView().environment(GameStore.preview(rounds: 0).resetForPreview())
}

#Preview("Mid-game") {
    RootView().environment(GameStore.preview(players: ["Ada", "Ben", "Cy"], rounds: 3))
}

private extension GameStore {
    func resetForPreview() -> GameStore { reset(); return self }
}
#endif

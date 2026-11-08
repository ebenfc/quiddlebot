import SwiftUI

/// Picks the screen from the store: setup, playing, or finished.
struct RootView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase

    /// The phone sits on the table between hands, so it must not lock mid-game. One place,
    /// driven by state: a sheet or the round counter covering the game screen doesn't turn it
    /// off, and coming back from the background turns it on again.
    private var keepsScreenAwake: Bool {
        scenePhase == .active && store.game.map { !$0.isFinished } == true
    }

    var body: some View {
        Group {
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
        // Rounded type everywhere: friendlier numbers, same system font metrics and Dynamic Type.
        .fontDesign(.rounded)
        .tint(DS.Colors.accent)
        .onChange(of: keepsScreenAwake, initial: true) { _, awake in
            UIApplication.shared.isIdleTimerDisabled = awake
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

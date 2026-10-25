import SwiftUI

/// A short burst of confetti for the end of a game. Drawn with Canvas, so it costs
/// almost nothing, and it stops animating once the last piece has fallen.
/// Callers skip it entirely when Reduce Motion is on.
struct ConfettiView: View {
    var duration: TimeInterval = 4.0

    private static let colors: [Color] = Theme.playerColors + [Theme.gold, Color.accentColor]
    private static let pieceCount = 140

    // Created once with the view, not in onAppear: an overlay's onAppear is not guaranteed
    // to land before the first frames, and an empty burst draws nothing.
    @State private var startDate = Date.now
    @State private var pieces: [Piece] = (0..<pieceCount).map { _ in Piece.random(colorCount: colors.count) }
    @State private var isFinished = false

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: isFinished)) { context in
            let elapsed = context.date.timeIntervalSince(startDate)
            Canvas { graphics, size in
                for piece in pieces {
                    let age = elapsed - piece.delay
                    guard age > 0 else { continue }
                    let y = -24 + piece.fall * age + 0.5 * 160 * age * age
                    guard y < size.height + 24 else { continue }
                    let x = piece.x * size.width + piece.drift * age + sin(age * piece.wobble) * 10
                    let opacity = min(1, max(0, (duration - age) / 0.8))
                    guard opacity > 0 else { continue }

                    var context = graphics
                    context.opacity = opacity
                    context.translateBy(x: x, y: y)
                    context.rotate(by: .radians(piece.spin * age))
                    let rect = CGRect(x: -piece.size / 2, y: -piece.size * 0.3,
                                      width: piece.size, height: piece.size * 0.6)
                    let shape = piece.isRound ? Path(ellipseIn: rect)
                                              : Path(roundedRect: rect, cornerRadius: 1.5)
                    context.fill(shape, with: .color(Self.colors[piece.colorIndex]))
                }
            }
        }
        .task {
            // Stop the animation clock only when the burst has really played out.
            // A cancelled task (SwiftUI can cancel and restart it during launch) must not
            // freeze the confetti before it has fallen into view.
            do {
                try await Task.sleep(for: .seconds(duration + 1))
                isFinished = true
            } catch {}
        }
        .accessibilityHidden(true)
    }

    private struct Piece {
        var x: Double          // 0...1 across the width
        var drift: Double      // sideways points per second
        var fall: Double       // starting downward speed
        var delay: Double
        var wobble: Double
        var spin: Double
        var size: Double
        var colorIndex: Int
        var isRound: Bool

        static func random(colorCount: Int) -> Piece {
            Piece(x: .random(in: 0...1),
                  drift: .random(in: -40...40),
                  fall: .random(in: 30...130),
                  delay: .random(in: 0...0.9),
                  wobble: .random(in: 2...6),
                  spin: .random(in: -8...8),
                  size: .random(in: 7...12),
                  colorIndex: .random(in: 0..<max(colorCount, 1)),
                  isRound: .random())
        }
    }
}

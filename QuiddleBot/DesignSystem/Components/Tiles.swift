import SwiftUI

/// The cream face shared by letter tiles and keypad keys: the app's signature, a plain card
/// on the table. Deliberately generic: no frame, no ornament, never the game's card art.
private struct TileSurface: ViewModifier {
    var fill: Color
    var isPressed: Bool

    func body(content: Content) -> some View {
        content
            .background(fill, in: RoundedRectangle.ds(DS.Radius.tile))
            .overlay {
                RoundedRectangle.ds(DS.Radius.tile)
                    .strokeBorder(DS.Colors.tileEdge, lineWidth: 1)
            }
            .overlay {
                RoundedRectangle.ds(DS.Radius.tile)
                    .fill(Color.black.opacity(isPressed ? DS.Opacity.pressed : 0))
            }
            // A hard 1.5 pt lip under the tile, so it sits on the table rather than in it.
            .shadow(color: DS.Colors.tileEdge, radius: 0, x: 0, y: 1.5)
    }
}

extension View {
    func tileSurface(fill: Color = DS.Colors.tileFace, isPressed: Bool = false) -> some View {
        modifier(TileSurface(fill: fill, isPressed: isPressed))
    }
}

/// One card in a word or the leftover tray: its face and, small, its points.
struct LetterTile: View {
    enum Tone {
        /// A card in a word: cream.
        case word
        /// A card nobody could use: a red wash, since it costs points.
        case leftover
    }

    let face: String
    var tone: Tone = .word

    /// Grows with Dynamic Type, within reason: the rows scroll sideways, so taller tiles
    /// cost nothing but a little width.
    @ScaledMetric(relativeTo: .body) private var scaledHeight: CGFloat = DS.Size.tile

    private var height: CGFloat { min(scaledHeight, 60) }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Text(face)
                .font(.system(size: height * 0.42, weight: .bold, design: .rounded))
                .foregroundStyle(ink)
                .frame(width: face.count > 1 ? height : height * 0.76, height: height)
            Text("\(CardValues.points[face] ?? 0)")
                .font(.system(size: max(10, height * 0.24), weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(ink.opacity(0.7))
                .padding(.trailing, 3)
                .padding(.bottom, 2)
        }
        .tileSurface(fill: tone == .word ? DS.Colors.tileFace : DS.Colors.tint(DS.Colors.negative))
        .accessibilityShowsLargeContentViewer {
            Text("\(face) \(CardValues.points[face] ?? 0)")
        }
    }

    private var ink: Color {
        tone == .word ? DS.Colors.tileInk : DS.Colors.negative
    }
}

import SwiftUI

/// One card in a word or the leftover tray: its face and, small, its points. A plain gray
/// chip in system type, the same fill as the keypad's keys: no border, shadow or ornament.
struct LetterTile: View {
    enum Tone {
        /// A card in a word: neutral gray.
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
                .font(.system(size: height * 0.42, weight: .medium))
                .foregroundStyle(ink)
                .frame(width: face.count > 1 ? height : height * 0.76, height: height)
            Text("\(CardValues.points[face] ?? 0)")
                .font(.system(size: max(10, height * 0.24), weight: .semibold).monospacedDigit())
                .foregroundStyle(ink.opacity(0.6))
                .padding(.trailing, 3)
                .padding(.bottom, 2)
        }
        .background(tone == .word ? DS.Colors.tileFace : DS.Colors.tint(DS.Colors.negative),
                    in: RoundedRectangle.ds(DS.Radius.tile))
        .accessibilityShowsLargeContentViewer {
            Text("\(face) \(CardValues.points[face] ?? 0)")
        }
    }

    private var ink: Color {
        tone == .word ? DS.Colors.tileInk : DS.Colors.negative
    }
}

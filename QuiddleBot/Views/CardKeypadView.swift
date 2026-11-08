import SwiftUI

/// The word calculator's keypad: letters where the iPhone keyboard has them, then the five
/// two-letter cards. Every key is a small cream tile with its point value in the corner.
struct CardKeypadView: View {
    var onCard: (String) -> Void
    var onNextWord: () -> Void
    var onBackspace: () -> Void
    /// Shorter on small screens such as the iPhone SE, so the words above stay in view.
    var keyHeight: CGFloat = DS.Size.key

    private static let letterRows: [[String]] = [
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
        ["Z", "X", "C", "V", "B", "N", "M"],
    ]
    private static let twoLetterCards = ["QU", "IN", "ER", "CL", "TH"]

    private let gap: CGFloat = 5
    private let rowGap: CGFloat = DS.Space.s

    @State private var taps = 0
    /// Key labels follow Dynamic Type a little, then stop: the keys themselves keep the
    /// system keyboard's size, and long-pressing at accessibility sizes shows the large
    /// content viewer instead.
    @ScaledMetric(relativeTo: .title3) private var faceSize: CGFloat = 20
    @ScaledMetric(relativeTo: .caption2) private var pointSize: CGFloat = 10

    var body: some View {
        // Key widths come from the ten-key top row, so every row lines up like a keyboard.
        GeometryReader { proxy in
            let key = (proxy.size.width - gap * 9) / 10
            VStack(spacing: rowGap) {
                letterRow(Self.letterRows[0], key: key)
                letterRow(Self.letterRows[1], key: key)
                HStack(spacing: gap) {
                    Color.clear.frame(width: key * 1.5, height: 1)
                    letterRow(Self.letterRows[2], key: key)
                    backspaceKey.frame(width: key * 1.5)
                }
                HStack(spacing: gap) {
                    ForEach(Self.twoLetterCards, id: \.self) { face in
                        cardKey(face).frame(width: key * 1.5)
                    }
                    nextWordKey
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: keyHeight * 4 + rowGap * 3)
        .sensoryFeedback(DS.Haptic.key, trigger: taps)
    }

    private func letterRow(_ faces: [String], key: CGFloat) -> some View {
        HStack(spacing: gap) {
            ForEach(faces, id: \.self) { face in
                cardKey(face).frame(width: key)
            }
        }
    }

    /// A key is a small letter tile, the same cream card as the words it builds.
    private func cardKey(_ face: String) -> some View {
        let isTwoLetter = face.count > 1
        let points = CardValues.points[face] ?? 0
        return Button {
            taps += 1
            onCard(face)
        } label: {
            ZStack(alignment: .bottomTrailing) {
                Text(face)
                    .font(.system(size: min(faceSize, 26) * (isTwoLetter ? 0.85 : 1),
                                  weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Text("\(points)")
                    .font(.system(size: min(pointSize, 12), weight: .bold, design: .rounded).monospacedDigit())
                    .opacity(0.7)
                    .padding(.trailing, 3)
                    .padding(.bottom, DS.Space.xxs)
            }
            .foregroundStyle(DS.Colors.tileInk)
        }
        .buttonStyle(KeyStyle(fill: DS.Colors.tileFace, isTile: true))
        .frame(height: keyHeight)
        // Spell two-letter cards out so VoiceOver reads "Q U", not a made-up word.
        .accessibilityLabel("\(face.map(String.init).joined(separator: " ")), \(points) points")
        .accessibilityShowsLargeContentViewer {
            Text("\(face) \(points)")
        }
    }

    private var backspaceKey: some View {
        Button {
            taps += 1
            onBackspace()
        } label: {
            Image(systemName: "delete.left")
                .font(.title3.weight(.medium))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(KeyStyle(fill: DS.Colors.surfaceSunken))
        .frame(height: keyHeight)
        .accessibilityLabel("Delete last card")
        .accessibilityShowsLargeContentViewer {
            Label("Delete", systemImage: "delete.left")
        }
    }

    private var nextWordKey: some View {
        Button {
            taps += 1
            onNextWord()
        } label: {
            Text("Next word")
                .font(.system(size: min(faceSize * 0.75, 19), weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(KeyStyle(fill: DS.Colors.surfaceSunken))
        .frame(height: keyHeight)
        .accessibilityHint("Starts a new word")
        .accessibilityShowsLargeContentViewer {
            Text("Next word")
        }
    }
}

/// A key that darkens while pressed, like the system keyboard. Card keys wear the tile
/// surface; the function keys sit flat in the sunken color.
private struct KeyStyle: ButtonStyle {
    let fill: Color
    var isTile = false

    @ViewBuilder
    func makeBody(configuration: Configuration) -> some View {
        if isTile {
            configuration.label
                .tileSurface(fill: fill, isPressed: configuration.isPressed)
                .contentShape(Rectangle())
        } else {
            configuration.label
                .foregroundStyle(Color.primary)
                .background(fill, in: RoundedRectangle.ds(DS.Radius.tile))
                .overlay {
                    RoundedRectangle.ds(DS.Radius.tile)
                        .fill(Color.primary.opacity(configuration.isPressed ? DS.Opacity.pressed : 0))
                }
                .contentShape(Rectangle())
        }
    }
}

/// Digits for "Type a score instead", in the same footprint and style as the card keypad,
/// so typing never brings up the system keyboard.
struct NumberPadView: View {
    var isNegative: Bool
    var onDigit: (Int) -> Void
    var onDelete: () -> Void
    var onToggleSign: () -> Void
    var keyHeight: CGFloat = DS.Size.key

    @State private var taps = 0
    @ScaledMetric(relativeTo: .title2) private var digitSize: CGFloat = 24

    var body: some View {
        Grid(horizontalSpacing: DS.Space.xs + 2, verticalSpacing: DS.Space.s) {
            ForEach([[1, 2, 3], [4, 5, 6], [7, 8, 9]], id: \.self) { row in
                GridRow {
                    ForEach(row, id: \.self, content: digitKey)
                }
            }
            GridRow {
                key(fill: isNegative ? DS.Colors.tint(DS.Colors.negative) : DS.Colors.surfaceSunken,
                    label: Image(systemName: "plus.forwardslash.minus")
                        .foregroundStyle(isNegative ? DS.Colors.negative : Color.primary),
                    action: onToggleSign)
                    .accessibilityLabel(isNegative ? "Negative score" : "Positive score")
                    .accessibilityHint("Switches the score between positive and negative")
                digitKey(0)
                key(fill: DS.Colors.surfaceSunken, label: Image(systemName: "delete.left"), action: onDelete)
                    .accessibilityLabel("Delete last digit")
            }
        }
        .sensoryFeedback(DS.Haptic.key, trigger: taps)
    }

    private func digitKey(_ digit: Int) -> some View {
        key(fill: DS.Colors.surface,
            label: Text("\(digit)").font(.system(size: min(digitSize, 30), weight: .medium, design: .rounded)),
            action: { onDigit(digit) })
            .accessibilityShowsLargeContentViewer { Text("\(digit)") }
    }

    private func key(fill: Color, label: some View, action: @escaping () -> Void) -> some View {
        Button {
            taps += 1
            action()
        } label: {
            label
                .font(.title3.weight(.medium))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(KeyStyle(fill: fill))
        .frame(height: keyHeight)
    }
}

#if DEBUG
#Preview("Keypad") {
    VStack(spacing: 24) {
        CardKeypadView(onCard: { _ in }, onNextWord: {}, onBackspace: {})
        NumberPadView(isNegative: false, onDigit: { _ in }, onDelete: {}, onToggleSign: {})
    }
    .padding()
    .dsCanvas()
}
#endif

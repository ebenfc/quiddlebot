import SwiftUI

/// The word calculator's keypad: letters where the iPhone keyboard has them, then the five
/// two-letter cards. Every key shows its point value small, like a tile.
struct CardKeypadView: View {
    var onCard: (String) -> Void
    var onNextWord: () -> Void
    var onBackspace: () -> Void
    /// Shorter on small screens such as the iPhone SE, so the words above stay in view.
    var keyHeight: CGFloat = 44

    private static let letterRows: [[String]] = [
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
        ["Z", "X", "C", "V", "B", "N", "M"],
    ]
    private static let twoLetterCards = ["QU", "IN", "ER", "CL", "TH"]

    private let gap: CGFloat = 5
    private let rowGap: CGFloat = 8

    @State private var taps = 0

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
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.6), trigger: taps)
    }

    private func letterRow(_ faces: [String], key: CGFloat) -> some View {
        HStack(spacing: gap) {
            ForEach(faces, id: \.self) { face in
                cardKey(face).frame(width: key)
            }
        }
    }

    private func cardKey(_ face: String) -> some View {
        let isTwoLetter = face.count > 1
        let points = CardValues.points[face] ?? 0
        return Button {
            taps += 1
            onCard(face)
        } label: {
            ZStack(alignment: .bottomTrailing) {
                Text(face)
                    .font(.system(size: isTwoLetter ? 17 : 20, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Text("\(points)")
                    .font(.system(size: 9, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .padding(.trailing, 3)
                    .padding(.bottom, 2)
            }
            .foregroundStyle(isTwoLetter ? Color.accentColor : Color.primary)
        }
        .buttonStyle(KeyStyle(fill: isTwoLetter ? Color.accentColor.opacity(0.16) : Color(.secondarySystemGroupedBackground)))
        .frame(height: keyHeight)
        // Spell two-letter cards out so VoiceOver reads "Q U", not a made-up word.
        .accessibilityLabel("\(face.map(String.init).joined(separator: " ")), \(points) points")
    }

    private var backspaceKey: some View {
        Button {
            taps += 1
            onBackspace()
        } label: {
            Image(systemName: "delete.left")
                .font(.system(size: 18, weight: .medium))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(KeyStyle(fill: Color(.tertiarySystemFill)))
        .frame(height: keyHeight)
        .accessibilityLabel("Delete last card")
    }

    private var nextWordKey: some View {
        Button {
            taps += 1
            onNextWord()
        } label: {
            Text("Next word")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(KeyStyle(fill: Color(.tertiarySystemFill)))
        .frame(height: keyHeight)
    }
}

/// A key that darkens while pressed, like the system keyboard.
private struct KeyStyle: ButtonStyle {
    let fill: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(fill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.primary.opacity(configuration.isPressed ? 0.12 : 0))
            }
            .shadow(color: .black.opacity(0.12), radius: 0, x: 0, y: 1)
            .contentShape(Rectangle())
    }
}

/// Digits for "Type a score instead", in the same footprint and style as the card keypad,
/// so typing never brings up the system keyboard.
struct NumberPadView: View {
    var isNegative: Bool
    var onDigit: (Int) -> Void
    var onDelete: () -> Void
    var onToggleSign: () -> Void
    var keyHeight: CGFloat = 44

    @State private var taps = 0

    var body: some View {
        Grid(horizontalSpacing: 6, verticalSpacing: 8) {
            ForEach([[1, 2, 3], [4, 5, 6], [7, 8, 9]], id: \.self) { row in
                GridRow {
                    ForEach(row, id: \.self, content: digitKey)
                }
            }
            GridRow {
                key(fill: isNegative ? Color.red.opacity(0.16) : Color(.tertiarySystemFill),
                    label: Image(systemName: "plus.forwardslash.minus")
                        .foregroundStyle(isNegative ? Color.red : Color.primary),
                    action: onToggleSign)
                    .accessibilityLabel(isNegative ? "Negative score" : "Positive score")
                    .accessibilityHint("Switches the score between positive and negative")
                digitKey(0)
                key(fill: Color(.tertiarySystemFill), label: Image(systemName: "delete.left"), action: onDelete)
                    .accessibilityLabel("Delete last digit")
            }
        }
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.6), trigger: taps)
    }

    private func digitKey(_ digit: Int) -> some View {
        key(fill: Color(.secondarySystemGroupedBackground),
            label: Text("\(digit)").font(.system(size: 24, weight: .medium, design: .rounded)),
            action: { onDigit(digit) })
    }

    private func key(fill: Color, label: some View, action: @escaping () -> Void) -> some View {
        Button {
            taps += 1
            action()
        } label: {
            label
                .font(.system(size: 20, weight: .medium))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(KeyStyle(fill: fill))
        .frame(height: keyHeight)
    }
}

/// One card in a word or the leftover tray: its face and, small, its points.
/// A plain rounded tile; the app never reproduces the game's card art.
struct CardTile: View {
    let face: String
    var tint: Color = .accentColor

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Text(face)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .frame(width: face.count > 1 ? 42 : 32, height: 42)
            Text("\(CardValues.points[face] ?? 0)")
                .font(.system(size: 9, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.secondary)
                .padding(.trailing, 3)
                .padding(.bottom, 2)
        }
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(tint.opacity(0.35), lineWidth: 1)
        }
    }
}

#if DEBUG
#Preview("Keypad") {
    VStack(spacing: 24) {
        CardKeypadView(onCard: { _ in }, onNextWord: {}, onBackspace: {})
        NumberPadView(isNegative: false, onDigit: { _ in }, onDelete: {}, onToggleSign: {})
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
#endif

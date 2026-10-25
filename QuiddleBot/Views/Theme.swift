import SwiftUI

/// The app's small design system: colors, card surfaces, avatars and buttons.
/// Every screen draws from here so the look stays consistent.
enum Theme {
    /// Bonuses and the current leader. Defined in the asset catalog with a dark variant.
    static let gold = Color("Gold")

    static let cornerRadius: CGFloat = 22

    /// One color per seat, chosen to stay clear of the indigo accent and the gold.
    static let playerColors: [Color] = [
        Color(red: 0.91, green: 0.36, blue: 0.27), // coral
        Color(red: 0.18, green: 0.62, blue: 0.34), // green
        Color(red: 0.00, green: 0.58, blue: 0.75), // cyan
        Color(red: 0.78, green: 0.27, blue: 0.62), // magenta
    ]

    static func playerColor(_ index: Int) -> Color {
        playerColors[index % playerColors.count]
    }
}

/// A raised card: grouped-background surface, continuous corners, a soft shadow in light mode.
struct CardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.06), radius: 14, x: 0, y: 6)
    }
}

extension View {
    func card(padding: CGFloat = 16) -> some View {
        modifier(CardModifier(padding: padding))
    }
}

/// A colored circle with the player's initial, so each player is recognisable at a glance.
struct PlayerAvatar: View {
    let name: String
    let index: Int
    var size: CGFloat = 34

    var body: some View {
        Text(initial)
            .font(.system(size: size * 0.46, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Theme.playerColor(index).gradient, in: Circle())
            .accessibilityHidden(true)
    }

    private var initial: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.first.map { String($0).uppercased() } ?? "?"
    }
}

/// The screen's main action: a full-width capsule in the accent color.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(isEnabled ? Color.white : Color.secondary)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background {
                if isEnabled {
                    Capsule().fill(Color.accentColor.gradient)
                } else {
                    Capsule().fill(Color(.tertiarySystemFill))
                }
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

/// A quieter companion to the primary button.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.accentColor)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(Capsule().fill(Color.accentColor.opacity(0.12)))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

/// A bar pinned to the bottom of the screen for the main action, so it is always in reach.
struct BottomActionBar<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 8) { content }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(.bar)
    }
}

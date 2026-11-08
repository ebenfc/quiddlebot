import SwiftUI

/// QuiddleBot's design system, "Card Table": felt green, bonus gold and cream letter tiles.
/// Every token is named for its role, never its hue. The Design System artifact on claude.ai
/// documents the same names and values; `scripts/make-colors.py` writes the color assets.
nonisolated enum DS {}

extension DS {
    /// Colors come from the asset catalog, which carries light, dark and Increase Contrast
    /// variants of each. A fill and the text drawn on it are always a pair (`accent` and
    /// `onAccent`), so every pairing clears 4.5:1.
    nonisolated enum Colors {
        // Brand
        static let accent = Color("DSAccent")
        static let onAccent = Color("DSOnAccent")

        // Bonus gold: a bright fill with dark ink on it, and a deeper shade for gold text.
        static let bonusFill = Color("DSBonusFill")
        static let onBonus = Color("DSOnBonus")
        static let bonusText = Color("DSBonusText")

        // Surfaces
        static let canvas = Color("DSCanvas")
        static let surface = Color("DSSurface")
        static let surfaceSunken = Color("DSSurfaceSunken")
        static let outline = Color("DSOutline")

        // Letter tiles: cream in both appearances, like the cards on the table.
        static let tileFace = Color("DSTileFace")
        static let tileEdge = Color("DSTileEdge")
        static let tileInk = Color("DSTileInk")

        // Status
        static let positive = Color("DSPositive")
        static let warning = Color("DSWarning")
        static let negative = Color("DSNegative")

        // Seats, with the ink that reads on every one of them.
        static let players: [Color] = [Color("DSPlayer1"), Color("DSPlayer2"),
                                       Color("DSPlayer3"), Color("DSPlayer4")]
        static let onPlayer = Color("DSOnPlayer")

        // Medals for the final standings; `onBonus` reads on all three.
        static let silver = Color("DSSilver")
        static let bronze = Color("DSBronze")

        static func player(_ seat: Int) -> Color {
            players[((seat % players.count) + players.count) % players.count]
        }

        /// A wash of a color behind text or a mark in that color's text role.
        static func tint(_ color: Color) -> Color {
            color.opacity(DS.Opacity.tint)
        }

        static func status(_ tone: StatusTone) -> Color {
            switch tone {
            case .positive: positive
            case .warning: warning
            case .negative: negative
            case .accent: accent
            case .neutral: .secondary
            }
        }
    }

    nonisolated enum Opacity {
        /// Every tinted background: badges, notices, the leader's row.
        static let tint = 0.18
        /// Players not yet reached in the round counter's strip.
        static let dimmed = 0.45
        /// The darkening on a pressed key.
        static let pressed = 0.12
    }
}

/// What a mark or note means. Never shown by color alone: each use pairs it with a symbol.
nonisolated enum StatusTone: Sendable {
    case positive, warning, negative, accent, neutral
}

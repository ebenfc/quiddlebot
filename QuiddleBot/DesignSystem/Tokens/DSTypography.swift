import SwiftUI

extension DS {
    /// Text styles, all on Dynamic Type. SF Rounded is applied once at each root
    /// (`.fontDesign(.rounded)`), so these never name a design.
    nonisolated enum Typography {
        /// Screen titles: "Round 4", "Ada wins!".
        static let screenTitle = Font.largeTitle.bold()
        /// The line under a screen title.
        static let screenSubtitle = Font.subheadline
        /// A card's heading: "Scorecard", "Highlights".
        static let sectionTitle = Font.title3.bold()
        /// A player's name in a row.
        static let rowTitle = Font.headline
        /// Bonus names and other short labels.
        static let label = Font.subheadline.weight(.semibold)
        static let detail = Font.subheadline
        static let caption = Font.caption
        static let footnote = Font.footnote
        /// Gold "+10" pills and other values in a capsule.
        static let badge = Font.caption.weight(.bold).monospacedDigit()
    }
}

/// The sizes a score is shown at. Every score in the app is one of these, through `ScoreNumeral`.
nonisolated enum ScoreStyle: Sendable {
    /// The hand being counted.
    case hero
    /// Running totals and final standings.
    case large
    /// A player's score in the round summary.
    case medium
    /// A word's points.
    case small
    /// A scorecard cell.
    case cell
    /// The scorecard's totals row.
    case cellTotal

    var font: Font {
        switch self {
        case .hero: .largeTitle.weight(.bold).monospacedDigit()
        case .large: .title2.weight(.bold).monospacedDigit()
        case .medium: .title3.weight(.bold).monospacedDigit()
        case .small: .headline.monospacedDigit()
        case .cell: .body.monospacedDigit()
        case .cellTotal: .body.weight(.bold).monospacedDigit()
        }
    }
}

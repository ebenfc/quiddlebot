import SwiftUI

extension DS {
    /// The spacing scale. Stacks, padding and gaps use these and nothing in between.
    nonisolated enum Space {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        /// Side margin of every screen.
        static let screen: CGFloat = 20
    }

    /// Corner radii, always with continuous corners.
    nonisolated enum Radius {
        /// Letter tiles and keypad keys.
        static let tile: CGFloat = 8
        /// Rows, fields and notices inside a card.
        static let control: CGFloat = 14
        /// Cards.
        static let card: CGFloat = 22
    }

    /// Fixed sizes that set rhythm and reach.
    nonisolated enum Size {
        /// The smallest tap target anywhere.
        static let minTap: CGFloat = 44
        /// Primary and secondary buttons.
        static let button: CGFloat = 54
        /// A letter tile at the default text size.
        static let tile: CGFloat = 42
        static let key: CGFloat = 44
        static let keyCompact: CGFloat = 40
        /// Screens shorter than this (iPhone SE) use the compact counter.
        static let compactHeight: CGFloat = 700
    }

    /// Player avatar diameters.
    nonisolated enum Avatar {
        static let tiny: CGFloat = 20
        static let small: CGFloat = 26
        static let strip: CGFloat = 28
        static let regular: CGFloat = 34
        static let large: CGFloat = 40
    }
}

extension RoundedRectangle {
    /// A rounded rectangle with the design system's continuous corners.
    static func ds(_ radius: CGFloat) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }
}

import SwiftUI

extension DS {
    /// Animation tokens. Everything that moves goes through these, and through the Reduce
    /// Motion helpers below, so the app calms down in one place.
    nonisolated enum Motion {
        /// State changes: a score updating, a row appearing.
        static let standard: Animation = .snappy
        /// Small toggles: a chip being picked.
        static let quick: Animation = .snappy(duration: 0.2)
        /// A button being pressed.
        static let press: Animation = .snappy(duration: 0.18)
        static let pressScale: CGFloat = 0.97
        /// The end-of-game confetti.
        static let celebration: TimeInterval = 4

        /// For `withAnimation` around scrolling and other large movement: none at all when
        /// Reduce Motion is on.
        static func movement(reduceMotion: Bool) -> Animation? {
            reduceMotion ? nil : standard
        }
    }

    /// Haptic tokens, for `.sensoryFeedback`.
    nonisolated enum Haptic {
        /// A keypad key: soft, like the system keyboard.
        static let key: SensoryFeedback = .impact(flexibility: .soft, intensity: 0.6)
        /// Picking one of several options.
        static let select: SensoryFeedback = .selection
        /// A round saved, a game won.
        static let success: SensoryFeedback = .success
    }
}

/// Swaps a movement transition for a plain fade when Reduce Motion is on.
private struct MotionSafeTransition: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let transition: AnyTransition

    func body(content: Content) -> some View {
        content.transition(reduceMotion ? .opacity : transition)
    }
}

extension View {
    /// `.transition(_:)` that becomes a fade under Reduce Motion.
    func motionSafeTransition(_ transition: AnyTransition) -> some View {
        modifier(MotionSafeTransition(transition: transition))
    }
}

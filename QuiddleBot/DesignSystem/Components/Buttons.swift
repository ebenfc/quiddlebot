import SwiftUI

/// The screen's main action: a full-width accent capsule. On iOS 26 it sits on Liquid Glass,
/// so it reacts to touch like the system's own controls; the solid fill keeps the label at
/// full contrast whatever is behind it.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ViewBuilder
    func makeBody(configuration: Configuration) -> some View {
        let label = configuration.label
            .font(.headline)
            .foregroundStyle(isEnabled ? DS.Colors.onAccent : Color.secondary)
            .frame(maxWidth: .infinity, minHeight: DS.Size.button)
            .background(isEnabled ? DS.Colors.accent : DS.Colors.surfaceSunken, in: Capsule())
            .contentShape(Capsule())

        if #available(iOS 26, *) {
            if isEnabled {
                label.glassEffect(.regular.tint(DS.Colors.accent).interactive(), in: Capsule())
            } else {
                label
            }
        } else {
            label
                .scaleEffect(configuration.isPressed && !reduceMotion ? DS.Motion.pressScale : 1)
                .animation(DS.Motion.press, value: configuration.isPressed)
        }
    }
}

/// A quieter companion to the primary button: accent text on clear glass (iOS 26) or on an
/// accent wash (earlier).
struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ViewBuilder
    func makeBody(configuration: Configuration) -> some View {
        let label = configuration.label
            .font(.headline)
            .foregroundStyle(DS.Colors.accent)
            .frame(maxWidth: .infinity, minHeight: DS.Size.button)
            .contentShape(Capsule())

        if #available(iOS 26, *) {
            label.glassEffect(.regular.interactive(), in: Capsule())
        } else {
            label
                .background(DS.Colors.tint(DS.Colors.accent), in: Capsule())
                .scaleEffect(configuration.isPressed && !reduceMotion ? DS.Motion.pressScale : 1)
                .animation(DS.Motion.press, value: configuration.isPressed)
        }
    }
}

/// The bar pinned to the bottom of a screen for its main action, so it is always in reach.
struct BottomActionBar<Content: View>: View {
    /// A solid backing. Off on iOS 26 for plain button bars, which float on glass over the
    /// content; on for the keypad, which needs a steady ground under its keys.
    var isSolid = true
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: DS.Space.s) { content }
            .padding(.horizontal, DS.Space.screen)
            .padding(.top, DS.Space.m)
            .padding(.bottom, DS.Space.s)
            .background {
                if isSolid {
                    Rectangle().fill(.bar).ignoresSafeArea()
                }
            }
    }
}

private struct BottomActionBarModifier<Bar: View>: ViewModifier {
    let keepsSolidBacking: Bool
    @ViewBuilder let bar: () -> Bar

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            if keepsSolidBacking {
                solid(content)
            } else {
                // A safe-area bar gets the scroll edge effect, which keeps the hint text
                // legible as cards scroll under the glass button.
                content.safeAreaBar(edge: .bottom) {
                    BottomActionBar(isSolid: false) { bar() }
                }
            }
        } else {
            solid(content)
        }
    }

    private func solid(_ content: Content) -> some View {
        content.safeAreaInset(edge: .bottom) {
            BottomActionBar(isSolid: true) { bar() }
        }
    }
}

extension View {
    /// Pins a `BottomActionBar` to the bottom of the screen.
    func bottomActionBar<Bar: View>(solid: Bool = false,
                                    @ViewBuilder _ bar: @escaping () -> Bar) -> some View {
        modifier(BottomActionBarModifier(keepsSolidBacking: solid, bar: bar))
    }
}

extension DS {
    /// SF Symbols whose best form differs by iOS version.
    nonisolated enum Symbol {
        /// A toolbar "more" button. iOS 26 draws its own glass circle, so the symbol drops its own.
        static var more: String {
            if #available(iOS 26, *) {
                return "ellipsis"
            }
            return "ellipsis.circle"
        }
    }
}

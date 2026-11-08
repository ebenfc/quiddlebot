import SwiftUI

/// A raised card: the surface color, continuous corners, a soft shadow in light mode and a
/// hairline edge in dark mode, where shadows don't show.
struct CardSurface: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    var padding: CGFloat = DS.Space.l

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Colors.surface, in: RoundedRectangle.ds(DS.Radius.card))
            .overlay {
                if colorScheme == .dark {
                    RoundedRectangle.ds(DS.Radius.card)
                        .strokeBorder(DS.Colors.outline.opacity(0.6), lineWidth: 1)
                }
            }
            .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.06), radius: 14, x: 0, y: 6)
    }
}

extension View {
    func dsCard(padding: CGFloat = DS.Space.l) -> some View {
        modifier(CardSurface(padding: padding))
    }

    /// The screen background behind every card.
    func dsCanvas() -> some View {
        background { DS.Colors.canvas.ignoresSafeArea() }
    }

    /// The ring that marks what is selected: the word being built, the leftover tray.
    func selectionOutline(_ isSelected: Bool, radius: CGFloat, color: Color = DS.Colors.accent) -> some View {
        overlay {
            RoundedRectangle.ds(radius)
                .strokeBorder(color, lineWidth: isSelected ? 2 : 0)
        }
    }
}

/// A short note inside a screen: a one-card word, a typed score. Symbol plus text, never
/// color alone, with an optional action on the trailing side.
struct NoticeBanner: View {
    let text: String
    var systemImage: String
    var tone: StatusTone = .neutral
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: DS.Space.m) {
            Image(systemName: systemImage)
                .foregroundStyle(DS.Colors.status(tone))
                .accessibilityHidden(true)
            Text(text)
                .font(DS.Typography.detail)
                .foregroundStyle(tone == .neutral ? Color.secondary : Color.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(DS.Typography.label)
                    .buttonStyle(.borderless)
                    .frame(minHeight: DS.Size.minTap)
            }
        }
        .padding(.horizontal, DS.Space.l)
        .padding(.vertical, DS.Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tone == .neutral ? DS.Colors.surface : DS.Colors.tint(DS.Colors.status(tone)),
                    in: RoundedRectangle.ds(DS.Radius.control))
    }
}

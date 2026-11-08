import SwiftUI

#if DEBUG
/// The design system in one scroll, in the same order as the Design System artifact on
/// claude.ai, so the two can be checked side by side. Open in the canvas in light and dark,
/// and with Increase Contrast on.
private struct DesignSystemCatalog: View {
    private let names = ["Ada", "Ben", "Bea", "Cy"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.xxl) {
                ScreenTitle(title: "Card Table", subtitle: "QuiddleBot design system")

                section("Color") {
                    swatchRow([("accent", DS.Colors.accent), ("bonusFill", DS.Colors.bonusFill),
                               ("canvas", DS.Colors.canvas), ("surface", DS.Colors.surface)])
                    swatchRow([("positive", DS.Colors.positive), ("warning", DS.Colors.warning),
                               ("negative", DS.Colors.negative), ("tileFace", DS.Colors.tileFace)])
                    swatchRow(DS.Colors.players.enumerated().map { ("player \($0.offset + 1)", $0.element) })
                }

                section("Type") {
                    Text("Round 4").font(DS.Typography.screenTitle)
                    Text("Scorecard").font(DS.Typography.sectionTitle)
                    Text("Ada").font(DS.Typography.rowTitle)
                    Text("Longest word").font(DS.Typography.label)
                    HStack(alignment: .firstTextBaseline, spacing: DS.Space.l) {
                        ScoreNumeral(38, style: .hero)
                        ScoreNumeral(112, style: .large)
                        ScoreNumeral(24, style: .medium)
                        ScoreNumeral(9, style: .small)
                        ScoreNumeral(7, style: .cell)
                    }
                }

                section("Tiles") {
                    HStack(spacing: DS.Space.xs) {
                        ForEach(["QU", "I", "Z"], id: \.self) { LetterTile(face: $0) }
                        LetterTile(face: "X", tone: .leftover)
                    }
                    CardKeypadView(onCard: { _ in }, onNextWord: {}, onBackspace: {})
                }

                section("Players") {
                    HStack(spacing: DS.Space.s) {
                        ForEach(names.indices, id: \.self) { PlayerAvatar(seat: $0, in: names) }
                        ForEach(1...4, id: \.self) { RankMedal(rank: $0) }
                    }
                    VStack(spacing: DS.Space.xs) {
                        PlayerScoreRow(names: names, seat: 0, total: 112, detail: "+18 last round",
                                       isLeader: true, showsCrown: true)
                        PlayerScoreRow(names: names, seat: 1, total: 97, detail: "+9 last round")
                    }
                    .dsCard(padding: DS.Space.s)
                }

                section("Badges and choices") {
                    HStack {
                        ValueBadge(text: "+10")
                        ValueBadge(text: "6 letters", systemImage: "star.fill")
                    }
                    BonusHeaderRow(title: "Longest word", detail: "Ada · QUIZ · 4 letters") {
                        ValueBadge(text: "+10")
                    }
                    HStack(spacing: DS.Space.s) {
                        SelectableChip(title: "Ada", isSelected: true, fill: DS.Colors.player(0),
                                       onFill: DS.Colors.onPlayer, showsDot: true) {}
                        SelectableChip(title: "Ben", isSelected: false, fill: DS.Colors.player(1),
                                       onFill: DS.Colors.onPlayer, showsDot: true,
                                       badge: ("sparkles", "suggested")) {}
                        SelectableChip(title: "Tie / none", isSelected: false) {}
                    }
                    NoticeBanner(text: "“Q” is one card. Words need at least two.",
                                 systemImage: "exclamationmark.triangle.fill", tone: .warning,
                                 actionTitle: "Move to leftovers") {}
                    HStack {
                        StatTile(value: "8", label: "rounds")
                        StatTile(value: "+10", label: "per bonus", isBonus: true)
                    }
                }

                section("Buttons") {
                    Button("Next Round") {}.buttonStyle(PrimaryButtonStyle())
                    Button("Finish Game") {}.buttonStyle(PrimaryButtonStyle()).disabled(true)
                    Button("New Players") {}.buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding(DS.Space.screen)
        }
        .dsCanvas()
        .fontDesign(.rounded)
        .tint(DS.Colors.accent)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            SectionHeader(title: title)
            content()
        }
        .dsCard()
    }

    private func swatchRow(_ swatches: [(String, Color)]) -> some View {
        HStack(spacing: DS.Space.s) {
            ForEach(swatches.indices, id: \.self) { index in
                VStack(spacing: DS.Space.xs) {
                    RoundedRectangle.ds(DS.Radius.control)
                        .fill(swatches[index].1)
                        .overlay {
                            RoundedRectangle.ds(DS.Radius.control)
                                .strokeBorder(DS.Colors.outline, lineWidth: 1)
                        }
                        .frame(height: 44)
                    Text(swatches[index].0)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview("Design system") {
    DesignSystemCatalog()
}

#Preview("Design system, dark") {
    DesignSystemCatalog()
        .preferredColorScheme(.dark)
}
#endif

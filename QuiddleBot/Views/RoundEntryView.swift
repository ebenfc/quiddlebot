import SwiftUI

/// The round at a glance: each player's counted words and score, and the bonuses the cards
/// decided. Tapping a player opens the round counter on them; the main "Count Hands" button
/// lives in GameView's bottom bar so it is always in reach.
struct RoundEntryView: View {
    let game: Game
    let isEditing: Bool
    @Binding var draft: RoundDraft
    /// Opens the round counter on a player.
    var onCount: (Int) -> Void

    private var rules: RuleSet { game.rules }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.l) {
            SectionHeader(title: isEditing ? "Fix the scores" : "Scores this round",
                          subtitle: "Count each player's cards. QuiddleBot adds them up and picks the bonuses.")

            VStack(spacing: DS.Space.xxs) {
                ForEach(game.players.indices, id: \.self) { player in
                    PlayerRow(names: game.players, player: player, rules: rules,
                              draft: draft, onTap: { onCount(player) })
                }
            }

            if rules.longestWordEnabled || rules.mostWordsEnabled {
                Divider()
            }
            if rules.longestWordEnabled {
                BonusResultRow(title: "Longest word", bonus: rules.bonusValue,
                               players: game.players,
                               selection: Binding(get: { draft.effectiveLongestWord },
                                                  set: { draft.pickLongestWord($0) }),
                               suggestion: draft.suggestedLongestWord,
                               reason: draft.longestWordReason(names: game.players),
                               isWaiting: !draft.uncountedPlayers.isEmpty)
            }
            if rules.mostWordsEnabled {
                BonusResultRow(title: "Most words", bonus: rules.bonusValue,
                               players: game.players,
                               selection: Binding(get: { draft.effectiveMostWords },
                                                  set: { draft.pickMostWords($0) }),
                               suggestion: draft.suggestedMostWords,
                               reason: draft.mostWordsReason(names: game.players),
                               isWaiting: !draft.uncountedPlayers.isEmpty)
            }
        }
        .dsCard()
    }

    /// One player: their words or "Not counted yet", notes about the score, and the score.
    private struct PlayerRow: View {
        let names: [String]
        let player: Int
        let rules: RuleSet
        let draft: RoundDraft
        var onTap: () -> Void

        private var name: String { names[player] }

        var body: some View {
            Button(action: onTap) {
                HStack(spacing: DS.Space.m) {
                    PlayerAvatar(seat: player, in: names)

                    VStack(alignment: .leading, spacing: DS.Space.xxs) {
                        HStack(spacing: DS.Space.xs + 2) {
                            Text(name)
                                .font(DS.Typography.rowTitle)
                                .lineLimit(1)
                            if bonusTotal > 0 {
                                ValueBadge(text: "+\(bonusTotal)", systemImage: "star.fill",
                                           accessibilityText: "\(bonusTotal) bonus points")
                                    .motionSafeTransition(.scale(scale: 0.6).combined(with: .opacity))
                            }
                        }
                        Text(detail)
                            .font(DS.Typography.detail)
                            .foregroundStyle(score == nil ? DS.Colors.accent : Color.secondary)
                            .lineLimit(2)
                        ForEach(notes, id: \.self) { note in
                            Label(note, systemImage: "exclamationmark.circle.fill")
                                .font(DS.Typography.caption.weight(.semibold))
                                .foregroundStyle(DS.Colors.warning)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if let score {
                        ScoreNumeral(score, style: .medium)
                    }
                    Image(systemName: "chevron.right")
                        .font(DS.Typography.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                .padding(.vertical, DS.Space.s)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .animation(DS.Motion.standard, value: bonusTotal)
            .accessibilityElement(children: .combine)
            .accessibilityHint(score == nil ? "Counts \(name)'s cards" : "Recounts \(name)'s cards")
        }

        private var score: Int? { draft.score(for: player) }

        /// The words as they read ("QUIZ · THE · left R"), "Typed score", or "Not counted yet".
        private var detail: String {
            if let hand = draft.countedHand(for: player) {
                var parts = hand.words.map(\.text)
                if !hand.leftovers.isEmpty {
                    parts.append("left \(hand.leftovers.joined(separator: " "))")
                }
                return parts.isEmpty ? "No words" : parts.joined(separator: " · ")
            }
            return score == nil ? "Not counted yet" : "Typed score"
        }

        private var notes: [String] {
            var notes: [String] = []
            if rules.floorHandAtZero, let score, score < 0 { notes.append("Counts as 0") }
            let penalty = draft.penalty(for: player)
            if penalty > 0 { notes.append("−\(penalty) lost challenge") }
            return notes
        }

        private var bonusTotal: Int {
            var total = 0
            if rules.longestWordEnabled, draft.effectiveLongestWord == .player(player) { total += rules.bonusValue }
            if rules.mostWordsEnabled, draft.effectiveMostWords == .player(player) { total += rules.bonusValue }
            return total
        }
    }

    /// One bonus as a result: who the cards picked and why, with Change for an override.
    /// Falls back to the chip picker when a score was typed or the scorekeeper overrode it.
    private struct BonusResultRow: View {
        let title: String
        let bonus: Int
        let players: [String]
        @Binding var selection: BonusAward
        let suggestion: BonusAward?
        let reason: String?
        /// Someone has no score yet, so the cards can't decide.
        let isWaiting: Bool

        @State private var isChanging = false

        var body: some View {
            Group {
                if let suggestion, let reason, selection == suggestion, !isChanging {
                    result(suggestion, reason: reason)
                } else if suggestion == nil && isWaiting {
                    waiting
                } else {
                    VStack(alignment: .leading, spacing: DS.Space.s) {
                        if suggestion == nil {
                            Text("A score was typed, so pick this bonus yourself.")
                                .font(DS.Typography.caption)
                                .foregroundStyle(.secondary)
                        }
                        BonusPickerView(title: title, bonus: bonus, players: players,
                                        selection: $selection, suggestion: suggestion)
                    }
                }
            }
            .animation(DS.Motion.standard, value: isChanging)
        }

        private func result(_ award: BonusAward, reason: String) -> some View {
            BonusHeaderRow(title: title,
                           detail: winner(award).map { "\($0) · \(reason)" } ?? reason) {
                if winner(award) != nil {
                    ValueBadge(text: "+\(bonus)", accessibilityText: "\(bonus) points")
                }
                Button("Change") { isChanging = true }
                    .font(DS.Typography.label)
                    .buttonStyle(.borderless)
                    .frame(minHeight: DS.Size.minTap)
                    .accessibilityHint("Pick who gets the \(title.lowercased()) bonus yourself")
            }
            .accessibilityElement(children: .combine)
        }

        private var waiting: some View {
            BonusHeaderRow(title: title, isDecided: false) {
                Text("Picked from the cards")
                    .font(DS.Typography.caption)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
        }

        private func winner(_ award: BonusAward) -> String? {
            if case .player(let player) = award { return players[player] }
            return nil
        }
    }
}

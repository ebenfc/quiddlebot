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
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(isEditing ? "Fix the scores" : "Scores this round")
                    .font(.title3.bold())
                Text("Count each player's cards. QuiddleBot adds them up and picks the bonuses.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 2) {
                ForEach(game.players.indices, id: \.self) { player in
                    PlayerRow(name: game.players[player], player: player, rules: rules,
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
        .card()
    }

    /// One player: their words or "Not counted yet", notes about the score, and the score.
    private struct PlayerRow: View {
        let name: String
        let player: Int
        let rules: RuleSet
        let draft: RoundDraft
        var onTap: () -> Void

        var body: some View {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    PlayerAvatar(name: name, index: player)

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(name)
                                .font(.body.weight(.semibold))
                                .lineLimit(1)
                            if bonusTotal > 0 {
                                Text("★ +\(bonusTotal)")
                                    .font(.caption.weight(.bold).monospacedDigit())
                                    .foregroundStyle(Theme.gold)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2)
                                    .background(Theme.gold.opacity(0.15), in: Capsule())
                                    .transition(.scale(scale: 0.6).combined(with: .opacity))
                            }
                        }
                        Text(detail)
                            .font(.subheadline)
                            .foregroundStyle(score == nil ? Color.accentColor : Color.secondary)
                            .lineLimit(1)
                        ForEach(notes, id: \.self) { note in
                            Text(note)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.orange)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if let score {
                        Text(score, format: .number)
                            .font(.title3.weight(.bold).monospacedDigit())
                            .contentTransition(.numericText(value: Double(score)))
                    }
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .animation(.snappy, value: bonusTotal)
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
                    VStack(alignment: .leading, spacing: 8) {
                        if suggestion == nil {
                            Text("A score was typed, so pick this bonus yourself.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        BonusPickerView(title: title, bonus: bonus, players: players,
                                        selection: $selection, suggestion: suggestion)
                    }
                }
            }
            .animation(.snappy, value: isChanging)
        }

        private func result(_ award: BonusAward, reason: String) -> some View {
            HStack(spacing: 10) {
                Image(systemName: "star.fill")
                    .foregroundStyle(Theme.gold)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Text(winner(award).map { "\($0) · \(reason)" } ?? reason)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if winner(award) != nil {
                    Text("+\(bonus)")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(Theme.gold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.gold.opacity(0.15), in: Capsule())
                }
                Button("Change") { isChanging = true }
                    .font(.subheadline.weight(.semibold))
                    .buttonStyle(.borderless)
                    .accessibilityHint("Pick who gets the \(title.lowercased()) bonus yourself")
            }
            .accessibilityElement(children: .combine)
        }

        private var waiting: some View {
            HStack(spacing: 10) {
                Image(systemName: "star")
                    .foregroundStyle(Theme.gold)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("Picked from the cards")
                    .font(.caption)
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

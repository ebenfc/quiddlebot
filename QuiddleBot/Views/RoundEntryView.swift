import SwiftUI

/// Which score field has the keyboard. Owned by GameView so the pinned action bar
/// can step aside while someone is typing.
enum EntryField: Hashable {
    case score(Int)
    case penalty(Int)
}

/// Score entry for one round: a score per player and the bonus picks.
/// The submit button lives in GameView's bottom bar so it is always in reach.
struct RoundEntryView: View {
    let game: Game
    let roundNumber: Int
    let isEditing: Bool
    @Binding var draft: RoundDraft
    var focusedField: FocusState<EntryField?>.Binding

    private var rules: RuleSet { game.rules }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text(isEditing ? "Fix the scores" : "Scores this round")
                    .font(.title3.bold())
                Text("Word points minus leftover cards. Tap + to switch to a negative hand.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 14) {
                ForEach(game.players.indices, id: \.self) { player in
                    ScoreRow(name: game.players[player],
                             player: player,
                             rules: rules,
                             draft: $draft,
                             focusedField: focusedField)
                }
            }

            if rules.longestWordEnabled || rules.mostWordsEnabled {
                Divider()
            }
            if rules.longestWordEnabled {
                BonusPickerView(title: "Longest word", bonus: rules.bonusValue,
                                players: game.players, selection: $draft.longestWord)
            }
            if rules.mostWordsEnabled {
                BonusPickerView(title: "Most words", bonus: rules.bonusValue,
                                players: game.players, selection: $draft.mostWords)
            }
        }
        .card()
        .toolbar {
            // The number pad has no Return key, so give the keyboard its own navigation.
            ToolbarItemGroup(placement: .keyboard) {
                Button("Previous player", systemImage: "chevron.up") { moveFocus(by: -1) }
                    .disabled(!canMoveFocus(by: -1))
                Button("Next player", systemImage: "chevron.down") { moveFocus(by: 1) }
                    .disabled(!canMoveFocus(by: 1))
                Spacer()
                Button("Done") { focusedField.wrappedValue = nil }
            }
        }
    }

    private func canMoveFocus(by delta: Int) -> Bool {
        guard case .score(let player) = focusedField.wrappedValue else { return false }
        return game.players.indices.contains(player + delta)
    }

    private func moveFocus(by delta: Int) {
        guard case .score(let player) = focusedField.wrappedValue else { return }
        focusedField.wrappedValue = .score(player + delta)
    }

    /// One player's row: avatar and name, live notes about bonuses, sign toggle, score, challenge flag.
    private struct ScoreRow: View {
        let name: String
        let player: Int
        let rules: RuleSet
        @Binding var draft: RoundDraft
        var focusedField: FocusState<EntryField?>.Binding

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    PlayerAvatar(name: name, index: player)

                    VStack(alignment: .leading, spacing: 2) {
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
                                .accessibilityLabel("\(bonusNames) bonus, plus \(bonusTotal)")
                        }
                        if countsAsZero {
                            Text("Counts as 0")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .transition(.opacity)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .animation(.snappy, value: bonusTotal)
                    .animation(.snappy, value: countsAsZero)

                    signButton

                    NumberField(placeholder: "pts",
                                text: $draft.scoreText[player],
                                isFocused: focusedField.wrappedValue == .score(player))
                        .focused(focusedField, equals: .score(player))
                        .accessibilityLabel("\(name) score")

                    challengeButton
                }

                if draft.showsPenalty[player] {
                    HStack(spacing: 8) {
                        Text("Lost a challenge, subtract")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        NumberField(placeholder: "pts",
                                    text: $draft.penaltyText[player],
                                    isFocused: focusedField.wrappedValue == .penalty(player))
                            .focused(focusedField, equals: .penalty(player))
                            .accessibilityLabel("\(name) challenge penalty")
                    }
                    .padding(.leading, 44)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.snappy, value: draft.showsPenalty[player])
        }

        /// The bonus points this player has been picked for, shown right where people look.
        private var bonusTotal: Int {
            var total = 0
            if rules.longestWordEnabled, draft.longestWord == .player(player) { total += rules.bonusValue }
            if rules.mostWordsEnabled, draft.mostWords == .player(player) { total += rules.bonusValue }
            return total
        }

        private var bonusNames: String {
            var names: [String] = []
            if rules.longestWordEnabled, draft.longestWord == .player(player) { names.append("Longest word") }
            if rules.mostWordsEnabled, draft.mostWords == .player(player) { names.append("Most words") }
            return names.joined(separator: " and ")
        }

        /// A negative hand is floored at zero by the official rules; say so before submitting.
        private var countsAsZero: Bool {
            guard rules.floorHandAtZero, let score = draft.score(for: player) else { return false }
            return score < 0
        }

        private var signButton: some View {
            let negative = draft.isNegative[player]
            return Button {
                draft.isNegative[player].toggle()
            } label: {
                Image(systemName: negative ? "minus" : "plus")
                    .font(.footnote.weight(.heavy))
                    .foregroundStyle(negative ? Color.red : Color.secondary)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(negative ? Color.red.opacity(0.14) : Color(.tertiarySystemFill)))
                    .frame(width: 38, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(negative ? "Negative score" : "Positive score")
            .accessibilityHint("Switches the score between positive and negative")
        }

        private var challengeButton: some View {
            let shown = draft.showsPenalty[player]
            return Button {
                draft.showsPenalty[player].toggle()
                if !draft.showsPenalty[player] { draft.penaltyText[player] = "" }
            } label: {
                Image(systemName: shown ? "flag.fill" : "flag")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(shown ? Color.orange : Color.secondary)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(shown ? Color.orange.opacity(0.15) : Color(.tertiarySystemFill)))
                    .frame(width: 38, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Lost a challenge")
            .accessibilityHint("Shows a field for the challenge penalty")
        }
    }

    /// A digits-only score box that lights up while it has focus.
    private struct NumberField: View {
        let placeholder: String
        @Binding var text: String
        var isFocused: Bool = false

        var body: some View {
            TextField(placeholder, text: $text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.title3.weight(.bold).monospacedDigit())
                .frame(width: 74, height: 48)
                .background(Color(.tertiarySystemFill),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.accentColor, lineWidth: isFocused ? 2 : 0)
                }
                .animation(.snappy(duration: 0.15), value: isFocused)
                .onChange(of: text) { _, newValue in
                    let digits = newValue.filter(\.isNumber)
                    if digits != newValue { text = digits }
                }
        }
    }
}

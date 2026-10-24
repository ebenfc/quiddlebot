import SwiftUI

/// Score entry for one round: a score per player, the bonus picks, and the submit button.
struct RoundEntryView: View {
    let game: Game
    let roundNumber: Int
    let isEditing: Bool
    @Binding var draft: RoundDraft
    let onSubmit: (Round) -> Void
    let onSave: (Round) -> Void
    let onCancel: () -> Void

    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case score(Int)
        case penalty(Int)
    }

    private var rules: RuleSet { game.rules }
    private var isComplete: Bool { draft.isComplete(rules: rules) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            VStack(spacing: 12) {
                ForEach(game.players.indices, id: \.self) { player in
                    ScoreRow(name: game.players[player],
                             player: player,
                             draft: $draft,
                             focusedField: $focusedField)
                }
            }

            if rules.longestWordEnabled {
                BonusPickerView(title: "Longest Word", bonus: rules.bonusValue,
                                players: game.players, selection: $draft.longestWord)
            }
            if rules.mostWordsEnabled {
                BonusPickerView(title: "Most Words", bonus: rules.bonusValue,
                                players: game.players, selection: $draft.mostWords)
            }

            actions
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .toolbar {
            // The number pad has no Return key, so give the keyboard its own navigation.
            ToolbarItemGroup(placement: .keyboard) {
                Button("Previous player", systemImage: "chevron.up") { moveFocus(by: -1) }
                    .disabled(!canMoveFocus(by: -1))
                Button("Next player", systemImage: "chevron.down") { moveFocus(by: 1) }
                    .disabled(!canMoveFocus(by: 1))
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(isEditing ? "Editing Round \(roundNumber)" : "Round \(roundNumber)")
                .font(.headline)
            if rules.roundCount == 8 {
                Text("\(Game.cardsDealt(inRound: roundNumber)) cards each")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var actions: some View {
        if isEditing {
            HStack(spacing: 12) {
                Button(role: .cancel, action: onCancel) {
                    Text("Cancel").frame(maxWidth: .infinity, minHeight: 32)
                }
                .buttonStyle(.bordered)

                Button {
                    if let round = draft.round(rules: rules) { onSave(round) }
                } label: {
                    Text("Save Changes").frame(maxWidth: .infinity, minHeight: 32)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isComplete)
            }
        } else {
            Button {
                if let round = draft.round(rules: rules) { onSubmit(round) }
            } label: {
                Text(game.isOnFinalRound ? "Finish Game" : "Next Round")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 32)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isComplete)
        }
    }

    private func canMoveFocus(by delta: Int) -> Bool {
        guard case .score(let player) = focusedField else { return false }
        return game.players.indices.contains(player + delta)
    }

    private func moveFocus(by delta: Int) {
        guard case .score(let player) = focusedField else { return }
        focusedField = .score(player + delta)
    }

    /// One player's row: name, sign toggle, score field, and a flag for a lost challenge.
    private struct ScoreRow: View {
        let name: String
        let player: Int
        @Binding var draft: RoundDraft
        var focusedField: FocusState<Field?>.Binding

        var body: some View {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text(name)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        draft.isNegative[player].toggle()
                    } label: {
                        Text(draft.isNegative[player] ? "−" : "+")
                            .font(.title3.monospaced().weight(.semibold))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.bordered)
                    .tint(draft.isNegative[player] ? .red : .secondary)
                    .accessibilityLabel(draft.isNegative[player] ? "Negative score" : "Positive score")
                    .accessibilityHint("Toggles the sign of the score")

                    NumberField(placeholder: "0", text: $draft.scoreText[player])
                        .focused(focusedField, equals: .score(player))
                        .accessibilityLabel("\(name) score")

                    Button {
                        draft.showsPenalty[player].toggle()
                        if !draft.showsPenalty[player] { draft.penaltyText[player] = "" }
                    } label: {
                        Image(systemName: draft.showsPenalty[player] ? "flag.fill" : "flag")
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.bordered)
                    .tint(draft.showsPenalty[player] ? .orange : .secondary)
                    .accessibilityLabel("Lost a challenge")
                    .accessibilityHint("Shows a field for the challenge penalty")
                }

                if draft.showsPenalty[player] {
                    HStack {
                        Text("Lost challenge, subtract")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        NumberField(placeholder: "0", text: $draft.penaltyText[player])
                            .focused(focusedField, equals: .penalty(player))
                            .accessibilityLabel("\(name) challenge penalty")
                    }
                }
            }
        }
    }

    /// A digits-only text field styled as a score box.
    private struct NumberField: View {
        let placeholder: String
        @Binding var text: String

        var body: some View {
            TextField(placeholder, text: $text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .font(.title3.monospacedDigit())
                .padding(.horizontal, 10)
                .frame(width: 88, height: 44)
                .background(Color(.tertiarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .onChange(of: text) { _, newValue in
                    let digits = newValue.filter(\.isNumber)
                    if digits != newValue { text = digits }
                }
        }
    }
}

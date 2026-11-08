import SwiftUI

/// The round header: where you are in the game, plus one pill per round.
/// Completed rounds are tappable to edit them.
struct RoundNavView: View {
    let game: Game
    let editingRound: Int?
    let onSelect: (Int) -> Void

    private enum Status { case completed, current, editing, upcoming }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            ScreenTitle(title: title, subtitle: subtitle)
                .animation(DS.Motion.standard, value: title)

            HStack(spacing: DS.Space.xs + 2) {
                ForEach(1...game.rules.roundCount, id: \.self) { round in
                    pill(round)
                }
            }
            // Eight pills share one row; past this size their numbers would clip.
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
    }

    private var shownRound: Int { editingRound ?? game.currentRound }

    private var title: String {
        editingRound != nil ? "Editing Round \(shownRound)" : "Round \(shownRound)"
    }

    private var subtitle: String {
        var parts = ["of \(game.rules.roundCount)"]
        if game.rules.roundCount == 8 {
            parts.append("\(Game.cardsDealt(inRound: shownRound)) cards each")
        }
        return parts.joined(separator: " · ")
    }

    private func pill(_ round: Int) -> some View {
        let status = status(for: round)
        return Button {
            onSelect(round)
        } label: {
            Group {
                // The round being edited shows a pencil, so it differs from the current
                // round by shape as well as color.
                if status == .editing {
                    Image(systemName: "pencil")
                        .font(.subheadline.weight(.bold))
                } else {
                    Text("\(round)")
                        .font(.subheadline.weight(.bold).monospacedDigit())
                }
            }
            .frame(maxWidth: .infinity, minHeight: 34)
            .foregroundStyle(foreground(for: status))
            .background(fill(for: status), in: Capsule())
            .overlay {
                if status == .current || status == .editing {
                    Capsule().strokeBorder(stroke(for: status), lineWidth: 2)
                }
            }
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(status != .completed)
        .accessibilityLabel("Round \(round), \(label(for: status))")
        .accessibilityHint(status == .completed ? "Edits this round" : "")
    }

    private func status(for round: Int) -> Status {
        if round == editingRound { return .editing }
        if editingRound == nil && round == game.currentRound { return .current }
        if game.rounds.indices.contains(round - 1) { return .completed }
        return .upcoming
    }

    private func fill(for status: Status) -> Color {
        switch status {
        case .completed: DS.Colors.accent
        case .editing: DS.Colors.tint(DS.Colors.warning)
        case .current: DS.Colors.tint(DS.Colors.accent)
        case .upcoming: DS.Colors.surfaceSunken
        }
    }

    private func stroke(for status: Status) -> Color {
        status == .editing ? DS.Colors.warning : DS.Colors.accent
    }

    private func foreground(for status: Status) -> Color {
        switch status {
        case .completed: DS.Colors.onAccent
        case .editing: DS.Colors.warning
        case .current: DS.Colors.accent
        case .upcoming: .secondary
        }
    }

    private func label(for status: Status) -> String {
        switch status {
        case .completed: "completed"
        case .editing: "editing"
        case .current: "current"
        case .upcoming: "not yet played"
        }
    }
}

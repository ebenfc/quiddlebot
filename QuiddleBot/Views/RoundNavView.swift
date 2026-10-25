import SwiftUI

/// The round header: where you are in the game, plus one pill per round.
/// Completed rounds are tappable to edit them.
struct RoundNavView: View {
    let game: Game
    let editingRound: Int?
    let onSelect: (Int) -> Void

    private enum Status { case completed, current, editing, upcoming }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.largeTitle.bold())
                    .contentTransition(.numericText())
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .animation(.snappy, value: title)

            HStack(spacing: 6) {
                ForEach(1...game.rules.roundCount, id: \.self) { round in
                    pill(round)
                }
            }
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
            Text("\(round)")
                .font(.subheadline.weight(.bold).monospacedDigit())
                .frame(maxWidth: .infinity, minHeight: 34)
                .foregroundStyle(foreground(for: status))
                .background(fill(for: status), in: Capsule())
                .overlay {
                    if status == .current {
                        Capsule().strokeBorder(Color.accentColor, lineWidth: 2)
                    }
                }
                .padding(.vertical, 5)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(status != .completed)
        .accessibilityLabel("Round \(round), \(label(for: status))")
        .accessibilityHint(status == .completed ? "Tap to edit" : "")
    }

    private func status(for round: Int) -> Status {
        if round == editingRound { return .editing }
        if editingRound == nil && round == game.currentRound { return .current }
        if game.rounds.indices.contains(round - 1) { return .completed }
        return .upcoming
    }

    private func fill(for status: Status) -> Color {
        switch status {
        case .completed: .accentColor
        case .editing: .orange
        case .current: Color.accentColor.opacity(0.12)
        case .upcoming: Color(.tertiarySystemFill)
        }
    }

    private func foreground(for status: Status) -> Color {
        switch status {
        case .completed, .editing: .white
        case .current: .accentColor
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

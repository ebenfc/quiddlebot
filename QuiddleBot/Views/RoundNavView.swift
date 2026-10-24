import SwiftUI

/// One pill per round. Completed rounds are tappable to edit them.
struct RoundNavView: View {
    let game: Game
    let editingRound: Int?
    let onSelect: (Int) -> Void

    private enum Status { case completed, current, editing, upcoming }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...game.rules.roundCount, id: \.self) { round in
                let status = status(for: round)
                Button {
                    onSelect(round)
                } label: {
                    Text("\(round)")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(fill(for: status), in: Capsule())
                        .overlay {
                            if status == .current {
                                Capsule().strokeBorder(Color.accentColor, lineWidth: 2)
                            }
                        }
                        .foregroundStyle(foreground(for: status))
                }
                .buttonStyle(.plain)
                .disabled(status != .completed)
                .accessibilityLabel("Round \(round), \(label(for: status))")
                .accessibilityHint(status == .completed ? "Tap to edit" : "")
            }
        }
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
        case .current: Color(.secondarySystemGroupedBackground)
        case .upcoming: Color(.tertiarySystemGroupedBackground)
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

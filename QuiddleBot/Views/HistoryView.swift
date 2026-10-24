import SwiftUI

/// Every completed round, with a per-player breakdown.
struct HistoryView: View {
    let game: Game
    var showsTitle = true
    /// When set, each round gets an Edit button.
    var onEdit: ((Int) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showsTitle {
                Text("Round History").font(.headline)
            }
            ForEach(Array(game.rounds.enumerated()), id: \.offset) { offset, round in
                RoundSummaryView(game: game, round: round, number: offset + 1, onEdit: onEdit)
            }
        }
    }
}

private struct RoundSummaryView: View {
    let game: Game
    let round: Round
    let number: Int
    let onEdit: ((Int) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Round \(number)")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if let onEdit {
                    Button {
                        onEdit(number)
                    } label: {
                        Text("Edit")
                            .font(.subheadline)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                    .accessibilityLabel("Edit round \(number)")
                }
            }

            ForEach(game.players.indices, id: \.self) { player in
                HStack(spacing: 8) {
                    Text(game.players[player]).lineLimit(1)
                    Spacer()
                    if let breakdown = breakdown(for: player) {
                        Text(breakdown)
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Text("\(Scoring.handTotal(round: round, player: player, rules: game.rules))")
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                        .frame(minWidth: 36, alignment: .trailing)
                }
                .accessibilityElement(children: .combine)
            }

            if let awards = awardsText {
                Label(awards, systemImage: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    /// "12 − 8 + 10 =" style explanation when anything beyond the raw score applied.
    private func breakdown(for player: Int) -> String? {
        let score = round.scores[player]
        let penalty = round.penalties[player]
        let bonus = Scoring.bonuses(in: round, for: player, rules: game.rules)
        var parts: [String] = []
        if game.rules.floorHandAtZero && score < 0 {
            parts.append("\(score) → 0")
        } else {
            parts.append("\(score)")
        }
        if penalty != 0 { parts.append("− \(penalty)") }
        if bonus > 0 { parts.append("+ \(bonus)") }
        guard parts.count > 1 || parts[0].contains("→") else { return nil }
        return parts.joined(separator: " ") + " ="
    }

    private var awardsText: String? {
        var parts: [String] = []
        if game.rules.longestWordEnabled, case .player(let p) = round.longestWord,
           game.players.indices.contains(p) {
            parts.append("Longest word: \(game.players[p])")
        }
        if game.rules.mostWordsEnabled, case .player(let p) = round.mostWords,
           game.players.indices.contains(p) {
            parts.append("Most words: \(game.players[p])")
        }
        return parts.isEmpty ? nil : parts.joined(separator: "  ·  ")
    }
}

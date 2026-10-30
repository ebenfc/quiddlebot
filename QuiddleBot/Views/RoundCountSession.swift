import Foundation

/// The round counter's working copy: a copy of the round draft plus one `HandDraft` per
/// player. "Next" writes the current player's cards into the copy and moves round the table;
/// Done hands the copy back; Cancel just throws the session away.
struct RoundCountSession: Equatable {
    /// How the current player's score is being entered.
    enum Entry: Equatable {
        case cards
        /// "Type a score instead": for a player whose cards are already back in the deck.
        case typed
    }

    private(set) var round: RoundDraft
    private(set) var hands: [HandDraft]
    private(set) var current: Int
    private(set) var entry: [Entry]

    /// What the session opened with, so Cancel knows whether to ask.
    private let openedRound: RoundDraft
    private let openedHands: [HandDraft]

    init(round: RoundDraft, cardsDealt: Int, startingAt player: Int) {
        self.round = round
        hands = (0..<round.playerCount).map { HandDraft(hand: round.hands[$0], cardsDealt: cardsDealt) }
        current = player
        // A typed score opens on its number, so recounting is a choice, never an accident.
        entry = (0..<round.playerCount).map { round.isTyped($0) ? .typed : .cards }
        openedRound = round
        openedHands = hands
    }

    var playerCount: Int { hands.count }

    /// The hand on screen. The keypad edits it through a binding.
    var currentHand: HandDraft {
        get { hands[current] }
        set { hands[current] = newValue }
    }

    var hasChanges: Bool {
        round != openedRound || hands.map(\.preview) != openedHands.map(\.preview)
    }

    // MARK: - Moving round the table

    /// False while the hand on screen has a one-card word: fix it before moving on.
    var canLeaveCurrent: Bool {
        entry[current] == .typed || hands[current].hand != nil || hands[current].isEmpty
    }

    /// The next seat, or nil on the last player, where the button says Done.
    var nextPlayer: Int? { current + 1 < playerCount ? current + 1 : nil }

    /// Next: keeps the current player's cards and moves to the next seat.
    mutating func advance() {
        guard canLeaveCurrent, let next = nextPlayer else { return }
        commitCurrent()
        current = next
    }

    /// Jump straight to a player from the strip at the top.
    mutating func select(_ player: Int) {
        guard canLeaveCurrent, (0..<playerCount).contains(player) else { return }
        commitCurrent()
        current = player
    }

    /// Done: keeps the current player's cards and returns the round to write back.
    mutating func finish() -> RoundDraft {
        if canLeaveCurrent { commitCurrent() }
        return round
    }

    /// Writes the current player's cards into the round when they aren't there yet. Passing
    /// over a typed player, or one whose counted hand is unchanged, never touches their score.
    private mutating func commitCurrent() {
        guard entry[current] == .cards else { return }
        let counted = round.countedHand(for: current)
        if let hand = hands[current].hand {
            if hand != counted { round.apply(hand, for: current) }
        } else if hands[current].isEmpty && counted != nil {
            // Every card was deleted: this player is not counted any more.
            round.clearScore(for: current)
        }
    }

    // MARK: - Typing a score instead

    /// Switches to the number pad. It starts blank: the player is about to type a new number.
    /// The cards stay behind it, so "Count cards instead" can bring them back.
    mutating func typeInstead() {
        guard entry[current] == .cards else { return }
        entry[current] = .typed
        round.scoreText[current] = ""
        round.isNegative[current] = false
    }

    /// Back to the keypad: the cards on screen replace whatever was typed.
    mutating func countInstead() {
        guard entry[current] == .typed else { return }
        entry[current] = .cards
        if let hand = hands[current].hand {
            round.apply(hand, for: current)
        } else {
            round.clearScore(for: current)
        }
    }

    /// Up to three digits; a hand can't score a thousand.
    mutating func typeDigit(_ digit: Int) {
        guard entry[current] == .typed, (0...9).contains(digit) else { return }
        let text = round.scoreText[current] == "0" ? "" : round.scoreText[current]
        guard text.count < 3 else { return }
        round.scoreText[current] = text + String(digit)
    }

    mutating func deleteDigit() {
        guard entry[current] == .typed, !round.scoreText[current].isEmpty else { return }
        round.scoreText[current].removeLast()
    }

    mutating func toggleSign() {
        guard entry[current] == .typed else { return }
        round.isNegative[current].toggle()
    }

    // MARK: - Lost a challenge

    /// The points a lost challenge takes off the current player, or 0 / blank to remove it.
    mutating func setPenalty(_ text: String) {
        let digits = String(text.filter(\.isNumber).prefix(3))
        let points = Int(digits) ?? 0
        round.penaltyText[current] = points == 0 ? "" : String(points)
        round.showsPenalty[current] = points != 0
    }
}

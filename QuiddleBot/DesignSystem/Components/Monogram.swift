import Foundation

/// What a player's avatar shows. Usually the initial; when two players share one ("Ben",
/// "Bea"), both get two letters so they can be told apart without relying on color.
nonisolated enum Monogram {
    static func make(for names: [String]) -> [String] {
        let trimmed = names.map { $0.trimmingCharacters(in: .whitespaces) }
        let initials = trimmed.map { $0.first.map { String($0).uppercased() } }
        let pairs = trimmed.map { name -> String? in
            guard name.count >= 2 else { return nil }
            let letters = Array(name)
            return String(letters[0]).uppercased() + String(letters[1]).lowercased()
        }
        return trimmed.indices.map { seat in
            guard let initial = initials[seat] else { return "\(seat + 1)" }
            let sharesInitial = initials.indices.contains { $0 != seat && initials[$0] == initial }
            guard sharesInitial else { return initial }
            if let pair = pairs[seat],
               !pairs.indices.contains(where: { $0 != seat && pairs[$0]?.lowercased() == pair.lowercased() }) {
                return pair
            }
            return "\(initial)\(seat + 1)"
        }
    }
}

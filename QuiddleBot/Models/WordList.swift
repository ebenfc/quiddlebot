import Foundation
import os

/// The built-in word list behind the counter's word check: ENABLE1 (public domain) plus
/// scripts/wordlist/additions.txt, lowercase a–z, 2 to 15 letters, built by
/// scripts/build-wordlist.sh. Membership is the whole test. The rulebook's other rules (no
/// proper nouns, abbreviations or hyphens) are not expressible in a lowercase list, and
/// the table's own dictionary still has the last word: see `WordVerdict`.
nonisolated struct WordList: Sendable {
    private let words: Set<String>

    init(words: some Sequence<String>) {
        self.words = Set(words.lazy.map { $0.lowercased() })
    }

    /// One word per line. Blank lines and `#` comment lines (the resource's header) are skipped.
    init(text: String) {
        // Walk the UTF-8 bytes, not Characters: grapheme breaking a 1.7 MB string is the
        // slow part, and the list is plain ASCII by construction.
        var set = Set<String>(minimumCapacity: 180_000)
        for line in text.utf8.split(separator: UInt8(ascii: "\n"), omittingEmptySubsequences: true)
        where line.first != UInt8(ascii: "#") {
            set.insert(String(decoding: line, as: UTF8.self))
        }
        words = set
    }

    var count: Int { words.count }

    /// Case-insensitive, so `Word.text` ("QUIZ") can be passed straight in.
    func contains(_ text: String) -> Bool {
        words.contains(text.lowercased())
    }

    /// words.txt from the app bundle. The tests are hosted by the app, so it is their bundle too.
    static func bundled(in bundle: Bundle = .main) throws -> WordList {
        guard let url = bundle.url(forResource: "words", withExtension: "txt") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return WordList(text: try String(contentsOf: url, encoding: .utf8))
    }

    /// Loaded once, the first time it is read. Read it from a detached task so that first
    /// read never blocks the main actor; after that it is a plain static access.
    /// nil means the resource is missing, and the counter then shows no verdicts at all.
    static let shared: WordList? = {
        do {
            return try bundled()
        } catch {
            Logger(subsystem: "com.ebencarey.quiddlebot", category: "words")
                .error("Word list missing: \(error.localizedDescription)")
            assertionFailure("words.txt is not in the bundle: run scripts/build-wordlist.sh, then xcodegen generate")
            return nil
        }
    }()
}

/// What the counter shows next to a word. A hint, never a ruling: it never changes a score
/// and never blocks Next or Done. The table's dictionary decides, as the rules say.
nonisolated enum WordVerdict: Equatable, Sendable {
    /// In the built-in list.
    case found
    /// Not in the list and the table has not ruled: amber, tap for options.
    case notInList
    /// Not in the list, but the table said it's good.
    case tableAccepted

    /// The list wins over a stale mark: a word the list knows is simply found.
    init(word: Word, isListed: Bool) {
        self = isListed ? .found : word.tableAccepted ? .tableAccepted : .notInList
    }
}

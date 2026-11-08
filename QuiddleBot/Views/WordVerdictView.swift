import SwiftUI
import UIKit

/// The mark next to a word in the counter: found in the built-in list, not in it, or
/// accepted by the table. Only the last two can be tapped, for the options sheet.
struct WordVerdictBadge: View {
    let verdict: WordVerdict
    var action: () -> Void

    var body: some View {
        switch verdict {
        case .found:
            mark("checkmark.circle.fill", tint: DS.Colors.positive)
                .accessibilityLabel("In the word list")
        case .notInList:
            Button(action: action) { mark("questionmark.circle.fill", tint: DS.Colors.warning) }
                .buttonStyle(.plain)
                .accessibilityLabel("Not in the word list")
                .accessibilityHint("Shows options")
        case .tableAccepted:
            Button(action: action) { mark("checkmark.circle", tint: DS.Colors.accent) }
                .buttonStyle(.plain)
                .accessibilityLabel("Accepted by the table")
                .accessibilityHint("Shows options")
        }
    }

    /// A full 44 pt target, inside the button label so the whole area taps.
    private func mark(_ systemImage: String, tint: Color) -> some View {
        Image(systemName: systemImage)
            .font(.title3)
            .imageScale(.medium)
            .foregroundStyle(tint)
            .frame(minWidth: DS.Size.minTap, minHeight: DS.Size.minTap)
            .contentShape(Rectangle())
    }
}

/// What to do about a word the list doesn't know: look it up in the dictionary built into
/// iOS, or record that the table accepted it. Never touches the score.
struct WordVerdictSheet: View {
    let word: Word
    let verdict: WordVerdict
    var onAccept: (Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    /// nil while the dictionary check is running: the first call on a device can take a
    /// moment, and a flash of the wrong message would be worse than a spinner.
    @State private var hasDefinition: Bool?
    @State private var showingDictionary = false

    private var term: String { word.text.lowercased() }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.xl) {
            ScreenTitle(title: word.text, subtitle: "\(word.points) points · \(word.letters) letters")

            Label {
                Text(verdict == .tableAccepted ? "The table accepted this word" : "Not in the built-in word list")
            } icon: {
                Image(systemName: verdict == .tableAccepted ? "checkmark.circle" : "questionmark.circle.fill")
                    .foregroundStyle(verdict == .tableAccepted ? DS.Colors.accent : DS.Colors.warning)
            }
            .font(DS.Typography.rowTitle)

            dictionaryArea

            Spacer(minLength: 0)

            if verdict == .tableAccepted {
                Button("Not accepted after all") {
                    onAccept(false)
                    dismiss()
                }
                .buttonStyle(SecondaryButtonStyle())
            } else {
                Button("Table says it's good") {
                    onAccept(true)
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
            }

            Text("The check never changes the score. A lost challenge still goes through ⋯ › Lost a challenge.")
                .font(DS.Typography.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(DS.Space.screen)
        .fontDesign(.rounded)
        .tint(DS.Colors.accent)
        .task {
            // Let the sheet finish sliding in before the (synchronous, main-thread) check.
            try? await Task.sleep(for: .milliseconds(300))
            hasDefinition = UIReferenceLibraryViewController.dictionaryHasDefinition(forTerm: term)
        }
        .sheet(isPresented: $showingDictionary) {
            DictionaryLookupView(term: term)
                .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private var dictionaryArea: some View {
        switch hasDefinition {
        case nil:
            HStack(spacing: DS.Space.m) {
                ProgressView()
                Text("Checking the dictionary…")
                    .font(DS.Typography.detail)
                    .foregroundStyle(.secondary)
            }
            .frame(minHeight: DS.Size.button)
        case true?:
            Button("Look up in Dictionary") { showingDictionary = true }
                .buttonStyle(SecondaryButtonStyle())
        case false?:
            // False also means no dictionary is installed (simulators have none), so this
            // never claims the word doesn't exist.
            Text("No definition found on this device. iOS looks words up in a dictionary you download under Settings › General › Dictionary.")
                .font(DS.Typography.detail)
                .foregroundStyle(.secondary)
        }
    }
}

/// The dictionary built into iOS, for one term. Its own Done button closes it.
struct DictionaryLookupView: UIViewControllerRepresentable {
    let term: String

    func makeUIViewController(context: Context) -> UIReferenceLibraryViewController {
        UIReferenceLibraryViewController(term: term)
    }

    func updateUIViewController(_ uiViewController: UIReferenceLibraryViewController, context: Context) {}
}

#if DEBUG
#Preview("Badges") {
    HStack(spacing: 24) {
        WordVerdictBadge(verdict: .found) {}
        WordVerdictBadge(verdict: .notInList) {}
        WordVerdictBadge(verdict: .tableAccepted) {}
    }
    .padding()
}

#Preview("Not in list") {
    WordVerdictSheet(word: Word(["Z", "A"]), verdict: .notInList, onAccept: { _ in })
}

#Preview("Table accepted") {
    WordVerdictSheet(word: Word(["Z", "A"], tableAccepted: true), verdict: .tableAccepted, onAccept: { _ in })
}
#endif

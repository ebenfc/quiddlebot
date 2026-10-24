import SwiftUI

struct SetupView: View {
    @Environment(GameStore.self) private var store

    @State private var playerCount = 2
    @State private var names = Array(repeating: "", count: 4)
    @State private var mostWordsForTwo = false
    @FocusState private var focusedName: Int?

    var body: some View {
        NavigationStack {
            Form {
                Section("Players") {
                    Picker("Number of players", selection: $playerCount) {
                        ForEach(2...4, id: \.self) { count in
                            Text("\(count)").tag(count)
                        }
                    }
                    .pickerStyle(.segmented)

                    ForEach(0..<playerCount, id: \.self) { index in
                        TextField("Player \(index + 1)", text: $names[index])
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .focused($focusedName, equals: index)
                            .submitLabel(index == playerCount - 1 ? .done : .next)
                            .onSubmit {
                                if index < playerCount - 1 {
                                    focusedName = index + 1
                                } else {
                                    start()
                                }
                            }
                            .accessibilityLabel("Player \(index + 1) name")
                    }
                }

                if playerCount == 2 {
                    Section {
                        Toggle("Most Words bonus", isOn: $mostWordsForTwo)
                    } footer: {
                        Text("With two players the official rules use one bonus. Longest Word is always on; turn this on to use both.")
                    }
                }

                Section {
                    Button(action: start) {
                        Text("Start Game")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 32)
                    }
                    .buttonStyle(.borderedProminent)
                    .listRowInsets(EdgeInsets())
                }
            }
            .navigationTitle("QuiddleBot")
        }
    }

    private func start() {
        focusedName = nil
        let players = (0..<playerCount).map { index -> String in
            let trimmed = names[index].trimmingCharacters(in: .whitespaces)
            return trimmed.isEmpty ? "Player \(index + 1)" : trimmed
        }
        store.start(players: players,
                    rules: .official(playerCount: playerCount, mostWordsForTwo: mostWordsForTwo))
    }
}

#Preview {
    SetupView().environment(GameStore(fileURL: FileManager.default.temporaryDirectory
        .appending(path: "quiddlebot-setup-preview.json")))
}

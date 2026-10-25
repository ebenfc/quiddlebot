import SwiftUI

struct SetupView: View {
    @Environment(GameStore.self) private var store

    @State private var playerCount = 2
    @State private var names = Array(repeating: "", count: 4)
    @State private var mostWordsForTwo = false
    @FocusState private var focusedName: Int?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Who's playing?").font(.headline)
                        Picker("Number of players", selection: $playerCount.animation(.snappy)) {
                            ForEach(2...4, id: \.self) { count in
                                Text("\(count) players").tag(count)
                            }
                        }
                        .pickerStyle(.segmented)

                        VStack(spacing: 10) {
                            ForEach(0..<playerCount, id: \.self) { index in
                                nameRow(index)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                    }
                    .card()

                    if playerCount == 2 {
                        VStack(alignment: .leading, spacing: 6) {
                            Toggle(isOn: $mostWordsForTwo) {
                                Label {
                                    Text("Most Words bonus")
                                } icon: {
                                    Image(systemName: "star.fill").foregroundStyle(Theme.gold)
                                }
                            }
                            Text("Two-player games use one bonus. Longest Word is always on; turn this on to play both.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .card()
                        .transition(.opacity)
                    }

                    rulesSummary
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
            .safeAreaInset(edge: .bottom) {
                BottomActionBar {
                    Button(action: start) {
                        HStack(spacing: 8) {
                            Text("Start Game")
                            Image(systemName: "arrow.right")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("QuiddleBot")
                .font(.largeTitle.bold())
            Text("Scorekeeper for Quiddler")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 12)
    }

    private func nameRow(_ index: Int) -> some View {
        HStack(spacing: 12) {
            PlayerAvatar(name: names[index].isEmpty ? "\(index + 1)" : names[index], index: index)
            TextField("Player \(index + 1)", text: $names[index])
                .font(.body.weight(.medium))
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
        .padding(.horizontal, 12)
        .frame(minHeight: 54)
        .background(Color(.tertiarySystemFill),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var rulesSummary: some View {
        HStack(spacing: 10) {
            summaryTile(value: "8", label: "rounds")
            summaryTile(value: "3–10", label: "cards")
            summaryTile(value: "+10", label: "per bonus", tint: Theme.gold)
        }
        .accessibilityElement(children: .combine)
    }

    private func summaryTile(value: String, label: String, tint: Color = .primary) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(tint)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .card(padding: 12)
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

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
                VStack(alignment: .leading, spacing: DS.Space.xl) {
                    ScreenTitle(title: "QuiddleBot", subtitle: "Scorekeeper for Quiddler")
                        .padding(.top, DS.Space.m)

                    VStack(alignment: .leading, spacing: DS.Space.l) {
                        Text("Who's playing?")
                            .font(DS.Typography.rowTitle)
                            .accessibilityAddTraits(.isHeader)
                        Picker("Number of players", selection: $playerCount.animation(DS.Motion.standard)) {
                            ForEach(2...4, id: \.self) { count in
                                Text("\(count) players").tag(count)
                            }
                        }
                        .pickerStyle(.segmented)

                        VStack(spacing: DS.Space.s) {
                            ForEach(0..<playerCount, id: \.self) { index in
                                nameRow(index)
                                    .motionSafeTransition(.move(edge: .top).combined(with: .opacity))
                            }
                        }

                        Text("Enter players in seating order. Hands are counted round the table.")
                            .font(DS.Typography.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .dsCard()

                    if playerCount == 2 {
                        VStack(alignment: .leading, spacing: DS.Space.xs + 2) {
                            Toggle(isOn: $mostWordsForTwo) {
                                Label {
                                    Text("Most Words bonus")
                                } icon: {
                                    Image(systemName: "star.fill").foregroundStyle(DS.Colors.bonusText)
                                }
                            }
                            Text("Two-player games use one bonus. Longest Word is always on; turn this on to play both.")
                                .font(DS.Typography.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .dsCard()
                        .transition(.opacity)
                    }

                    rulesSummary
                }
                .padding(DS.Space.screen)
            }
            .scrollDismissesKeyboard(.interactively)
            .dsCanvas()
            .bottomActionBar {
                Button(action: start) {
                    HStack(spacing: DS.Space.s) {
                        Text("Start Game")
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func nameRow(_ index: Int) -> some View {
        HStack(spacing: DS.Space.m) {
            PlayerAvatar(seat: index, in: Array(names.prefix(playerCount)))
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
        .padding(.horizontal, DS.Space.m)
        .frame(minHeight: DS.Size.button)
        .background(DS.Colors.surfaceSunken, in: RoundedRectangle.ds(DS.Radius.control))
    }

    private var rulesSummary: some View {
        HStack(spacing: DS.Space.m) {
            StatTile(value: "8", label: "rounds")
            StatTile(value: "3–10", label: "cards")
            StatTile(value: "+10", label: "per bonus", isBonus: true)
        }
        .accessibilityElement(children: .combine)
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

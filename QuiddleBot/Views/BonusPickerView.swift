import SwiftUI

/// Who gets a bonus this round: one chip per player plus "Tie / None".
struct BonusPickerView: View {
    let title: String
    let bonus: Int
    let players: [String]
    @Binding var selection: BonusAward

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("\(title)  +\(bonus)", systemImage: "star.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)], spacing: 8) {
                ForEach(players.indices, id: \.self) { player in
                    chip(players[player], value: .player(player))
                }
                chip("Tie / None", value: .tie)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(title) bonus")
    }

    @ViewBuilder
    private func chip(_ label: String, value: BonusAward) -> some View {
        let isSelected = selection == value
        let button = Button {
            selection = value
        } label: {
            Text(label)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])

        if isSelected {
            button
                .buttonStyle(.borderedProminent)
                .tint(value == .tie ? .orange : .accentColor)
        } else {
            button
                .buttonStyle(.bordered)
                .tint(.secondary)
        }
    }
}

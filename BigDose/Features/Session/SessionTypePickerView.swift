import SwiftUI

struct SessionTypePickerView: View {
    var onSelect: (BigDoseSessionType) -> Void
    var onCancel: () -> Void

    var body: some View {
        ZStack {
            BigDoseGradientBackground()

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Add Dose")
                            .font(.system(.largeTitle, weight: .semibold))
                            .foregroundStyle(.white)

                        Text("What are we tracking?")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.66))
                    }

                    Spacer()

                    Button("Cancel", action: onCancel)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.solarGold)
                }

                LazyVGrid(columns: sessionColumns, spacing: 12) {
                    ForEach(BigDoseSessionType.allCases) { type in
                        Button {
                            onSelect(type)
                        } label: {
                            SessionTypeCard(type: type)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()
            }
            .padding(22)
        }
    }

    private var sessionColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
    }
}

private struct SessionTypeCard: View {
    let type: BigDoseSessionType

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: type.systemImage)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.solarGold)

            VStack(alignment: .leading, spacing: 4) {
                Text(type.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)

                Text(type.detail)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        .padding(16)
        .bigDoseGlass(cornerRadius: 24)
    }
}

#Preview {
    SessionTypePickerView(onSelect: { _ in }, onCancel: { })
}

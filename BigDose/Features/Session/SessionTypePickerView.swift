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
                        Text("Dose Type")
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

                StartSunSessionActionButton(size: .prominent) {
                    onSelect(.sun)
                }

                HStack(spacing: 10) {
                    ForEach([BigDoseSessionType.lamp, .supplement, .scheduled]) { type in
                        Button {
                            onSelect(type)
                        } label: {
                            DoseTypeSecondaryCard(type: type)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()
            }
            .padding(22)
        }
    }
}

private struct DoseTypeSecondaryCard: View {
    let type: BigDoseSessionType

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: type.systemImage)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.solarGold)

            Text(type.shortTitle)
                .font(.caption.weight(.black))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 108)
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .bigDoseGlass(cornerRadius: 22)
    }
}

#Preview {
    SessionTypePickerView(onSelect: { _ in }, onCancel: { })
}

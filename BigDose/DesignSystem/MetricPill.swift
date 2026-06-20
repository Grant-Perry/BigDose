import SwiftUI

struct MetricPill: View {
    var title: String
    var value: String
    var systemImage: String
    var infoTopic: BigDoseInfoTopic?

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.bigDoseHeader(.headline).weight(.bold))
                .foregroundStyle(.solarGold)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 2) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.58))

                    if let infoTopic {
                        InfoCircleButton(topic: infoTopic, compact: true)
                    }
                }

                Text(value)
                    .font(.bigDoseHeader(.headline).weight(.black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .bigDoseGlass(cornerRadius: 22)
    }
}

import SwiftUI

struct MetricPill: View {
    var title: String
    var value: String
    var systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.bigDoseHeader(.headline).weight(.bold))
                .foregroundStyle(.solarGold)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))

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

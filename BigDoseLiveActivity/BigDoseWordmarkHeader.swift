import SwiftUI

struct BigDoseWordmarkHeader: View {
    var trailingText: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("BigDose")
                .font(.bigDoseWordmark(16))
                .foregroundStyle(WidgetBrandColors.solarGold)
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 0)

            if let trailingText {
                Text(trailingText)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.82))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.10), in: .capsule)
            }
        }
    }
}

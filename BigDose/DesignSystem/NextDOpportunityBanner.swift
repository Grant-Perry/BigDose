import SwiftUI

struct NextDOpportunityBanner: View {
    var display: VitaminDWindowDisplay
    var detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: bannerSymbol)
                .font(.title2.weight(.bold))
                .foregroundStyle(.solarGold)
                .symbolEffect(.pulse, options: .repeating, value: display.nextOpportunityStart != nil)

            VStack(alignment: .leading, spacing: 5) {
                Text(display.bannerEyebrow)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.solarGold)
                    .textCase(.uppercase)

                Text(display.bannerTitle)
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text(detail)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.42))
                .padding(.top, 4)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.06), in: .rect(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(display.bannerTitle). \(detail)")
    }

    private var bannerSymbol: String {
        if display.nextOpportunityStart == nil, display.isToday {
            return "sun.max.circle.fill"
        }

        return "sun.max.fill"
    }
}

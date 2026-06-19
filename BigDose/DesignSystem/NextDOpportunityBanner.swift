import SwiftUI

struct NextDOpportunityBanner: View {
    var display: VitaminDWindowDisplay
    var todayGoalProgress: Double
    var todayCollectedIU: Double
    var targetIU: Int

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: bannerSymbol)
                .font(.bigDoseHeader(.title2).weight(.bold))
                .foregroundStyle(.solarGold)
                .symbolEffect(.pulse, options: .repeating, value: display.nextOpportunityStart != nil)

            VStack(alignment: .leading, spacing: 5) {
                Text(display.bannerEyebrow)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.solarGold)
                    .textCase(.uppercase)

                Text(display.bannerTitle)
                    .font(.bigDoseHeader(.headline).weight(.black))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(Int(todayCollectedIU.rounded())) / \(targetIU) IU today")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.48))
            }

            Spacer(minLength: 8)

            SunSessionGoalDialView(
                goalProgress: todayGoalProgress,
                goalTimerInterval: nil,
                isPaused: true,
                diameter: 58,
                lineWidth: 4,
                progressCaption: "today"
            )
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.06), in: .rect(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(display.bannerTitle). \(Int(todayGoalProgress * 100)) percent of today's goal.")
    }

    private var bannerSymbol: String {
        if display.nextOpportunityStart == nil, display.isToday {
            return "sun.max.circle.fill"
        }

        return "sun.max.fill"
    }
}

import SwiftUI

struct RecommendedDailyIUCard: View {
    var recommendation: OptimalDailyIURecommendation
    var showsSunTarget: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 4) {
                Text("Recommended daily intake")
                    .font(.bigDoseHeader(.headline).weight(.semibold))
                    .foregroundStyle(.white)
                InfoCircleButton(topic: .dailyIUTarget, compact: true)
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(recommendation.totalDailyIU.formatted())")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(.solarGold)
                Text("IU/day total")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.68))
            }

            breakdownLines

            if showsSunTarget {
                Text("Sun session target: \(recommendation.sunSessionTargetIU.formatted()) IU after your default supplement.")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var breakdownLines: some View {
        VStack(alignment: .leading, spacing: 4) {
            breakdownRow("Maintenance", recommendation.maintenanceIU)
            if recommendation.levelCorrectionIU > 0 {
                breakdownRow(
                    "Level correction (\(Int(recommendation.startingLevelNgML.rounded()))→\(Int(recommendation.goalLevelNgML.rounded())) ng/mL)",
                    recommendation.levelCorrectionIU
                )
            }
            if recommendation.weightAdjustmentIU > 0 {
                breakdownRow("Weight adjustment", recommendation.weightAdjustmentIU)
            }
        }
    }

    private func breakdownRow(_ label: String, _ iu: Int) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text("+\(iu.formatted()) IU")
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.white.opacity(0.58))
    }
}

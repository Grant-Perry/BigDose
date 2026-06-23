import SwiftUI

struct NextDOpportunityBanner: View {
    var display: VitaminDWindowDisplay
    var now: Date
    var todayGoalProgress: Double
    var todaySunIU: Double
    var targetIU: Int
    var isSunSessionStartEnabled = true
    var showsNoUsefulUV = false
    var onStartSunSession: () -> Void = {}

    private let goalDialDiameter: CGFloat = 96 * 0.85

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .center, spacing: 6) {
                Text(display.bannerEyebrow)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.solarGold)
                    .textCase(.uppercase)

                Spacer(minLength: 0)

                InfoCircleButton(topic: .dWindowOpen, iconSize: 11, compact: true)
            }

            bannerTitleBlock

            Text("\(Int(todaySunIU.rounded())) / \(targetIU) IU sun")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.48))

            HStack(spacing: 4) {
                Text("Recommended sun target")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.42))
                InfoCircleButton(topic: .dailyIUTarget, iconSize: 10, compact: true)
            }
        }
        .padding(14)
        .padding(.trailing, goalDialDiameter + 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.06), in: .rect(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
        .overlay(alignment: .trailing) {
            todayGoalDialButton
                .padding(.trailing, 12)
        }
        .accessibilityElement(children: .contain)
    }

    private var bannerTitleBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(display.bannerTitleLead)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(display.bannerTitleDetail)

                if let remainingLabel = openNowRemainingLabel {
                    Text("·")
                        .foregroundStyle(.white.opacity(0.42))

                    Text(remainingLabel)
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(.solarGold)
                }
            }
        }
        .font(.bigDoseHeader(.headline).weight(.black))
        .foregroundStyle(.white)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var openNowRemainingLabel: String? {
        guard display.isWindowOpenNow,
              let remaining = display.remainingWindowDurationComponents(at: now),
              remaining.hours > 0 || remaining.minutes > 0 else {
            return nil
        }

        return "\(remaining.compactLabel) left"
    }

    private var todayGoalDialButton: some View {
        Button(action: onStartSunSession) {
            SunSessionGoalDialView(
                goalProgress: todayGoalProgress,
                goalTimerInterval: nil,
                isPaused: true,
                diameter: goalDialDiameter,
                lineWidth: 5,
                progressCaption: "IU goal",
                showsNoUsefulUV: showsNoUsefulUV
            )
            .accessibilityHidden(true)
        }
        .buttonStyle(.plain)
        .disabled(!isSunSessionStartEnabled)
        .opacity(isSunSessionStartEnabled ? 1 : 0.48)
        .accessibilityLabel("Start sun session")
        .accessibilityValue("\(Int(todayGoalProgress * 100)) percent of daily goal")
        .accessibilityHint(isSunSessionStartEnabled ? "Starts a new sun session" : "Weather data required to start a sun session")
    }
}

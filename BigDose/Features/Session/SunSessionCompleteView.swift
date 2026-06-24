import SwiftUI

struct SunSessionCompleteView: View {
    var result: SunSessionResult
    var onDone: () -> Void

    var body: some View {
        ZStack {
            BigDoseGradientBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    generatedCard
                    safetyRecapCard
                    statsCard
                    factorsCard
                    editHintCard
                    doneButton
                }
                .padding(18)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title.weight(.semibold))
                .foregroundStyle(.green)

            Text("Session Complete")
                .font(.title.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.top, 14)
    }

    private var generatedCard: some View {
        GlassCard {
            HStack(alignment: .center, spacing: 16) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 58, weight: .semibold))
                    .foregroundStyle(.solarGold)
                    .shadow(color: .solarGold.opacity(0.4), radius: 12)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(Int(result.estimatedIU.rounded()))")
                            .font(.system(size: 56, weight: .semibold))
                            .foregroundStyle(.solarGold)
                        Text("IU")
                            .font(.bigDoseHeader(.title3).weight(.semibold))
                            .foregroundStyle(.white.opacity(0.72))
                    }

                    Text("vitamin D estimated")
                        .font(.bigDoseHeader(.headline).weight(.semibold))
                        .foregroundStyle(.white.opacity(0.68))
                }
            }
        }
    }

    private var safetyRecapCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(safetyRecapTint)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.safetyRecapTitle)
                            .font(.bigDoseHeader(.headline).weight(.semibold))
                            .foregroundStyle(.white)

                        Text("MED (burn risk) Used: \(result.medUsedPercent)%")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(safetyRecapTint)
                    }

                    Spacer(minLength: 0)

                    InfoCircleButton(topic: .medUsed, compact: true)
                }

                Text(result.safetyRecapMessage)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var safetyRecapTint: Color {
        switch result.medUsedPercent {
        case 95...:
            .red
        case 75...:
            .solarOrange
        case 50...:
            .solarGold
        default:
            .green
        }
    }

    private var statsCard: some View {
        GlassCard {
            VStack(spacing: 12) {
                summaryRow("Duration", durationText(result.elapsedSeconds))
                Divider().overlay(.white.opacity(0.12))
                summaryRow("MED (burn risk) Used", "\(result.medUsedPercent)%", highlight: result.medOverLimitPercent > 0)
                if result.medOverLimitPercent > 0 {
                    summaryRow("Past 100% MED (burn risk)", "+\(result.medOverLimitPercent)%", highlight: true)
                }
                Divider().overlay(.white.opacity(0.12))
                summaryRow("Average Rate", "\(Int(result.averageRate.rounded())) IU/min")
                Divider().overlay(.white.opacity(0.12))
                summaryRow("Peak UV", result.plan.uvIndex.formatted(.number.precision(.fractionLength(1))))
                Divider().overlay(.white.opacity(0.12))
                summaryRow("% of daily target", "\(Int(result.percentOfTarget * 100))%")
            }
        }
    }

    private var factorsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Rate Factors")
                    .font(.bigDoseHeader(.headline).weight(.semibold))
                    .foregroundStyle(.white)

                summaryRow("Skin type", result.plan.skinType.title)
                summaryRow("Skin exposure", "\(Int(result.plan.exposedBodySurfaceArea * 100))%")
                summaryRow("Clouds / shade", result.plan.cloudCover.title)
                summaryRow("Effective UV", result.plan.input.effectiveUVIndex.formatted(.number.precision(.fractionLength(1))))
                summaryRow("Final rate", "\(Int(result.plan.iuPerMinute.rounded())) IU/min", highlight: true)
            }
        }
    }

    private var editHintCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "pencil.and.list.clipboard")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.solarGold)

            Text("Logged too long? Tap this session in History to dial in the duration — IU and MED (burn risk) recalculate automatically.")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.58))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(.white.opacity(0.06), in: .rect(cornerRadius: 18))
    }

    private var doneButton: some View {
        BigDosePrimaryButton(title: "Done", style: .accent, action: onDone)
    }

    private func summaryRow(_ title: String, _ value: String, highlight: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(.bigDoseHeader(.headline).weight(.semibold))
                .foregroundStyle(.white.opacity(0.62))
            Spacer()
            Text(value)
                .font(.bigDoseHeader(.headline).weight(.semibold))
                .foregroundStyle(highlight ? .solarGold : .white)
        }
    }

    private func durationText(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}


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
                    statsCard
                    factorsCard
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
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.72))
                    }

                    Text("vitamin D estimated")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.68))
                }
            }
        }
    }

    private var statsCard: some View {
        GlassCard {
            VStack(spacing: 12) {
                summaryRow("Duration", durationText(result.elapsedSeconds))
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
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)

                summaryRow("Skin type", result.plan.skinType.title)
                summaryRow("Skin exposure", "\(Int(result.plan.exposedBodySurfaceArea * 100))%")
                summaryRow("Clouds / shade", result.plan.cloudCover.title)
                summaryRow("Effective UV", result.plan.input.effectiveUVIndex.formatted(.number.precision(.fractionLength(1))))
                summaryRow("Final rate", "\(Int(result.plan.iuPerMinute.rounded())) IU/min", highlight: true)
            }
        }
    }

    private var doneButton: some View {
        Button(action: onDone) {
            Text("Done")
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .tint(.blue)
    }

    private func summaryRow(_ title: String, _ value: String, highlight: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.62))
            Spacer()
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(highlight ? .solarGold : .white)
        }
    }

    private func durationText(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

#Preview {
    SunSessionCompleteView(result: SunSessionResult(
        plan: SunSessionPlan(
            startedAt: .now,
            durationSeconds: 15 * 60,
            exposedBodySurfaceArea: 0.25,
            cloudCover: .clear,
            sunscreenTransmission: 1,
            uvIndex: 6.4,
            currentTemperatureFahrenheit: 82,
            skinType: .typeII,
            locationName: "Newport News",
            targetIU: 1_000
        ),
        endedAt: .now,
        elapsedSeconds: 960,
        estimatedIU: 700
    ), onDone: { })
}

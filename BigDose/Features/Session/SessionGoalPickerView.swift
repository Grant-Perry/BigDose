import SwiftUI

struct SessionGoalPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var targetIU: Double
    let plan: SunSessionPlan
    let elapsedSeconds: TimeInterval

    private let presets = [600, 1_000, 2_000, 4_000, 5_000]

    private var safeGoalIU: Double {
        plan.safeGoalIUAtCurrentSettings
    }

    private var sliderMinimum: Double {
        SunSessionPlan.sessionGoalMinimumIU
    }

    private var sliderMaximum: Double {
        max(
            plan.sessionGoalPickerMaximumIU,
            ceil(targetIU / SunSessionPlan.sessionGoalSliderStep) * SunSessionPlan.sessionGoalSliderStep
        )
    }

    private var exceedsSafeGoal: Bool {
        targetIU > safeGoalIU
    }

    private var timeToGoalSubtitle: String {
        let currentIU = plan.estimatedIU(at: elapsedSeconds)
        guard plan.liveIUProductionRatePerMinute > 0 else {
            return "Session goal"
        }
        guard currentIU < targetIU else {
            return "Goal reached at current rate"
        }
        let remainingIU = targetIU - currentIU
        let minutes = max(1, Int(ceil(remainingIU / plan.liveIUProductionRatePerMinute)))
        return "About \(minutes) min remaining at current rate"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BigDoseGradientBackground()

                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(Int(targetIU.rounded()))")
                            .font(.system(size: 56, weight: .semibold))
                            .foregroundStyle(.solarGold)
                            .contentTransition(.numericText())
                            .animation(.smooth, value: Int(targetIU.rounded()))

                        Text("IU")
                            .font(.bigDoseHeader(.title3).weight(.semibold))
                            .foregroundStyle(.white.opacity(0.68))
                    }

                    Text(timeToGoalSubtitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.58))

                    Slider(
                        value: $targetIU,
                        in: sliderMinimum...sliderMaximum,
                        step: SunSessionPlan.sessionGoalSliderStep
                    )
                    .tint(.solarGold)

                    HStack {
                        Text("\(Int(sliderMinimum)) IU")
                        Spacer()
                        Text("\(Int(sliderMaximum.rounded())) IU")
                    }
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.42))

                    if exceedsSafeGoal {
                        safeGoalCaution
                    }

                    HStack(spacing: 8) {
                        ForEach(presets, id: \.self) { iu in
                            Button {
                                withAnimation(.smooth) {
                                    targetIU = min(Double(iu), sliderMaximum)
                                }
                            } label: {
                                Text("\(iu.formatted())")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(Int(targetIU.rounded()) == iu ? .black : .white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        Int(targetIU.rounded()) == iu ? Color.solarGold : .white.opacity(0.08),
                                        in: .rect(cornerRadius: 10)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .padding(22)
            }
            .navigationTitle("Session Goal")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.bigDoseHeader(.headline).weight(.semibold))
                        .foregroundStyle(.solarGold)
                }
            }
        }
    }

    private var safeGoalCaution: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text("Past burn guidance")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)

                Text(
                    "This goal needs more sun time than BigDose allows before the 95% MED (burn risk) guidance limit (~\(Int(safeGoalIU.rounded())) IU at current settings). MED (burn risk) still tracks separately — only you stop the session."
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.62))
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(.orange.opacity(0.12), in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.orange.opacity(0.28), lineWidth: 1)
        }
    }
}

import SwiftUI
import WidgetKit

struct SunSessionLiveActivityLockScreenView: View {
    let context: ActivityViewContext<SunSessionActivityAttributes>

    private var goalTimerInterval: ClosedRange<Date>? {
        SunSessionLiveActivityMetrics.goalTimerInterval(
            attributes: context.attributes,
            state: context.state
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            titleRow

            Text(context.attributes.locationName)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            HStack(alignment: .center, spacing: 10) {
                timerColumn
                    .frame(maxWidth: .infinity, alignment: .leading)

                SunSessionGoalDialView(
                    goalProgress: context.state.goalProgress,
                    goalTimerInterval: goalTimerInterval,
                    isPaused: context.state.isPaused,
                    diameter: 54,
                    lineWidth: 4
                )

                SunSessionLiveActivityLiveMetricsColumn(
                    attributes: context.attributes,
                    state: context.state
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            controlRow

            BigDoseCompactWeatherAttributionView()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var titleRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("BigDose")
                .font(.bigDoseWordmark(18))
                .foregroundStyle(WidgetBrandColors.solarGold)

            Text("Sun Session")
                .font(.bigDoseHeader(.caption))
                .foregroundStyle(WidgetBrandColors.solarGold.opacity(0.88))

            Spacer(minLength: 0)

            Text("UV \(context.attributes.uvIndex.formatted(.number.precision(.fractionLength(1))))")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.82))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.white.opacity(0.10), in: .capsule)
        }
    }

    private var timerColumn: some View {
        Group {
            if context.state.isPaused {
                VStack(alignment: .leading, spacing: 4) {
                    Text(SunSessionLiveActivityFormatting.elapsedClock(
                        SunSessionLiveActivityMetrics.elapsedSeconds(state: context.state)
                    ))
                    .font(.system(size: 30, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)

                    Text("Paused")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.orange)
                }
            } else if let referenceDate = SunSessionLiveActivityMetrics.timerReferenceDate(state: context.state) {
                Text(referenceDate, style: .timer)
                    .font(.system(size: 30, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
        }
    }

    private var controlRow: some View {
        SunSessionLiveActivityControls(
            sessionID: context.attributes.sessionID,
            isPaused: context.state.isPaused,
            pendingControl: context.state.pendingControl,
            style: .lockScreen
        )
    }
}

enum SunSessionLiveActivityFormatting {
    static func elapsedClock(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        let minutes = total / 60
        let remainder = total % 60
        return "\(minutes):\(String(format: "%02d", remainder))"
    }
}

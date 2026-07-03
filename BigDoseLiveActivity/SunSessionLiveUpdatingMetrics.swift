import SwiftUI

/// Static metrics snapshot; pass live values from SunSessionLiveUpdatingMetricsView when running.
struct SunSessionLiveActivityLiveMetricsColumn: View {
    let attributes: SunSessionActivityAttributes
    let state: SunSessionActivityAttributes.ContentState
    var estimatedIU: Double?
    var goalProgress: Double?
    var iuFont: Font = .system(size: 30, weight: .black, design: .rounded)
    var progressWidth: CGFloat = 96

    private var resolvedEstimatedIU: Double {
        estimatedIU ?? state.estimatedIU
    }

    private var resolvedGoalProgress: Double {
        goalProgress ?? state.goalProgress
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("\(Int(resolvedEstimatedIU.rounded())) IU")
                .font(iuFont)
                .foregroundStyle(.white)
                .monospacedDigit()
                .contentTransition(.numericText())

            Text("Goal \(Int(attributes.targetIU.rounded()))")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            ProgressView(value: resolvedGoalProgress)
                .tint(WidgetBrandColors.solarGold)
                .frame(width: progressWidth)
        }
    }
}

/// Timeline-backed metrics for widgets where TimelineView ticks reliably.
struct SunSessionLiveUpdatingMetricsView<Content: View>: View {
    let attributes: SunSessionActivityAttributes
    let state: SunSessionActivityAttributes.ContentState
    @ViewBuilder var content: (_ estimatedIU: Double, _ goalProgress: Double) -> Content

    var body: some View {
        if state.isPaused {
            content(state.estimatedIU, state.goalProgress)
        } else if let anchor = SunSessionLiveActivityMetrics.timerReferenceDate(state: state) {
            TimelineView(.animation(minimumInterval: 1.0, paused: false)) { timeline in
                let metrics = liveMetrics(at: timeline.date)
                content(metrics.estimatedIU, metrics.goalProgress)
            }
            .id(anchor)
        } else {
            content(state.estimatedIU, state.goalProgress)
        }
    }

    private func liveMetrics(at date: Date) -> (estimatedIU: Double, goalProgress: Double) {
        let elapsed = SunSessionLiveActivityMetrics.elapsedSeconds(state: state, now: date)
        let estimatedIU = SunSessionLiveActivityMetrics.estimatedIU(
            elapsedSeconds: elapsed,
            iuPerMinute: attributes.iuPerMinute
        )
        let goalProgress = SunSessionLiveActivityMetrics.goalProgress(
            estimatedIU: estimatedIU,
            targetIU: attributes.targetIU
        )
        return (estimatedIU, goalProgress)
    }
}

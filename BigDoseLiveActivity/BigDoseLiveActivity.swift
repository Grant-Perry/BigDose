import ActivityKit
import SwiftUI
import WidgetKit

@main
struct BigDoseLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        BigDoseHomeWidget()
        SunSessionLiveActivityWidget()
    }
}

struct SunSessionLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SunSessionActivityAttributes.self) { context in
            SunSessionLiveActivityLockScreenView(context: context)
                .activityBackgroundTint(WidgetBrandColors.midnightBlue.opacity(0.84))
                .activitySystemActionForegroundColor(WidgetBrandColors.solarGold)
                .widgetURL(SunSessionActivityAttributes.appOpenURL(sessionID: context.attributes.sessionID))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        BigDoseLiveActivityLogo()
                            .frame(width: 24, height: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.attributes.locationName)
                                .font(.caption.weight(.semibold))
                            Text("UV \(context.attributes.uvIndex.formatted(.number.precision(.fractionLength(1))))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    SunSessionLiveActivityDynamicIslandMetrics(context: context)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 10) {
                        SunSessionLiveActivityDynamicIslandTimer(context: context)
                            .font(.title3.weight(.semibold))

                        Spacer()

                        if context.state.isPaused {
                            Button(intent: ResumeSunSessionLiveActivityIntent(sessionID: context.attributes.sessionID)) {
                                Image(systemName: "play.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        } else {
                            Button(intent: PauseSunSessionLiveActivityIntent(sessionID: context.attributes.sessionID)) {
                                Image(systemName: "pause.fill")
                            }
                            .buttonStyle(.bordered)
                        }
                        Button(intent: EndSunSessionLiveActivityIntent(sessionID: context.attributes.sessionID)) {
                            Image(systemName: "stop.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                }
            } compactLeading: {
                BigDoseLiveActivityLogo()
                    .frame(width: 20, height: 20)
            } compactTrailing: {
                SunSessionLiveActivityDynamicIslandTimer(context: context)
            } minimal: {
                SunSessionLiveActivityDynamicIslandTimer(context: context)
                    .font(.caption2.weight(.black))
            }
            .widgetURL(SunSessionActivityAttributes.appOpenURL(sessionID: context.attributes.sessionID))
        }
    }
}

private struct SunSessionLiveActivityDynamicIslandTimer: View {
    let context: ActivityViewContext<SunSessionActivityAttributes>

    var body: some View {
        if context.state.isPaused {
            Text(SunSessionLiveActivityFormatting.elapsedClock(
                SunSessionLiveActivityMetrics.elapsedSeconds(state: context.state)
            ))
            .monospacedDigit()
        } else if let referenceDate = SunSessionLiveActivityMetrics.timerReferenceDate(state: context.state) {
            Text(referenceDate, style: .timer)
                .monospacedDigit()
                .frame(minWidth: 44)
        } else {
            Text("0:00")
                .monospacedDigit()
        }
    }
}

private struct SunSessionLiveActivityDynamicIslandMetrics: View {
    let context: ActivityViewContext<SunSessionActivityAttributes>

    var body: some View {
        SunSessionLiveActivityMetricsColumn(
            attributes: context.attributes,
            state: context.state,
            iuFont: .headline.weight(.black),
            progressWidth: 88
        )
    }
}

#Preview("Sun session (ActivityKit)", as: .content, using: SunSessionActivityAttributes.previewSession) {
    SunSessionLiveActivityWidget()
} contentStates: {
    SunSessionActivityAttributes.ContentState.previewRunning()
}

import WidgetKit
import SwiftUI

struct BigDoseHomeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: BigDoseWidgetKind.home, provider: BigDoseHomeWidgetProvider()) { entry in
            BigDoseHomeWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [WidgetBrandColors.midnightBlue, WidgetBrandColors.deepSpace],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                .widgetURL(entry.snapshot.widgetDeepLinkURL)
        }
        .configurationDisplayName("Vitamin D Window")
        .description("Next sun window, UV, and today's D progress.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryCircular])
    }
}

private struct BigDoseHomeWidgetProvider: TimelineProvider {
    private let activeSessionHorizonSeconds = 300

    func placeholder(in context: Context) -> BigDoseHomeWidgetEntry {
        BigDoseHomeWidgetEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (BigDoseHomeWidgetEntry) -> Void) {
        let snapshot = BigDoseWidgetSnapshotStore.load() ?? .placeholder
        completion(BigDoseHomeWidgetEntry(date: .now, snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BigDoseHomeWidgetEntry>) -> Void) {
        let snapshot = BigDoseWidgetSnapshotStore.load() ?? .placeholder
        let now = Date.now

        if snapshot.activeSession != nil {
            let entries = (0...activeSessionHorizonSeconds).map { offset in
                BigDoseHomeWidgetEntry(
                    date: now.addingTimeInterval(TimeInterval(offset)),
                    snapshot: snapshot
                )
            }
            completion(Timeline(entries: entries, policy: .atEnd))
            return
        }

        let entry = BigDoseHomeWidgetEntry(date: now, snapshot: snapshot)
        completion(Timeline(entries: [entry], policy: .after(snapshot.nextTimelineRefreshDate)))
    }
}

struct BigDoseHomeWidgetEntry: TimelineEntry {
    var date: Date
    var snapshot: BigDoseWidgetSnapshot
}

struct BigDoseHomeWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: BigDoseHomeWidgetEntry

    var body: some View {
        if let session = entry.snapshot.activeSession {
            switch family {
            case .systemSmall:
                activeSessionSmallView(session, now: entry.date)
            case .systemMedium:
                activeSessionMediumView(session, now: entry.date)
            case .accessoryInline:
                activeSessionInlineView(session, now: entry.date)
            case .accessoryCircular:
                activeSessionCircularView(session, now: entry.date)
            default:
                activeSessionSmallView(session, now: entry.date)
            }
        } else {
            switch family {
            case .systemSmall:
                windowSmallView
            case .systemMedium:
                windowMediumView
            case .accessoryInline:
                windowInlineView
            case .accessoryCircular:
                windowCircularView
            default:
                windowSmallView
            }
        }
    }

    private func activeSessionSmallView(_ session: ActiveSessionWidgetState, now: Date) -> some View {
        let metrics = sessionMetrics(session, now: now)

        return VStack(alignment: .leading, spacing: 8) {
            BigDoseWordmarkHeader()

            Text("Sun Session")
                .font(.bigDoseHeader(.caption))
                .foregroundStyle(WidgetBrandColors.solarGold)

            sessionTimerText(session, now: now)
                .font(.title2.weight(.bold).monospacedDigit())
                .foregroundStyle(.white)

            Text("\(Int(metrics.estimatedIU.rounded())) / \(Int(session.targetIU.rounded())) IU")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.76))

            ProgressView(value: metrics.progress)
                .tint(WidgetBrandColors.solarGold)

            if session.isPaused {
                Text("Paused")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.orange)
            }
        }
    }

    private func activeSessionMediumView(_ session: ActiveSessionWidgetState, now: Date) -> some View {
        let metrics = sessionMetrics(session, now: now)
        let timerReference = widgetTimerReference(session)

        return VStack(alignment: .leading, spacing: 8) {
            BigDoseWordmarkHeader()

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sun Session Live")
                        .font(.bigDoseHeader(.caption))
                        .foregroundStyle(WidgetBrandColors.solarGold)

                    sessionTimerText(session, now: now)
                        .font(.system(size: 30, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)

                    Text(session.locationName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.68))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                SunSessionGoalDialView(
                    goalProgress: metrics.progress,
                    goalTimerInterval: widgetGoalTimerInterval(session),
                    isPaused: session.isPaused,
                    diameter: 64,
                    lineWidth: 5,
                    liveProgressAnchor: timerReference
                )

                VStack(spacing: 8) {
                    Text("\(Int(metrics.estimatedIU.rounded()))")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()

                    Text("IU")
                        .font(.bigDoseHeader(.caption))
                        .foregroundStyle(WidgetBrandColors.solarGold)

                    Text("\(Int(metrics.progress * 100))% goal")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.68))
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private func activeSessionInlineView(_ session: ActiveSessionWidgetState, now: Date) -> some View {
        let metrics = sessionMetrics(session, now: now)
        return Text("Sun \(formattedElapsed(metrics.elapsed)) · \(Int(metrics.estimatedIU.rounded())) IU")
    }

    private func activeSessionCircularView(_ session: ActiveSessionWidgetState, now: Date) -> some View {
        let metrics = sessionMetrics(session, now: now)

        return ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Text("\(Int(metrics.progress * 100))%")
                    .font(.caption2.weight(.black))
                Image(systemName: "sun.max.fill")
                    .font(.caption2)
            }
        }
    }

    private var windowSmallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            BigDoseWordmarkHeader(
                trailingText: "UV \(entry.snapshot.currentUVIndex.formatted(.number.precision(.fractionLength(0))))"
            )

            Text(windowHeadline)
                .font(.bigDoseHeader(.headline))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 0)

            HStack {
                Spacer(minLength: 0)
                SunSessionGoalDialView(
                    goalProgress: entry.snapshot.todayGoalProgress,
                    goalTimerInterval: nil,
                    isPaused: true,
                    diameter: 52,
                    lineWidth: 4,
                    progressCaption: "today"
                )
                Spacer(minLength: 0)
            }

            Text("\(Int(entry.snapshot.todayCollectedIU.rounded())) / \(entry.snapshot.targetIU) IU")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))
        }
    }

    private var windowMediumView: some View {
        VStack(alignment: .leading, spacing: 8) {
            BigDoseWordmarkHeader()

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Vitamin D Window")
                        .font(.bigDoseHeader(.caption))
                        .foregroundStyle(WidgetBrandColors.solarGold)

                    Text(windowHeadline)
                        .font(.bigDoseHeader(.title3))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    if let detail = windowDetail {
                        Text(detail)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.68))
                            .lineLimit(2)
                            .minimumScaleFactor(0.75)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 8) {
                    SunSessionGoalDialView(
                        goalProgress: entry.snapshot.todayGoalProgress,
                        goalTimerInterval: nil,
                        isPaused: true,
                        diameter: 68,
                        lineWidth: 5,
                        progressCaption: "today"
                    )

                    Text("Peak UV \(entry.snapshot.peakUVIndex.formatted(.number.precision(.fractionLength(1))))")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
                        .lineLimit(1)
                }
            }
        }
    }

    private var windowInlineView: some View {
        Text("\(windowHeadline) · \(Int(entry.snapshot.todayCollectedIU.rounded()))/\(entry.snapshot.targetIU) IU")
    }

    private var windowCircularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Image(systemName: entry.snapshot.isInBestWindow ? "sun.max.fill" : "clock.fill")
                    .font(.caption.weight(.bold))
                Text("\(Int(entry.snapshot.todayGoalProgress * 100))%")
                    .font(.caption2.weight(.black))
            }
        }
    }

    @ViewBuilder
    private func sessionTimerText(_ session: ActiveSessionWidgetState, now: Date) -> some View {
        if session.isPaused {
            Text(formattedElapsed(sessionMetrics(session, now: now).elapsed))
        } else if let reference = widgetTimerReference(session) {
            Text(reference, style: .timer)
                .monospacedDigit()
        } else {
            Text(formattedElapsed(0))
        }
    }

    private func sessionMetrics(_ session: ActiveSessionWidgetState, now: Date) -> (elapsed: TimeInterval, estimatedIU: Double, progress: Double) {
        let elapsed = widgetElapsedSeconds(session, now: now)
        let estimatedIU = SunSessionLiveActivityMetrics.estimatedIU(
            elapsedSeconds: elapsed,
            iuPerMinute: session.iuPerMinute
        )
        let progress = SunSessionLiveActivityMetrics.goalProgress(
            estimatedIU: estimatedIU,
            targetIU: session.targetIU
        )
        return (elapsed, estimatedIU, progress)
    }

    private func widgetElapsedSeconds(_ session: ActiveSessionWidgetState, now: Date) -> TimeInterval {
        if session.isPaused {
            return session.elapsedOffsetSeconds
        }

        guard let runningSince = session.runningSince else {
            return session.elapsedOffsetSeconds
        }

        return session.elapsedOffsetSeconds + now.timeIntervalSince(runningSince)
    }

    private func widgetTimerReference(_ session: ActiveSessionWidgetState) -> Date? {
        guard !session.isPaused, let runningSince = session.runningSince else { return nil }
        return runningSince.addingTimeInterval(-session.elapsedOffsetSeconds)
    }

    private func widgetGoalTimerInterval(_ session: ActiveSessionWidgetState) -> ClosedRange<Date>? {
        guard !session.isPaused, let effectiveStart = widgetTimerReference(session) else { return nil }
        let duration = SunSessionLiveActivityMetrics.goalDurationSeconds(
            targetIU: session.targetIU,
            iuPerMinute: session.iuPerMinute
        )
        return effectiveStart...effectiveStart.addingTimeInterval(duration)
    }

    private func formattedElapsed(_ seconds: TimeInterval) -> String {
        SunSessionLiveActivityFormatting.elapsedClock(seconds)
    }

    private var windowHeadline: String {
        let snapshot = entry.snapshot

        guard snapshot.isOnboardingComplete else {
            return "Finish setup in BigDose"
        }

        if snapshot.isInBestWindow {
            return "Best window now"
        }

        if let start = snapshot.nextUsefulStart ?? snapshot.bestWindowStart {
            return "Next window \(WidgetTimeFormatting.compactTime(start))"
        }

        return snapshot.windowQualityTitle
    }

    private var windowDetail: String? {
        let snapshot = entry.snapshot

        guard let start = snapshot.bestWindowStart, let end = snapshot.bestWindowEnd else {
            return snapshot.locationLabel
        }

        return WidgetTimeFormatting.compactRange(start: start, end: end)
    }
}

enum WidgetTimeFormatting {
    static func compactTime(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    static func compactRange(start: Date, end: Date) -> String {
        let startText = start.formatted(date: .omitted, time: .shortened)
        let endText = end.formatted(date: .omitted, time: .shortened)
        return "Best \(startText)–\(endText)"
    }
}

#Preview(as: .systemSmall) {
    BigDoseHomeWidget()
} timeline: {
    BigDoseHomeWidgetEntry(date: .now, snapshot: .placeholder)
}

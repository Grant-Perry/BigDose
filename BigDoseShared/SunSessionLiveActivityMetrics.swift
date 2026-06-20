import Foundation

nonisolated enum SunSessionLiveActivityMetrics {
    static func elapsedSeconds(
        state: SunSessionActivityAttributes.ContentState,
        now: Date = .now
    ) -> TimeInterval {
        if state.isPaused {
            return state.elapsedOffsetSeconds
        }

        guard let runningSince = state.runningSince else {
            return state.elapsedOffsetSeconds
        }

        return state.elapsedOffsetSeconds + now.timeIntervalSince(runningSince)
    }

    /// Date anchor for `Text(_:style: .timer)` so the lock screen timer ticks without app updates.
    static func timerReferenceDate(state: SunSessionActivityAttributes.ContentState) -> Date? {
        guard !state.isPaused, let runningSince = state.runningSince else { return nil }
        return runningSince.addingTimeInterval(-state.elapsedOffsetSeconds)
    }

    static func estimatedIU(elapsedSeconds: TimeInterval, iuPerMinute: Double) -> Double {
        guard elapsedSeconds > 0 else { return 0 }
        return iuPerMinute * (elapsedSeconds / 60)
    }

    static func goalProgress(estimatedIU: Double, targetIU: Double) -> Double {
        guard targetIU > 0 else { return 0 }
        return min(max(estimatedIU / targetIU, 0), 1)
    }

    static func goalDurationSeconds(targetIU: Double, iuPerMinute: Double) -> TimeInterval {
        max(60, (targetIU / max(iuPerMinute, 0.01)) * 60)
    }

    /// Interval for `ProgressView(timerInterval:)` so goal progress ticks on the lock screen.
    static func goalTimerInterval(
        attributes: SunSessionActivityAttributes,
        state: SunSessionActivityAttributes.ContentState
    ) -> ClosedRange<Date>? {
        guard let effectiveStart = timerReferenceDate(state: state) else { return nil }
        let duration = goalDurationSeconds(
            targetIU: attributes.targetIU,
            iuPerMinute: attributes.iuPerMinute
        )
        return effectiveStart...effectiveStart.addingTimeInterval(duration)
    }
}

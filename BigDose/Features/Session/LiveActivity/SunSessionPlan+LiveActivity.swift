import Foundation

extension SunSessionPlan {
    var liveActivitySessionID: String {
        "sun-\(Int(startedAt.timeIntervalSince1970))"
    }

    func liveActivityAttributes() -> SunSessionActivityAttributes {
        SunSessionActivityAttributes(
            sessionID: liveActivitySessionID,
            targetIU: targetIU,
            uvIndex: uvIndex,
            locationName: locationName,
            iuPerMinute: liveIUProductionRatePerMinute,
            sessionStartedAt: startedAt
        )
    }

    func liveActivityContentState(
        elapsedSeconds: TimeInterval,
        isPaused: Bool
    ) -> SunSessionActivityAttributes.ContentState {
        let estimatedIU = estimatedIU(at: elapsedSeconds)
        let goalProgress = goalProgress(at: elapsedSeconds)

        if isPaused {
            return SunSessionActivityAttributes.ContentState(
                isPaused: true,
                elapsedOffsetSeconds: elapsedSeconds,
                runningSince: nil,
                estimatedIU: estimatedIU,
                goalProgress: goalProgress,
                pendingControl: .none
            )
        }

        let timing = SunSessionLiveActivityMetrics.runningStateTiming(elapsedSeconds: elapsedSeconds)
        return SunSessionActivityAttributes.ContentState(
            isPaused: false,
            elapsedOffsetSeconds: timing.elapsedOffsetSeconds,
            runningSince: timing.runningSince,
            estimatedIU: estimatedIU,
            goalProgress: goalProgress,
            pendingControl: .none
        )
    }
}

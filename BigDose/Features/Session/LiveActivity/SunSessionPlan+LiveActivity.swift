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

        // Anchor to the real session start so the lock screen timer ticks without app updates.
        return SunSessionActivityAttributes.ContentState(
            isPaused: false,
            elapsedOffsetSeconds: 0,
            runningSince: startedAt,
            estimatedIU: estimatedIU,
            goalProgress: goalProgress,
            pendingControl: .none
        )
    }
}

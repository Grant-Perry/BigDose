import Foundation

enum BigDoseWidgetActiveSessionUpdater {
    static func publish(
        plan: SunSessionPlan,
        elapsedSeconds: TimeInterval,
        isPaused: Bool
    ) {
        var snapshot = BigDoseWidgetSnapshotStore.load() ?? .placeholder

        if isPaused {
            snapshot.activeSession = ActiveSessionWidgetState(
                sessionID: plan.liveActivitySessionID,
                locationName: plan.locationName,
                isPaused: true,
                elapsedOffsetSeconds: elapsedSeconds,
                runningSince: nil,
                iuPerMinute: plan.liveIUProductionRatePerMinute,
                targetIU: plan.targetIU,
                sessionStartedAt: plan.startedAt
            )
        } else {
            let timing = SunSessionLiveActivityMetrics.runningStateTiming(elapsedSeconds: elapsedSeconds)
            snapshot.activeSession = ActiveSessionWidgetState(
                sessionID: plan.liveActivitySessionID,
                locationName: plan.locationName,
                isPaused: false,
                elapsedOffsetSeconds: timing.elapsedOffsetSeconds,
                runningSince: timing.runningSince,
                iuPerMinute: plan.liveIUProductionRatePerMinute,
                targetIU: plan.targetIU,
                sessionStartedAt: plan.startedAt
            )
        }

        snapshot.generatedAt = .now
        BigDoseWidgetSnapshotStore.save(snapshot)
        BigDoseWidgetReloader.reloadHomeWidget()
    }

    static func clearActiveSession() {
        guard var snapshot = BigDoseWidgetSnapshotStore.load() else { return }
        snapshot.activeSession = nil
        snapshot.generatedAt = .now
        BigDoseWidgetSnapshotStore.save(snapshot)
        BigDoseWidgetReloader.reloadHomeWidget()
    }
}

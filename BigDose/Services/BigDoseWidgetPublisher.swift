import Foundation

@MainActor
enum BigDoseWidgetPublisher {
    static func publish(
        profile: UserProfile,
        plan: DailySunPlan?,
        weather: BigDoseWeatherSnapshot?,
        todayCollectedIU: Double,
        activeSessionPlan: SunSessionPlan? = nil,
        activeSessionElapsed: TimeInterval = 0,
        activeSessionIsPaused: Bool = false
    ) {
        let snapshot = BigDoseWidgetSnapshotBuilder.makeSnapshot(
            profile: profile,
            plan: plan,
            weather: weather,
            todayCollectedIU: todayCollectedIU,
            activeSessionPlan: activeSessionPlan,
            activeSessionElapsed: activeSessionElapsed,
            activeSessionIsPaused: activeSessionIsPaused
        )
        BigDoseWidgetSnapshotStore.save(snapshot)
        BigDoseWidgetReloader.reloadHomeWidget()
    }

    static func publishFromStores(
        profile: UserProfile,
        plan: DailySunPlan?,
        weather: BigDoseWeatherSnapshot?,
        todayCollectedIU: Double
    ) {
        let snapshot = BigDoseWidgetSnapshotBuilder.makeSnapshot(
            profile: profile,
            plan: plan,
            weather: weather,
            todayCollectedIU: todayCollectedIU
        )
        BigDoseWidgetSnapshotStore.save(snapshot)
        BigDoseWidgetReloader.reloadHomeWidget()
    }
}

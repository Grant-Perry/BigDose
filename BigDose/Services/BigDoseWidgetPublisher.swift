import Foundation

@MainActor
enum BigDoseWidgetPublisher {
    static func publish(
        profile: UserProfile,
        plan: DailySunPlan?,
        weather: BigDoseWeatherSnapshot?,
        todaySunIU: Double,
        todaySupplementIU: Double,
        totalDailyTargetIU: Int,
        activeSessionPlan: SunSessionPlan? = nil,
        activeSessionElapsed: TimeInterval = 0,
        activeSessionIsPaused: Bool = false
    ) {
        let snapshot = BigDoseWidgetSnapshotBuilder.makeSnapshot(
            profile: profile,
            plan: plan,
            weather: weather,
            todaySunIU: todaySunIU,
            todaySupplementIU: todaySupplementIU,
            totalDailyTargetIU: totalDailyTargetIU,
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
        todaySunIU: Double,
        todaySupplementIU: Double,
        totalDailyTargetIU: Int
    ) {
        let snapshot = BigDoseWidgetSnapshotBuilder.makeSnapshot(
            profile: profile,
            plan: plan,
            weather: weather,
            todaySunIU: todaySunIU,
            todaySupplementIU: todaySupplementIU,
            totalDailyTargetIU: totalDailyTargetIU
        )
        BigDoseWidgetSnapshotStore.save(snapshot)
        BigDoseWidgetReloader.reloadHomeWidget()
    }
}

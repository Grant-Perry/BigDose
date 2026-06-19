import Foundation

enum BigDoseWidgetSnapshotBuilder {
    static func makeSnapshot(
        profile: UserProfile,
        plan: DailySunPlan?,
        weather: BigDoseWeatherSnapshot?,
        todayCollectedIU: Double,
        activeSessionPlan: SunSessionPlan? = nil,
        activeSessionElapsed: TimeInterval = 0,
        activeSessionIsPaused: Bool = false,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> BigDoseWidgetSnapshot {
        let bestStart = plan?.bestWindowStart ?? plan?.nextUsefulStart
        let bestEnd = plan?.bestWindowEnd ?? plan?.nextUsefulEnd
        let isInBestWindow: Bool = {
            guard let start = bestStart, let end = bestEnd else { return false }
            return now >= start && now <= end
        }()

        let activeSession = activeSessionWidgetState(
            plan: activeSessionPlan,
            elapsedSeconds: activeSessionElapsed,
            isPaused: activeSessionIsPaused
        )

        return BigDoseWidgetSnapshot(
            generatedAt: now,
            locationLabel: plan?.locationLabel ?? "Current Location",
            currentUVIndex: weather?.uvIndex ?? plan?.peakUVIndex ?? 0,
            peakUVIndex: plan?.peakUVIndex ?? weather?.uvIndex ?? 0,
            windowQualityTitle: plan?.quality.title ?? "Open app",
            bestWindowStart: plan?.bestWindowStart,
            bestWindowEnd: plan?.bestWindowEnd,
            nextUsefulStart: plan?.nextUsefulStart,
            nextUsefulEnd: plan?.nextUsefulEnd,
            todayCollectedIU: todayCollectedIU,
            targetIU: profile.preferredDailyIU,
            isInBestWindow: isInBestWindow,
            isOnboardingComplete: profile.isOnboardingComplete,
            activeSession: activeSession
        )
    }

    static func makeSnapshot(
        profile: UserProfile,
        plan: DailySunPlan?,
        weather: BigDoseWeatherSnapshot?,
        todayCollectedIU: Double,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> BigDoseWidgetSnapshot {
        if let record = ActiveSunSessionStore.load() {
            let sessionPlan = ActiveSunSessionPersistence.plan(from: record)
            return makeSnapshot(
                profile: profile,
                plan: plan,
                weather: weather,
                todayCollectedIU: todayCollectedIU,
                activeSessionPlan: sessionPlan,
                activeSessionElapsed: record.currentElapsed(now: now),
                activeSessionIsPaused: record.isPaused,
                now: now,
                calendar: calendar
            )
        }

        return makeSnapshot(
            profile: profile,
            plan: plan,
            weather: weather,
            todayCollectedIU: todayCollectedIU,
            activeSessionPlan: nil,
            activeSessionElapsed: 0,
            activeSessionIsPaused: false,
            now: now,
            calendar: calendar
        )
    }

    private static func activeSessionWidgetState(
        plan: SunSessionPlan?,
        elapsedSeconds: TimeInterval,
        isPaused: Bool
    ) -> ActiveSessionWidgetState? {
        guard let plan else { return nil }

        if isPaused {
            return ActiveSessionWidgetState(
                sessionID: plan.liveActivitySessionID,
                locationName: plan.locationName,
                isPaused: true,
                elapsedOffsetSeconds: elapsedSeconds,
                runningSince: nil,
                iuPerMinute: plan.liveIUProductionRatePerMinute,
                targetIU: plan.targetIU,
                sessionStartedAt: plan.startedAt
            )
        }

        return ActiveSessionWidgetState(
            sessionID: plan.liveActivitySessionID,
            locationName: plan.locationName,
            isPaused: false,
            elapsedOffsetSeconds: 0,
            runningSince: plan.startedAt,
            iuPerMinute: plan.liveIUProductionRatePerMinute,
            targetIU: plan.targetIU,
            sessionStartedAt: plan.startedAt
        )
    }
}

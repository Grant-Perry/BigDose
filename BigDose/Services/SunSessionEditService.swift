import Foundation

enum SunSessionEditService {
    static func isEditable(_ session: ExposureSession) -> Bool {
        session.source == .liveTracked
    }

    static func plan(from session: ExposureSession, profile: UserProfile) -> SunSessionPlan? {
        let cloudCover = CloudCoverPreset(rawValue: session.cloudCoverRaw) ?? .clear
        let skinType = FitzpatrickSkinType(rawValue: session.skinTypeRaw) ?? profile.skinType

        return SunSessionPlan(
            startedAt: session.startedAt,
            durationSeconds: max(session.durationSeconds, 60),
            exposedBodySurfaceArea: session.exposedBodySurfaceArea,
            cloudCover: cloudCover,
            sunscreenTransmission: session.sunscreenFactor,
            uvIndex: session.maxUVIndex > 0 ? session.maxUVIndex : session.averageUVIndex,
            currentTemperatureFahrenheit: 72,
            skinType: skinType,
            locationName: session.locationLabel ?? "Sun session",
            targetIU: session.resolvedSessionTargetIU(profile: profile),
            exitLeadFraction: profile.prepareExitLeadFraction,
            latitude: session.latitude ?? 0,
            longitude: session.longitude ?? 0
        )
    }

    static func metrics(
        for session: ExposureSession,
        profile: UserProfile,
        durationSeconds: TimeInterval
    ) -> SunSessionEditMetrics? {
        guard let plan = plan(from: session, profile: profile) else { return nil }

        let clampedDuration = clampedDurationSeconds(durationSeconds)
        let medUsed = plan.medUsedPercent(at: clampedDuration)

        return SunSessionEditMetrics(
            durationSeconds: clampedDuration,
            estimatedIU: plan.estimatedIU(at: clampedDuration),
            peakMedUsedPercent: medUsed,
            medOverLimitPercent: SunSessionSafetyThresholds.medOverLimitPercent(for: medUsed),
            iuPerMinute: plan.liveIUProductionRatePerMinute
        )
    }

    static func apply(
        durationSeconds: TimeInterval,
        to session: ExposureSession,
        profile: UserProfile
    ) {
        guard let metrics = metrics(for: session, profile: profile, durationSeconds: durationSeconds) else {
            return
        }

        session.durationSeconds = metrics.durationSeconds
        session.endedAt = session.startedAt.addingTimeInterval(metrics.durationSeconds)
        session.estimatedIU = metrics.estimatedIU
        session.peakMedUsedPercent = metrics.peakMedUsedPercent
        session.medOverLimitPercent = metrics.medOverLimitPercent
    }

    static func clampedDurationSeconds(_ seconds: TimeInterval) -> TimeInterval {
        max(60, (seconds / 60).rounded() * 60)
    }
}

struct SunSessionEditMetrics: Equatable {
    var durationSeconds: TimeInterval
    var estimatedIU: Double
    var peakMedUsedPercent: Int
    var medOverLimitPercent: Int
    var iuPerMinute: Double
}

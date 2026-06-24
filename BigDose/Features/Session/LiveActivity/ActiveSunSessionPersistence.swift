import Foundation

enum ActiveSunSessionPersistence {
    static func record(
        from plan: SunSessionPlan,
        elapsedSeconds: TimeInterval,
        isPaused: Bool,
        acknowledgedSafetyAlertIDs: [String] = [],
        now: Date = .now
    ) -> ActiveSunSessionRecord {
        ActiveSunSessionRecord(
            sessionID: plan.liveActivitySessionID,
            startedAt: plan.startedAt,
            durationSeconds: plan.durationSeconds,
            exposedBodySurfaceArea: plan.exposedBodySurfaceArea,
            cloudCoverRaw: plan.cloudCover.rawValue,
            sunscreenTransmission: plan.sunscreenTransmission,
            uvIndex: plan.uvIndex,
            currentTemperatureFahrenheit: plan.currentTemperatureFahrenheit,
            skinTypeRaw: plan.skinType.rawValue,
            locationName: plan.locationName,
            targetIU: plan.targetIU,
            exitLeadFraction: plan.exitLeadFraction,
            latitude: plan.latitude,
            longitude: plan.longitude,
            elapsedSeconds: elapsedSeconds,
            isPaused: isPaused,
            updatedAt: now,
            acknowledgedSafetyAlertIDs: acknowledgedSafetyAlertIDs
        )
    }

    static func plan(from record: ActiveSunSessionRecord) -> SunSessionPlan? {
        guard
            let cloudCover = CloudCoverPreset(rawValue: record.cloudCoverRaw),
            let skinType = FitzpatrickSkinType(rawValue: record.skinTypeRaw)
        else {
            return nil
        }

        return SunSessionPlan(
            startedAt: record.startedAt,
            durationSeconds: record.durationSeconds,
            exposedBodySurfaceArea: record.exposedBodySurfaceArea,
            cloudCover: cloudCover,
            sunscreenTransmission: record.sunscreenTransmission,
            uvIndex: record.uvIndex,
            currentTemperatureFahrenheit: record.currentTemperatureFahrenheit,
            skinType: skinType,
            locationName: record.locationName,
            targetIU: record.targetIU,
            exitLeadFraction: record.exitLeadFraction,
            latitude: record.latitude,
            longitude: record.longitude
        )
    }

    static func persist(
        plan: SunSessionPlan,
        elapsedSeconds: TimeInterval,
        isPaused: Bool,
        acknowledgedSafetyAlertIDs: [String] = []
    ) {
        let record = record(
            from: plan,
            elapsedSeconds: elapsedSeconds,
            isPaused: isPaused,
            acknowledgedSafetyAlertIDs: acknowledgedSafetyAlertIDs
        )
        ActiveSunSessionStore.save(record)
    }

    static func clear() {
        ActiveSunSessionStore.clear()
    }
}

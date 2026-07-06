import Foundation

nonisolated enum ActiveSunSessionSafetyAlertID {
    static let goalReached = "goalReached"
    static let turnOver = "turnOver"
    static let medWarning = "medWarning"
    static let prepareExit = "prepareExit"

    static func overLimit(percent: Int) -> String {
        "overLimit.\(percent)"
    }
}

nonisolated struct ActiveSunSessionRecord: Codable, Sendable, Equatable {
    var sessionID: String
    var startedAt: Date
    var durationSeconds: TimeInterval
    var exposedBodySurfaceArea: Double
    var cloudCoverRaw: String
    var sunscreenTransmission: Double
    var uvIndex: Double
    var currentTemperatureFahrenheit: Double
    var skinTypeRaw: String
    var locationName: String
    var targetIU: Double
    var exitLeadFraction: Double
    var latitude: Double = 0
    var longitude: Double = 0
    var elapsedSeconds: TimeInterval
    var isPaused: Bool
    var updatedAt: Date
    var acknowledgedSafetyAlertIDs: [String] = []

    private enum CodingKeys: String, CodingKey {
        case sessionID
        case startedAt
        case durationSeconds
        case exposedBodySurfaceArea
        case cloudCoverRaw
        case sunscreenTransmission
        case uvIndex
        case currentTemperatureFahrenheit
        case skinTypeRaw
        case locationName
        case targetIU
        case exitLeadFraction
        case latitude
        case longitude
        case elapsedSeconds
        case isPaused
        case updatedAt
        case acknowledgedSafetyAlertIDs
    }

    init(
        sessionID: String,
        startedAt: Date,
        durationSeconds: TimeInterval,
        exposedBodySurfaceArea: Double,
        cloudCoverRaw: String,
        sunscreenTransmission: Double,
        uvIndex: Double,
        currentTemperatureFahrenheit: Double,
        skinTypeRaw: String,
        locationName: String,
        targetIU: Double,
        exitLeadFraction: Double,
        latitude: Double = 0,
        longitude: Double = 0,
        elapsedSeconds: TimeInterval,
        isPaused: Bool,
        updatedAt: Date,
        acknowledgedSafetyAlertIDs: [String] = []
    ) {
        self.sessionID = sessionID
        self.startedAt = startedAt
        self.durationSeconds = durationSeconds
        self.exposedBodySurfaceArea = exposedBodySurfaceArea
        self.cloudCoverRaw = cloudCoverRaw
        self.sunscreenTransmission = sunscreenTransmission
        self.uvIndex = uvIndex
        self.currentTemperatureFahrenheit = currentTemperatureFahrenheit
        self.skinTypeRaw = skinTypeRaw
        self.locationName = locationName
        self.targetIU = targetIU
        self.exitLeadFraction = exitLeadFraction
        self.latitude = latitude
        self.longitude = longitude
        self.elapsedSeconds = elapsedSeconds
        self.isPaused = isPaused
        self.updatedAt = updatedAt
        self.acknowledgedSafetyAlertIDs = acknowledgedSafetyAlertIDs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sessionID = try container.decode(String.self, forKey: .sessionID)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        durationSeconds = try container.decode(TimeInterval.self, forKey: .durationSeconds)
        exposedBodySurfaceArea = try container.decode(Double.self, forKey: .exposedBodySurfaceArea)
        cloudCoverRaw = try container.decode(String.self, forKey: .cloudCoverRaw)
        sunscreenTransmission = try container.decode(Double.self, forKey: .sunscreenTransmission)
        uvIndex = try container.decode(Double.self, forKey: .uvIndex)
        currentTemperatureFahrenheit = try container.decode(Double.self, forKey: .currentTemperatureFahrenheit)
        skinTypeRaw = try container.decode(String.self, forKey: .skinTypeRaw)
        locationName = try container.decode(String.self, forKey: .locationName)
        targetIU = try container.decode(Double.self, forKey: .targetIU)
        exitLeadFraction = try container.decode(Double.self, forKey: .exitLeadFraction)
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude) ?? 0
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude) ?? 0
        elapsedSeconds = try container.decode(TimeInterval.self, forKey: .elapsedSeconds)
        isPaused = try container.decode(Bool.self, forKey: .isPaused)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        acknowledgedSafetyAlertIDs = try container.decodeIfPresent([String].self, forKey: .acknowledgedSafetyAlertIDs) ?? []
    }

    func currentElapsed(now: Date = .now) -> TimeInterval {
        if isPaused {
            return elapsedSeconds
        }

        return elapsedSeconds + now.timeIntervalSince(updatedAt)
    }

    var liveActivityContentState: SunSessionActivityAttributes.ContentState {
        let elapsed = currentElapsed()
        let estimatedIU = SunSessionLiveActivityMetrics.estimatedIU(
            elapsedSeconds: elapsed,
            iuPerMinute: max(targetIU / max(durationSeconds / 60, 1), 0)
        )
        let goalProgress = SunSessionLiveActivityMetrics.goalProgress(
            estimatedIU: estimatedIU,
            targetIU: targetIU
        )

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

        let timing = SunSessionLiveActivityMetrics.runningStateTiming(elapsedSeconds: elapsed)
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

nonisolated struct ActiveSessionWidgetState: Codable, Sendable, Equatable {
    var sessionID: String
    var locationName: String
    var isPaused: Bool
    var elapsedOffsetSeconds: TimeInterval
    var runningSince: Date?
    var iuPerMinute: Double
    var targetIU: Double
    var sessionStartedAt: Date
}

nonisolated enum ActiveSunSessionStore {
    private static let storageKey = "bigdose.activeSunSession"

    nonisolated static func load() -> ActiveSunSessionRecord? {
        guard
            let defaults = UserDefaults(suiteName: BigDoseAppGroup.identifier),
            let data = defaults.data(forKey: storageKey)
        else {
            return nil
        }

        return try? JSONDecoder().decode(ActiveSunSessionRecord.self, from: data)
    }

    nonisolated static func save(_ record: ActiveSunSessionRecord) {
        guard
            let defaults = UserDefaults(suiteName: BigDoseAppGroup.identifier),
            let data = try? JSONEncoder().encode(record)
        else {
            return
        }

        defaults.set(data, forKey: storageKey)
    }

    nonisolated static func clear() {
        UserDefaults(suiteName: BigDoseAppGroup.identifier)?.removeObject(forKey: storageKey)
    }
}

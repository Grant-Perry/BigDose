import Foundation

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

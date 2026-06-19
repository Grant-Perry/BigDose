import ActivityKit
import Foundation

/// Shared between the app (start/update) and the widget extension (presentation).
struct SunSessionActivityAttributes: ActivityAttributes, Equatable {
    struct ContentState: Codable, Hashable {
        var isPaused: Bool
        /// Total elapsed time accumulated before the current running segment.
        var elapsedOffsetSeconds: TimeInterval
        /// Start of the current unpaused segment; nil while paused.
        var runningSince: Date?
        /// Pushed from the app so IU stays current on the lock screen.
        var estimatedIU: Double
        var goalProgress: Double
    }

    var sessionID: String
    var targetIU: Double
    var uvIndex: Double
    var locationName: String
    var iuPerMinute: Double
    var sessionStartedAt: Date
}

// MARK: - Deep link

extension SunSessionActivityAttributes {
    static func appOpenURL(sessionID: String) -> URL? {
        guard !sessionID.isEmpty else { return nil }
        return URL(string: "bigdose://session/\(sessionID)")
    }

    static func sessionID(fromDeepLink url: URL) -> String? {
        guard url.scheme == "bigdose", url.host == "session" else { return nil }
        let id = url.lastPathComponent
        return id.isEmpty ? nil : id
    }
}

extension Notification.Name {
    static let bigDoseOpenSessionFromLiveActivity = Notification.Name("bigDoseOpenSessionFromLiveActivity")
}

extension SunSessionActivityAttributes.ContentState {
    static func running(startedAt: Date, estimatedIU: Double = 0, goalProgress: Double = 0) -> Self {
        Self(
            isPaused: false,
            elapsedOffsetSeconds: 0,
            runningSince: startedAt,
            estimatedIU: estimatedIU,
            goalProgress: goalProgress
        )
    }

    static func previewRunning(elapsedSeconds: TimeInterval = 420) -> Self {
        let attributes = SunSessionActivityAttributes.previewSession
        let estimatedIU = SunSessionLiveActivityMetrics.estimatedIU(
            elapsedSeconds: elapsedSeconds,
            iuPerMinute: attributes.iuPerMinute
        )
        let goalProgress = SunSessionLiveActivityMetrics.goalProgress(
            estimatedIU: estimatedIU,
            targetIU: attributes.targetIU
        )

        return Self(
            isPaused: false,
            elapsedOffsetSeconds: 0,
            runningSince: Date.now.addingTimeInterval(-elapsedSeconds),
            estimatedIU: estimatedIU,
            goalProgress: goalProgress
        )
    }

    static func previewPaused(elapsedSeconds: TimeInterval = 420) -> Self {
        let attributes = SunSessionActivityAttributes.previewSession
        let estimatedIU = SunSessionLiveActivityMetrics.estimatedIU(
            elapsedSeconds: elapsedSeconds,
            iuPerMinute: attributes.iuPerMinute
        )
        let goalProgress = SunSessionLiveActivityMetrics.goalProgress(
            estimatedIU: estimatedIU,
            targetIU: attributes.targetIU
        )

        return Self(
            isPaused: true,
            elapsedOffsetSeconds: elapsedSeconds,
            runningSince: nil,
            estimatedIU: estimatedIU,
            goalProgress: goalProgress
        )
    }
}

extension SunSessionActivityAttributes {
    static let previewSession = SunSessionActivityAttributes(
        sessionID: "preview-session",
        targetIU: 4_000,
        uvIndex: 6.5,
        locationName: "Backyard",
        iuPerMinute: 44,
        sessionStartedAt: .now.addingTimeInterval(-420)
    )
}

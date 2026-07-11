import ActivityKit
import AppIntents
import Foundation

struct PauseSunSessionLiveActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pause Sun Session"
    static var openAppWhenRun = false

    @Parameter(title: "Session ID")
    var sessionID: String

    init() {
        sessionID = ""
    }

    init(sessionID: String) {
        self.sessionID = sessionID
    }

    func perform() async throws -> some IntentResult {
        await SunSessionLiveActivityIntentSupport.requestConfirmedControl(
            sessionID: sessionID,
            control: .pause
        ) { sessionID in
            let elapsed = await SunSessionLiveActivityIntentSupport.pause(sessionID: sessionID)
            ActiveSunSessionStore.applyLiveActivityControl(
                .pause,
                sessionID: sessionID,
                elapsedSeconds: elapsed
            )
            SunSessionLiveActivityCommandStore.request(.pause, sessionID: sessionID)
        }
        return .result()
    }
}

struct ResumeSunSessionLiveActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Resume Sun Session"
    static var openAppWhenRun = false

    @Parameter(title: "Session ID")
    var sessionID: String

    init() {
        sessionID = ""
    }

    init(sessionID: String) {
        self.sessionID = sessionID
    }

    func perform() async throws -> some IntentResult {
        await SunSessionLiveActivityIntentSupport.clearPending(sessionID: sessionID)
        let elapsed = await SunSessionLiveActivityIntentSupport.resume(sessionID: sessionID)
        ActiveSunSessionStore.applyLiveActivityControl(
            .resume,
            sessionID: sessionID,
            elapsedSeconds: elapsed
        )
        SunSessionLiveActivityCommandStore.request(.resume, sessionID: sessionID)
        return .result()
    }
}

struct EndSunSessionLiveActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "End Sun Session"
    static var openAppWhenRun = true

    @Parameter(title: "Session ID")
    var sessionID: String

    init() {
        sessionID = ""
    }

    init(sessionID: String) {
        self.sessionID = sessionID
    }

    func perform() async throws -> some IntentResult {
        await SunSessionLiveActivityIntentSupport.requestConfirmedControl(
            sessionID: sessionID,
            control: .end
        ) { sessionID in
            let elapsed = await SunSessionLiveActivityIntentSupport.frozenElapsed(sessionID: sessionID)
            ActiveSunSessionStore.applyLiveActivityControl(
                .end,
                sessionID: sessionID,
                elapsedSeconds: elapsed
            )
            SunSessionLiveActivityCommandStore.request(.end, sessionID: sessionID)
            await SunSessionLiveActivityIntentSupport.end(sessionID: sessionID)
            SunSessionSharedWidgetCleanup.clearActiveSessionAndReload()
        }
        return .result()
    }
}

enum SunSessionLiveActivityIntentSupport {
    static func requestConfirmedControl(
        sessionID: String,
        control: SunSessionPendingControl,
        perform: @Sendable (String) async -> Void
    ) async {
        var shouldPerform = false

        await update(sessionID: sessionID) { activity in
            var state = activity.content.state
            if state.pendingControl == control {
                shouldPerform = true
                state.pendingControl = .none
            } else {
                state.pendingControl = control
            }
            return state
        }

        guard shouldPerform else { return }
        await perform(sessionID)
    }

    static func clearPending(sessionID: String) async {
        await update(sessionID: sessionID) { activity in
            var state = activity.content.state
            guard state.pendingControl != .none else { return state }
            state.pendingControl = .none
            return state
        }
    }

    @discardableResult
    static func pause(sessionID: String) async -> TimeInterval? {
        var frozenElapsed: TimeInterval?
        await update(sessionID: sessionID) { activity in
            var state = activity.content.state
            guard !state.isPaused else {
                frozenElapsed = state.elapsedOffsetSeconds
                return state
            }

            let elapsed = SunSessionLiveActivityMetrics.elapsedSeconds(state: state)
            frozenElapsed = elapsed
            let metrics = metricsSnapshot(
                attributes: activity.attributes,
                elapsedSeconds: elapsed
            )

            state.isPaused = true
            state.elapsedOffsetSeconds = elapsed
            state.runningSince = nil
            state.estimatedIU = metrics.estimatedIU
            state.goalProgress = metrics.goalProgress
            return state
        }
        return frozenElapsed
    }

    @discardableResult
    static func resume(sessionID: String) async -> TimeInterval? {
        var frozenElapsed: TimeInterval?
        await update(sessionID: sessionID) { activity in
            var state = activity.content.state
            guard state.isPaused else {
                frozenElapsed = SunSessionLiveActivityMetrics.elapsedSeconds(state: state)
                return state
            }

            frozenElapsed = state.elapsedOffsetSeconds
            let metrics = metricsSnapshot(
                attributes: activity.attributes,
                elapsedSeconds: state.elapsedOffsetSeconds
            )

            state.isPaused = false
            state.runningSince = .now
            state.estimatedIU = metrics.estimatedIU
            state.goalProgress = metrics.goalProgress
            return state
        }
        return frozenElapsed
    }

    static func frozenElapsed(sessionID: String) async -> TimeInterval? {
        for activity in Activity<SunSessionActivityAttributes>.activities where activity.attributes.sessionID == sessionID {
            return SunSessionLiveActivityMetrics.elapsedSeconds(state: activity.content.state)
        }
        return ActiveSunSessionStore.load()?.currentElapsed()
    }

    static func end(sessionID: String) async {
        for activity in Activity<SunSessionActivityAttributes>.activities where activity.attributes.sessionID == sessionID {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    private static func metricsSnapshot(
        attributes: SunSessionActivityAttributes,
        elapsedSeconds: TimeInterval
    ) -> (estimatedIU: Double, goalProgress: Double) {
        let estimatedIU = SunSessionLiveActivityMetrics.estimatedIU(
            elapsedSeconds: elapsedSeconds,
            iuPerMinute: attributes.iuPerMinute
        )
        let goalProgress = SunSessionLiveActivityMetrics.goalProgress(
            estimatedIU: estimatedIU,
            targetIU: attributes.targetIU
        )
        return (estimatedIU, goalProgress)
    }

    private static func update(
        sessionID: String,
        transform: (Activity<SunSessionActivityAttributes>) -> SunSessionActivityAttributes.ContentState
    ) async {
        for activity in Activity<SunSessionActivityAttributes>.activities where activity.attributes.sessionID == sessionID {
            let next = transform(activity)
            await activity.update(ActivityContent(state: next, staleDate: nil))
        }
    }
}

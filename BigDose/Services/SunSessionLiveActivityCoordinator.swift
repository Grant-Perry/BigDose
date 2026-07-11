import ActivityKit
import Foundation

/// Owns the single live activity for the active sun session.
@MainActor
final class SunSessionLiveActivityCoordinator {
    static let shared = SunSessionLiveActivityCoordinator()

    static let optInStorageKey = "sunSessionLiveActivityOptIn"

    static func registerDefaultPreferences() {
        UserDefaults.standard.register(defaults: [optInStorageKey: true])
    }

    static var isOptedIn: Bool {
        get { UserDefaults.standard.bool(forKey: optInStorageKey) }
        set { UserDefaults.standard.set(newValue, forKey: optInStorageKey) }
    }

    private var activity: Activity<SunSessionActivityAttributes>?
    private var lastPushedContentState: SunSessionActivityAttributes.ContentState?
    private var pendingUpdateTask: Task<Void, Never>?
    private var pendingContentState: SunSessionActivityAttributes.ContentState?
    private var reconcileTask: Task<Void, Never>?

    private init() {}

    /// Call on each timer tick, pause/resume, or when the session ends.
    func sync(plan: SunSessionPlan?, elapsedSeconds: TimeInterval, isPaused: Bool, optedIn: Bool) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            Task { await endIfNeeded() }
            return
        }

        guard optedIn, let plan else {
            Task { await endIfNeeded() }
            return
        }

        let sessionID = plan.liveActivitySessionID
        if SunSessionLiveActivityCommandStore.hasPendingEnd(for: sessionID) {
            Task { await endIfNeeded() }
            return
        }

        let attributes = plan.liveActivityAttributes()
        let state = plan.liveActivityContentState(elapsedSeconds: elapsedSeconds, isPaused: isPaused)

        let previous = reconcileTask
        reconcileTask = Task { @MainActor [weak self] in
            _ = await previous?.value
            guard let self else { return }
            await self.reconcileSingleton(with: attributes, state: state)
        }
    }

    func endIfNeeded() async {
        cancelPendingUpdate()
        reconcileTask?.cancel()
        reconcileTask = nil

        for activity in Activity<SunSessionActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }

        self.activity = nil
        lastPushedContentState = nil
    }

    private func reconcileSingleton(
        with attributes: SunSessionActivityAttributes,
        state: SunSessionActivityAttributes.ContentState
    ) async {
        await endLiveActivities(notMatchingSessionID: attributes.sessionID)
        await dedupeLiveActivities(forSessionID: attributes.sessionID)

        if let existing = Activity<SunSessionActivityAttributes>.activities.first(where: {
            $0.attributes.sessionID == attributes.sessionID
        }) {
            if existing.attributes != attributes {
                await existing.end(nil, dismissalPolicy: .immediate)
                activity = nil
                lastPushedContentState = nil
                await start(attributes: attributes, state: state)
                return
            }

            activity = existing
            scheduleDebouncedUpdate(state: state)
            return
        }

        activity = nil
        lastPushedContentState = nil
        await start(attributes: attributes, state: state)
    }

    private func endLiveActivities(notMatchingSessionID sessionID: String) async {
        for activity in Activity<SunSessionActivityAttributes>.activities where activity.attributes.sessionID != sessionID {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    private func dedupeLiveActivities(forSessionID sessionID: String) async {
        let matches = Activity<SunSessionActivityAttributes>.activities.filter { $0.attributes.sessionID == sessionID }
        guard matches.count > 1 else { return }

        for extra in matches.dropFirst() {
            await extra.end(nil, dismissalPolicy: .immediate)
        }
    }

    private func scheduleDebouncedUpdate(state: SunSessionActivityAttributes.ContentState) {
        guard let activity else { return }

        var mergedState = state
        mergedState.pendingControl = activity.content.state.pendingControl

        if activity.content.state == mergedState { return }
        if let last = lastPushedContentState, last == mergedState { return }

        pendingContentState = nil
        pendingUpdateTask?.cancel()
        pendingUpdateTask = nil

        pendingUpdateTask = Task { @MainActor [weak self] in
            defer { self?.pendingUpdateTask = nil }
            guard let self else { return }
            guard !Task.isCancelled else { return }

            await activity.update(ActivityContent(state: mergedState, staleDate: nil))
            guard !Task.isCancelled else { return }
            self.lastPushedContentState = mergedState
        }
    }

    private func start(
        attributes: SunSessionActivityAttributes,
        state: SunSessionActivityAttributes.ContentState
    ) async {
        cancelPendingUpdate()

        // Don't resurrect a Live Activity after cleanup cleared the App Group store.
        guard let record = ActiveSunSessionStore.load(),
              record.sessionID == attributes.sessionID else {
            return
        }

        let content = ActivityContent(state: state, staleDate: nil)

        do {
            activity = try Activity.request(attributes: attributes, content: content, pushType: nil)
            lastPushedContentState = state
        } catch {
            activity = nil
            lastPushedContentState = nil
        }
    }

    private func cancelPendingUpdate() {
        pendingUpdateTask?.cancel()
        pendingUpdateTask = nil
        pendingContentState = nil
    }
}

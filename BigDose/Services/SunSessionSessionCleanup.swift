import Foundation

@MainActor
enum SunSessionSessionCleanup {
    static func finishSession(clearPendingCommandFor sessionID: String? = nil) {
        ActiveSunSessionPersistence.clear()
        SessionSafetyNotificationService.cancelSessionNotifications()
        ActiveSessionReminderService.cancel()

        if let sessionID {
            SunSessionLiveActivityCommandStore.clearPending(for: sessionID)
        }

        BigDoseWidgetActiveSessionUpdater.clearActiveSession()

        Task {
            await SunSessionLiveActivityCoordinator.shared.endIfNeeded()
        }
    }
}

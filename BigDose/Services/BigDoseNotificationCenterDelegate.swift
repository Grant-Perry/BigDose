import Foundation
import UIKit
import UserNotifications

final class BigDoseNotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
    // Main-actor isolated so UIKit's completion (which drives snapshot/state
    // restoration) resumes on the main thread. Completing these async delegate
    // methods on a background executor crashes in
    // -[UIApplication _performBlockAfterCATransactionCommitSynchronizes:].
    @MainActor
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        guard Self.shouldDeliver(notification.request.identifier) else {
            return []
        }

        let kind = Self.feedbackKind(for: notification.request.identifier)
        BigDoseAlertFeedback.present(kind: kind)
        return [.banner, .list, .sound, .badge]
    }

    @MainActor
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard Self.shouldDeliver(response.notification.request.identifier) else {
            return
        }

        let identifier = response.notification.request.identifier
        if identifier == ActiveSessionReminderService.identifier,
           let record = ActiveSunSessionStore.load() {
            NotificationCenter.default.post(
                name: .bigDoseOpenSessionFromLiveActivity,
                object: record.sessionID
            )
        }

        let kind = Self.feedbackKind(for: identifier)
        BigDoseAlertFeedback.present(kind: kind)
    }

    nonisolated private static func shouldDeliver(_ identifier: String) -> Bool {
        guard identifier.hasPrefix("bigdose.session.") else { return true }
        return ActiveSunSessionStore.load() != nil
    }

    nonisolated private static func feedbackKind(for identifier: String) -> BigDoseAlertFeedback.Kind {
        if identifier.contains("overLimit") || identifier.contains("stop") || identifier.contains("levelTrend") {
            return .critical
        }

        if identifier.contains("stillActive") {
            return .warning
        }

        if identifier.contains("medWarning") || identifier.contains("turnOver") || identifier.contains("prepareExit") || identifier.contains("risk") {
            return .warning
        }

        return .informational
    }
}

enum BigDoseNotifications {
    private static let delegate = BigDoseNotificationCenterDelegate()

    static func configure() {
        UNUserNotificationCenter.current().delegate = delegate
        UIApplication.shared.registerForRemoteNotifications()
        SessionSafetyNotificationService.cancelOrphanedSessionNotificationsIfNeeded()
    }
}

import Foundation
import UIKit
import UserNotifications

final class BigDoseNotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        guard Self.shouldDeliver(notification.request.identifier) else {
            return []
        }

        let kind = Self.feedbackKind(for: notification.request.identifier)
        await MainActor.run {
            BigDoseAlertFeedback.present(kind: kind)
        }
        return [.banner, .list, .sound, .badge]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard Self.shouldDeliver(response.notification.request.identifier) else {
            return
        }

        let kind = Self.feedbackKind(for: response.notification.request.identifier)
        await MainActor.run {
            BigDoseAlertFeedback.present(kind: kind)
        }
    }

    nonisolated private static func shouldDeliver(_ identifier: String) -> Bool {
        guard identifier.hasPrefix("bigdose.session.") else { return true }
        return ActiveSunSessionStore.load() != nil
    }

    nonisolated private static func feedbackKind(for identifier: String) -> BigDoseAlertFeedback.Kind {
        if identifier.contains("stop") || identifier.contains("levelTrend") {
            return .critical
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

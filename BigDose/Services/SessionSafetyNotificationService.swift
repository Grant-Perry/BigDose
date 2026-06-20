import Foundation
import UserNotifications

enum SessionSafetyNotificationService {
    static let turnOverIdentifier = "bigdose.session.turnOver"
    static let medWarningIdentifier = "bigdose.session.medWarning"
    static let prepareExitIdentifier = "bigdose.session.prepareExit"
    static let stopIdentifier = "bigdose.session.stop"

    private static var sessionIdentifiers: [String] {
        [turnOverIdentifier, medWarningIdentifier, prepareExitIdentifier, stopIdentifier]
    }

    static func schedule(for plan: SunSessionPlan, enabled: Bool) async {
        guard enabled else {
            cancelSessionNotifications()
            return
        }

        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else { return }

            center.removePendingNotificationRequests(withIdentifiers: sessionIdentifiers)

            let skin = plan.skinType.title

            await schedule(
                identifier: turnOverIdentifier,
                title: "Turn over",
                body: "About 50% of your estimated MED for \(skin) skin — flip sides or rotate exposure.",
                seconds: plan.turnOverAlertSeconds
            )

            await schedule(
                identifier: medWarningIdentifier,
                title: "Approaching exposure limit",
                body: "About 75% of your estimated MED for \(skin) skin at this UV. Consider wrapping up soon.",
                seconds: plan.medWarningSeconds
            )

            let exitCountdown = plan.prepareExitCountdownText
            await schedule(
                identifier: prepareExitIdentifier,
                title: "Get ready to exit sun",
                body: "Past 75% of MED — start heading inside. Recommended stop in \(exitCountdown).",
                seconds: plan.prepareExitAlertSeconds
            )

            await schedule(
                identifier: stopIdentifier,
                title: "Time to stop",
                body: "About 90% of your estimated MED for \(skin) skin. End this session or get covered.",
                seconds: plan.stopAlertSeconds
            )
        } catch {
            return
        }
    }

    static func cancelSessionNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: sessionIdentifiers)
    }

    static func cancelOrphanedSessionNotificationsIfNeeded() {
        guard ActiveSunSessionStore.load() == nil else { return }
        cancelSessionNotifications()
    }

    static func cancelTurnOverNotification() {
        cancel(identifier: turnOverIdentifier)
    }

    static func cancelMedWarningNotification() {
        cancel(identifier: medWarningIdentifier)
    }

    static func cancelPrepareExitNotification() {
        cancel(identifier: prepareExitIdentifier)
    }

    static func cancelStopNotification() {
        cancel(identifier: stopIdentifier)
    }

    private static func cancel(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    private static func schedule(identifier: String, title: String, body: String, seconds: TimeInterval) async {
        guard seconds > 1 else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try? await UNUserNotificationCenter.current().add(request)
    }
}

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

            await schedule(
                identifier: turnOverIdentifier,
                title: "Turn over",
                body: "You have reached the turn-over point for this sun session.",
                seconds: plan.turnOverAlertSeconds
            )

            await schedule(
                identifier: medWarningIdentifier,
                title: "Approaching exposure limit",
                body: "You are around 75% of the estimated MED window for your skin type and current UV.",
                seconds: plan.medWarningSeconds
            )

            let exitCountdown = plan.prepareExitCountdownText
            await schedule(
                identifier: prepareExitIdentifier,
                title: "Get ready to exit sun",
                body: "Start packing up — you're approaching your exit in \(exitCountdown).",
                seconds: plan.prepareExitAlertSeconds
            )

            await schedule(
                identifier: stopIdentifier,
                title: "Time to stop",
                body: "You are approaching your skin-type exposure limit. End this session or get covered.",
                seconds: plan.stopAlertSeconds
            )
        } catch {
            return
        }
    }

    static func cancelSessionNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: sessionIdentifiers)
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

import Foundation
import UserNotifications

enum SessionSafetyNotificationService {
    private static let turnOverIdentifier = "bigdose.session.turnOver"
    private static let stopIdentifier = "bigdose.session.stop"

    static func schedule(for plan: SunSessionPlan) async {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            guard granted else { return }

            center.removePendingNotificationRequests(withIdentifiers: [turnOverIdentifier, stopIdentifier])

            await schedule(
                identifier: turnOverIdentifier,
                title: "Turn over",
                body: "You have reached the turn-over point for this sun session.",
                seconds: plan.turnOverAlertSeconds
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
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [turnOverIdentifier, stopIdentifier])
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

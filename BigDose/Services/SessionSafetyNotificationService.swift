import Foundation
import UserNotifications

enum SessionSafetyNotificationService {
    static let turnOverIdentifier = "bigdose.session.turnOver"
    static let medWarningIdentifier = "bigdose.session.medWarning"
    static let prepareExitIdentifier = "bigdose.session.prepareExit"

    private static func overLimitIdentifier(for percent: Int) -> String {
        "bigdose.session.overLimit.\(percent)"
    }

    private static var overLimitPercents: [Int] {
        [
            SunSessionSafetyThresholds.guidanceLimitPercent,
            SunSessionSafetyThresholds.nannyReminderPercent,
            SunSessionSafetyThresholds.fullMEDPercent
        ]
    }

    private static var sessionIdentifiers: [String] {
        var identifiers = [turnOverIdentifier, medWarningIdentifier, prepareExitIdentifier]
        identifiers.append(contentsOf: overLimitPercents.map(overLimitIdentifier(for:)))
        return identifiers
    }

    static func schedule(
        for plan: SunSessionPlan,
        enabled: Bool,
        wantsNannyMode: Bool = true,
        elapsedSeconds: TimeInterval = 0
    ) async {
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
                body: "About 50% of your estimated MED (burn risk) for \(skin) skin — flip sides or rotate exposure.",
                seconds: remainingSeconds(until: plan.turnOverAlertSeconds, elapsedSeconds: elapsedSeconds)
            )

            await schedule(
                identifier: medWarningIdentifier,
                title: "Approaching exposure limit",
                body: "About 75% of your estimated MED (burn risk) for \(skin) skin at this UV. Consider wrapping up soon.",
                seconds: remainingSeconds(until: plan.medWarningSeconds, elapsedSeconds: elapsedSeconds)
            )

            if wantsNannyMode {
                let exitCountdown = plan.prepareExitCountdownText
                await schedule(
                    identifier: prepareExitIdentifier,
                    title: "Get ready to exit sun",
                    body: "Past 75% of MED (burn risk) — start heading inside. Guidance limit in \(exitCountdown).",
                    seconds: remainingSeconds(until: plan.prepareExitAlertSeconds, elapsedSeconds: elapsedSeconds)
                )

                for percent in overLimitPercents {
                    await schedule(
                        identifier: overLimitIdentifier(for: percent),
                        title: overLimitNotificationTitle(for: percent),
                        body: plan.overLimitAlertMessage(for: percent),
                        seconds: remainingSeconds(
                            until: plan.secondsToReachMedPercent(percent),
                            elapsedSeconds: elapsedSeconds
                        )
                    )
                }
            }
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
        ActiveSessionReminderService.cancel()
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

    static func cancelOverLimitNotification(for percent: Int) {
        cancel(identifier: overLimitIdentifier(for: percent))
    }

    private static func overLimitNotificationTitle(for percent: Int) -> String {
        if percent == SunSessionSafetyThresholds.guidanceLimitPercent {
            "Past guidance limit"
        } else if percent == SunSessionSafetyThresholds.nannyReminderPercent {
            "Still in the sun — 98% MED (burn risk)"
        } else if percent == SunSessionSafetyThresholds.fullMEDPercent {
            "100% MED (burn risk) — stop now"
        } else {
            "Still in the sun — \(percent)% MED (burn risk)"
        }
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

    private static func remainingSeconds(until thresholdSeconds: TimeInterval, elapsedSeconds: TimeInterval) -> TimeInterval {
        thresholdSeconds - elapsedSeconds
    }

    private static func cancel(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}

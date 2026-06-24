import Foundation
import UserNotifications

enum ActiveSessionReminderService {
    static let identifier = "bigdose.session.stillActive"
    static let gracePeriodSeconds: TimeInterval = 15 * 60
    static let followUpIntervalSeconds: TimeInterval = 30 * 60

    static func schedule(
        for plan: SunSessionPlan,
        elapsedSeconds: TimeInterval,
        isPaused: Bool,
        enabled: Bool
    ) async {
        guard enabled else {
            cancel()
            return
        }

        guard !isPaused else {
            cancel()
            return
        }

        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else { return }

            center.removePendingNotificationRequests(withIdentifiers: [identifier])

            guard let seconds = nextReminderSeconds(
                for: plan,
                elapsedSeconds: elapsedSeconds
            ) else {
                return
            }

            let durationLabel = SunSessionDurationFormatting.compact(elapsedSeconds)
            let content = UNMutableNotificationContent()
            content.title = "Sun session still running"
            content.body = "BigDose has tracked \(durationLabel) so far. Still outside, or stop and save?"
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            try await center.add(request)
        } catch {
            return
        }
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    static func isStale(
        for plan: SunSessionPlan,
        elapsedSeconds: TimeInterval,
        isPaused: Bool
    ) -> Bool {
        guard !isPaused, elapsedSeconds > 0 else { return false }

        if elapsedSeconds >= plan.safeMaxDurationSeconds + gracePeriodSeconds {
            return true
        }

        guard plan.hasReachedGoal(at: elapsedSeconds) else { return false }
        return elapsedSeconds >= plan.goalDurationSeconds + gracePeriodSeconds
    }

    static func staleSessionMessage(
        for plan: SunSessionPlan,
        elapsedSeconds: TimeInterval
    ) -> String {
        let duration = SunSessionDurationFormatting.compact(elapsedSeconds)
        let iu = Int(plan.estimatedIU(at: elapsedSeconds).rounded())
        let med = plan.medUsedPercent(at: elapsedSeconds)

        if plan.hasReachedGoal(at: elapsedSeconds) {
            return "This session has run \(duration) and logged about \(iu) IU at \(med)% MED (burn risk) used. Still outside, or stop and save?"
        }

        return "This session has run \(duration) — past your safe max window — and is at \(med)% MED (burn risk) used. Stop and save, or keep going if you're still out."
    }

    static func nextReminderSeconds(
        for plan: SunSessionPlan,
        elapsedSeconds: TimeInterval
    ) -> TimeInterval? {
        let triggers = staleTriggerElapsedSeconds(for: plan)
        guard let firstTrigger = triggers.min() else { return nil }

        if elapsedSeconds >= firstTrigger {
            return followUpIntervalSeconds
        }

        return max(1, firstTrigger - elapsedSeconds)
    }

    private static func staleTriggerElapsedSeconds(for plan: SunSessionPlan) -> [TimeInterval] {
        var triggers = [plan.safeMaxDurationSeconds + gracePeriodSeconds]

        if plan.targetIU > 0, plan.liveIUProductionRatePerMinute > 0 {
            triggers.append(plan.goalDurationSeconds + gracePeriodSeconds)
        }

        return triggers
    }
}

enum SunSessionDurationFormatting {
    static func compact(_ seconds: TimeInterval) -> String {
        let totalMinutes = max(0, Int(seconds.rounded()) / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }

        return "\(max(totalMinutes, 1))m"
    }

    static func timer(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainder = Int(seconds) % 60
        return "\(minutes):\(String(format: "%02d", remainder))"
    }
}

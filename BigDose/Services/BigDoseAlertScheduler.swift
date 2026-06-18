import Foundation
import UserNotifications

enum BigDoseAlertScheduler {
    private static let managedPrefix = "bigdose.alert."

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    static func reschedule(profile: UserProfile, dailyPlan: DailySunPlan?, progress: BigDoseProgressSnapshot?) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let managedIDs = pending.map(\.identifier).filter { $0.hasPrefix(managedPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: managedIDs)

        guard await requestAuthorization() else {
            return
        }

        if profile.wantsSolarWindowAlerts, let start = dailyPlan?.nextUsefulStart, !isInQuietHours(start, profile: profile) {
            await scheduleCalendar(
                id: "solarWindow",
                title: "Useful sunlight is coming up",
                body: "BigDose found a sunlight window that matches your profile.",
                date: start
            )
        }

        if profile.wantsSupplementReminders {
            await scheduleDaily(
                id: "supplement",
                title: "Log your vitamin D",
                body: "Record your supplement dose so today’s progress stays accurate.",
                hour: profile.supplementReminderHour,
                minute: profile.supplementReminderMinute
            )
        }

        if profile.wantsLabReminders {
            let date = Calendar.current.date(byAdding: .day, value: profile.labReminderIntervalDays, to: .now) ?? .now
            await scheduleCalendar(
                id: "labReminder",
                title: "Consider a vitamin D lab check",
                body: "A 25(OH)D result keeps BigDose estimates anchored.",
                date: date
            )
        }

        if profile.wantsWeeklyProgressAlerts {
            await scheduleWeeklyProgress()
        }

        if profile.wantsLevelTrendAlerts, let progress, progress.estimatedLevel < profile.goalNanogramsPerMilliliter * 0.7 {
            await scheduleCalendar(
                id: "levelTrend",
                title: "Your estimate is below target",
                body: "Review recent sunlight, supplements, and lab data in BigDose.",
                date: Calendar.current.date(byAdding: .hour, value: 2, to: .now) ?? .now
            )
        }
    }

    static func cancelAllManagedAlerts() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = requests.map(\.identifier).filter { $0.hasPrefix(managedPrefix) }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    private static func scheduleCalendar(id: String, title: String, body: String, date: Date) async {
        guard date > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: managedPrefix + id, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    private static func scheduleDaily(id: String, title: String, body: String, hour: Int, minute: Int) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: managedPrefix + id, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    private static func scheduleWeeklyProgress() async {
        let content = UNMutableNotificationContent()
        content.title = "Weekly BigDose check-in"
        content.body = "See how sunlight, supplements, and labs are tracking against your goal."
        content.sound = .default

        var components = DateComponents()
        components.weekday = 1
        components.hour = 18
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: managedPrefix + "weekly", content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    private static func isInQuietHours(_ date: Date, profile: UserProfile) -> Bool {
        guard profile.quietHoursEnabled else { return false }

        let hour = Calendar.current.component(.hour, from: date)
        if profile.quietHoursStartHour < profile.quietHoursEndHour {
            return hour >= profile.quietHoursStartHour && hour < profile.quietHoursEndHour
        }

        return hour >= profile.quietHoursStartHour || hour < profile.quietHoursEndHour
    }
}

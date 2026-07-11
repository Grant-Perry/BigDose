import Foundation
import UserNotifications

enum BigDoseAlertScheduler {
    private static let managedPrefix = "bigdose.alert."
    private static let eventOffset: TimeInterval = 15 * 60
    @MainActor private static var rescheduleGeneration = 0

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func reschedule(
        profile: UserProfile,
        dailyPlan: DailySunPlan?,
        progress: BigDoseProgressSnapshot?,
        latestLabMeasuredAt: Date? = nil
    ) async {
        await MainActor.run { rescheduleGeneration += 1 }
        let generation = await MainActor.run { rescheduleGeneration }

        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let managedIDs = pending.map(\.identifier).filter { $0.hasPrefix(managedPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: managedIDs)

        guard await requestAuthorization() else {
            return
        }
        guard await MainActor.run(body: { generation == rescheduleGeneration }) else { return }

        if let dailyPlan {
            await scheduleSolarEventAlerts(profile: profile, dailyPlan: dailyPlan)
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
            let anchor = latestLabMeasuredAt ?? profile.updatedAt
            let candidate = Calendar.current.date(
                byAdding: .day,
                value: profile.labReminderIntervalDays,
                to: anchor
            ) ?? .now
            // If the cadence is already overdue, nudge tomorrow instead of forever postponing.
            let date = candidate > .now
                ? candidate
                : (Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now.addingTimeInterval(86_400))
            await scheduleCalendar(
                id: "labReminder",
                title: "Consider a vitamin D lab check",
                body: "A 25(OH)D result keeps BigDose estimates anchored.",
                date: date
            )
        }

        guard await MainActor.run(body: { generation == rescheduleGeneration }) else { return }

        if profile.wantsWeeklyProgressAlerts {
            await scheduleWeeklyProgress()
        }

        if profile.wantsLevelTrendAlerts, let progress, progress.estimatedLevel < profile.goalNanogramsPerMilliliter * 0.7 {
            await scheduleCalendar(
                id: "levelTrend",
                title: "Your estimate is below target",
                body: "Review recent sunlight, supplements and lab data in BigDose.",
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

    private static func scheduleSolarEventAlerts(profile: UserProfile, dailyPlan: DailySunPlan) async {
        let events = SolarEventScheduleContext.make(from: dailyPlan)
        let nextOpportunityDuplicatesOpening = events.nextDOpportunityStart.map { next in
            guard let opening = events.dWindowOpening else { return false }
            return abs(next.timeIntervalSince(opening)) < 60
        } ?? false

        if profile.wantsDWindowOpeningAlerts, let opening = events.dWindowOpening {
            await scheduleBeforeAfter(
                idPrefix: "dWindow.opening",
                beforeTitle: "D window opens soon",
                beforeBody: "Your vitamin D window opens in 15 minutes.",
                afterTitle: "D window just opened",
                afterBody: "The sun is high enough for meaningful vitamin D production.",
                eventDate: opening,
                profile: profile
            )
        }

        if profile.wantsDWindowClosingAlerts, let closing = events.dWindowClosing {
            await scheduleBeforeAfter(
                idPrefix: "dWindow.closing",
                beforeTitle: "D window closing soon",
                beforeBody: "Your vitamin D window closes in 15 minutes.",
                afterTitle: "D window just closed",
                afterBody: "Today's vitamin D window has ended.",
                eventDate: closing,
                profile: profile
            )
        }

        if profile.wantsSolarNoonAlerts, let solarNoon = events.solarNoon {
            await scheduleBeforeAfter(
                idPrefix: "solarNoon",
                beforeTitle: "Solar noon approaching",
                beforeBody: "The sun reaches its highest point in 15 minutes.",
                afterTitle: "Solar noon",
                afterBody: "The sun is at its highest point for today.",
                eventDate: solarNoon,
                profile: profile
            )
        }

        if profile.wantsSunriseSunsetAlerts {
            if let sunrise = events.sunrise {
                await scheduleBeforeAfter(
                    idPrefix: "sunrise",
                    beforeTitle: "Sunrise soon",
                    beforeBody: "The sun rises in 15 minutes.",
                    afterTitle: "Sunrise",
                    afterBody: "The sun is up.",
                    eventDate: sunrise,
                    profile: profile
                )
            }

            if let sunset = events.sunset {
                await scheduleBeforeAfter(
                    idPrefix: "sunset",
                    beforeTitle: "Sunset soon",
                    beforeBody: "The sun sets in 15 minutes.",
                    afterTitle: "Sunset",
                    afterBody: "The sun has set.",
                    eventDate: sunset,
                    profile: profile
                )
            }
        }

        if profile.wantsAMLightWindowAlerts {
            if let amLightStart = events.amLightWindowStart {
                await scheduleBeforeAfter(
                    idPrefix: "amLight.opening",
                    beforeTitle: "AM light window soon",
                    beforeBody: "Low-angle morning sunlight — safe to look at — begins in 15 minutes.",
                    afterTitle: "AM light window open",
                    afterBody: "Morning sun is between 1°–3° — gentle light that's safe to look at.",
                    eventDate: amLightStart,
                    profile: profile
                )
            }

            if let amLightEnd = events.amLightWindowEnd {
                await scheduleBeforeAfter(
                    idPrefix: "amLight.closing",
                    beforeTitle: "AM light window ending soon",
                    beforeBody: "The low-angle morning window ends in 15 minutes.",
                    afterTitle: "AM light window ended",
                    afterBody: "Morning light is no longer at the low, eye-safe angle.",
                    eventDate: amLightEnd,
                    profile: profile
                )
            }
        }

        if profile.wantsNextDOpportunityAlerts,
           !nextOpportunityDuplicatesOpening || !profile.wantsDWindowOpeningAlerts,
           let nextOpportunity = events.nextDOpportunityStart {
            await scheduleBeforeAfter(
                idPrefix: "nextDOpportunity",
                beforeTitle: "D window opportunity soon",
                beforeBody: "Your next vitamin D window opens in 15 minutes.",
                afterTitle: "D window opportunity",
                afterBody: "Your next vitamin D window is opening now.",
                eventDate: nextOpportunity,
                profile: profile
            )
        }
    }

    private static func scheduleBeforeAfter(
        idPrefix: String,
        beforeTitle: String,
        beforeBody: String,
        afterTitle: String,
        afterBody: String,
        eventDate: Date,
        profile: UserProfile
    ) async {
        let beforeDate = eventDate.addingTimeInterval(-eventOffset)
        let suffix = dateIdentifier(for: eventDate)

        if beforeDate > .now, !isInQuietHours(beforeDate, profile: profile) {
            await scheduleCalendar(
                id: "\(idPrefix).before.\(suffix)",
                title: beforeTitle,
                body: beforeBody,
                date: beforeDate
            )
        }

        if eventDate > .now, !isInQuietHours(eventDate, profile: profile) {
            await scheduleCalendar(
                id: "\(idPrefix).at.\(suffix)",
                title: afterTitle,
                body: afterBody,
                date: eventDate
            )
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
        content.body = "See how sunlight, supplements and labs are tracking against your goal."
        content.sound = .default

        var components = DateComponents()
        components.weekday = 1
        components.hour = 18
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: managedPrefix + "weekly", content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    private static func dateIdentifier(for date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        return String(format: "%04d%02d%02d%02d%02d", year, month, day, hour, minute)
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

private struct SolarEventScheduleContext {
    var dWindowOpening: Date?
    var dWindowClosing: Date?
    var solarNoon: Date?
    var sunrise: Date?
    var sunset: Date?
    var amLightWindowStart: Date?
    var amLightWindowEnd: Date?
    var nextDOpportunityStart: Date?

    static func make(from plan: DailySunPlan, now: Date = .now) -> SolarEventScheduleContext {
        let display = DailySunPlanService.vitaminDWindowDisplay(for: plan, now: now)
        let snapshot = display.snapshot
        let referenceDay = snapshot.referenceDay
        // Only alert for a future opening — never while today's window is already open.
        let nextOpportunity: Date? = if display.isWindowOpenNow {
            nil
        } else if let start = display.nextOpportunityStart, start > now {
            start
        } else {
            nil
        }
        let amLight = SolarGeometryService.amLightWindow(
            latitude: plan.latitude,
            longitude: plan.longitude,
            date: referenceDay
        )

        return SolarEventScheduleContext(
            dWindowOpening: snapshot.windowStart,
            dWindowClosing: snapshot.windowEnd,
            solarNoon: snapshot.solarNoon,
            sunrise: snapshot.sunrise,
            sunset: snapshot.sunset,
            amLightWindowStart: amLight.start,
            amLightWindowEnd: amLight.end,
            nextDOpportunityStart: nextOpportunity
        )
    }
}

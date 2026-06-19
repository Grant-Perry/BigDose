import Foundation

struct VitaminDWindowSnapshot: Equatable {
    var referenceDay: Date
    var sunrise: Date?
    var sunset: Date?
    var solarNoon: Date
    var solarNoonAltitudeDegrees: Double
    var windowStart: Date?
    var windowEnd: Date?
    var thresholdDegrees: Double

    var duration: TimeInterval? {
        guard let windowStart, let windowEnd else { return nil }
        return max(windowEnd.timeIntervalSince(windowStart), 0)
    }

    var durationLabel: String? {
        guard let duration else { return nil }
        return Self.formattedDuration(duration)
    }

    func remainingDuration(from now: Date = .now) -> TimeInterval? {
        guard let windowEnd else { return nil }

        if let windowStart, now < windowStart {
            return max(windowEnd.timeIntervalSince(windowStart), 0)
        }

        guard now <= windowEnd else { return nil }
        return max(windowEnd.timeIntervalSince(now), 0)
    }

    func remainingDurationLabel(now: Date) -> String? {
        guard let remainingDuration = remainingDuration(from: now) else { return nil }
        return Self.formattedDuration(remainingDuration)
    }

    static func formattedDuration(_ duration: TimeInterval) -> String {
        let totalMinutes = Int(duration.rounded(.down) / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0, minutes > 0 {
            return "\(hours)h \(minutes)m"
        }

        if hours > 0 {
            return "\(hours)h"
        }

        return "\(minutes)m"
    }

    var hasWindow: Bool {
        windowStart != nil && windowEnd != nil
    }
}

struct VitaminDWindowDisplay: Equatable {
    var snapshot: VitaminDWindowSnapshot
    var isToday: Bool
    var nextOpportunityStart: Date?
    var nextOpportunityTiming: BestSunlightHighlight.Timing

    var isWindowOpenNow: Bool {
        isToday && nextOpportunityStart == nil && snapshot.hasWindow
    }

    var dayLabel: String {
        isToday ? "Today" : "Tomorrow"
    }

    var cardTitle: String {
        isToday ? "Vitamin D Window Today" : "Vitamin D Window Tomorrow"
    }

    var bannerTitleLead: String {
        "Vitamin D window is..."
    }

    var bannerTitleDetail: String {
        if isWindowOpenNow {
            return "Open Now"
        }

        guard let nextOpportunityStart else {
            return isToday ? "Open Now" : "Unavailable Tomorrow"
        }

        return VitaminDWindowHeadline.scheduledOpeningTitle(nextOpening: nextOpportunityStart)
    }

    var bannerTitle: String {
        "\(bannerTitleLead) \(bannerTitleDetail)"
    }

    var nextWindowTitle: String {
        VitaminDWindowHeadline.nextWindowTitle(
            isOpenNow: isWindowOpenNow,
            nextOpening: nextOpportunityStart ?? (isToday ? nil : snapshot.windowStart)
        )
    }

    var bannerEyebrow: String {
        if isWindowOpenNow {
            return "D Window Open"
        }

        guard nextOpportunityStart != nil else {
            return isToday ? "D Window Open" : "Tomorrow's Plan"
        }

        switch nextOpportunityTiming {
        case .today:
            return "Up Next"
        case .tomorrow:
            return "Tomorrow's Window"
        }
    }

    func remainingWindowDurationLabel(at now: Date) -> String? {
        guard isWindowOpenNow else { return nil }
        return snapshot.remainingDurationLabel(now: now)
    }
}

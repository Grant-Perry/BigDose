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

    var dayLabel: String {
        isToday ? "Today" : "Tomorrow"
    }

    var cardTitle: String {
        isToday ? "Vitamin D Window Today" : "Vitamin D Window Tomorrow"
    }

    var bannerTitle: String {
        guard let nextOpportunityStart else {
            return isToday ? "Vitamin D window is open now" : "No vitamin D window tomorrow"
        }

        let time = nextOpportunityStart.formatted(date: .omitted, time: .shortened)
        switch nextOpportunityTiming {
        case .today:
            return "Next D opportunity is today at \(time)"
        case .tomorrow:
            return "Next D opportunity is tomorrow at \(time)"
        }
    }

    var bannerEyebrow: String {
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
}

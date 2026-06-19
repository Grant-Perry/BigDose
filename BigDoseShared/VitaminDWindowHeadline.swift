import Foundation

/// User-facing copy for when the vitamin D synthesis window is open, upcoming, or tomorrow.
enum VitaminDWindowHeadline {
    static func isWindowOpenNow(
        windowStart: Date?,
        windowEnd: Date?,
        now: Date = .now
    ) -> Bool {
        guard let windowStart, let windowEnd else { return false }
        return now >= windowStart && now <= windowEnd
    }

    /// Compact headline for widgets and “next window” surfaces.
    static func nextWindowTitle(
        isOpenNow: Bool,
        nextOpening: Date?,
        calendar: Calendar = .current
    ) -> String {
        if isOpenNow {
            return "Right Now!"
        }

        guard let nextOpening else {
            return "Vitamin D window unavailable"
        }

        return scheduledOpeningTitle(nextOpening: nextOpening, calendar: calendar)
    }

    static func scheduledOpeningTitle(
        nextOpening: Date,
        calendar: Calendar = .current
    ) -> String {
        if calendar.isDateInTomorrow(nextOpening) || !calendar.isDateInToday(nextOpening) {
            return "Tomorrow at \(formatTime(nextOpening))"
        }

        return "Today at \(formatTime(nextOpening))"
    }

    static func windowRangeSubtitle(start: Date, end: Date) -> String {
        "\(formatTime(start))–\(formatTime(end))"
    }

    static func formatTime(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }
}

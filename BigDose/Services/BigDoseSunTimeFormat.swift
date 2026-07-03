import Foundation

enum BigDoseSunTimeFormat {
    /// Floors to the minute so labels match Apple Weather (avoids rounding 5:49:xx up to 5:50).
    static func label(for date: Date, calendar: Calendar = .current) -> String {
        let floored = calendar.date(
            from: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        ) ?? date
        return floored.formatted(date: .omitted, time: .shortened)
    }

    static func debugDescription(for date: Date?, calendar: Calendar = .current) -> String {
        guard let date else { return "nil" }
        let iso = date.ISO8601Format()
        return "\(label(for: date, calendar: calendar)) (\(iso))"
    }
}

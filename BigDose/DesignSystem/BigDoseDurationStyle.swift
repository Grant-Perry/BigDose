import Foundation

/// Compact hour/minute notation styling — tune unit de-emphasis app-wide from here.
enum BigDoseDurationStyle {
    /// Opacity applied to `h` / `m` unit suffixes so values read first (e.g. **9**h **13**m).
    static var unitOpacity: Double = 0.5

    static var hourSuffix: String = "h"
    static var minuteSuffix: String = "m"
    static var componentSpacing: String = " "
}

struct BigDoseDurationComponents: Equatable, Sendable {
    var hours: Int
    var minutes: Int

    init(hours: Int = 0, minutes: Int = 0) {
        self.hours = max(hours, 0)
        self.minutes = max(minutes, 0)
    }

    init(duration: TimeInterval) {
        let totalMinutes = Int(duration.rounded(.down) / 60)
        self.hours = totalMinutes / 60
        self.minutes = totalMinutes % 60
    }

    /// Plain compact label for accessibility, logging, and non-SwiftUI contexts.
    var compactLabel: String {
        if hours > 0, minutes > 0 {
            return "\(hours)\(BigDoseDurationStyle.hourSuffix)\(BigDoseDurationStyle.componentSpacing)\(minutes)\(BigDoseDurationStyle.minuteSuffix)"
        }

        if hours > 0 {
            return "\(hours)\(BigDoseDurationStyle.hourSuffix)"
        }

        return "\(minutes)\(BigDoseDurationStyle.minuteSuffix)"
    }

    var accessibilityLabel: String {
        if hours > 0, minutes > 0 {
            return "\(hours) hours \(minutes) minutes"
        }

        if hours > 0 {
            return "\(hours) hours"
        }

        return "\(minutes) minutes"
    }
}

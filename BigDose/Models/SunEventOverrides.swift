import Foundation

struct SunEventOverrides: Equatable, Sendable {
    var sunrise: Date?
    var sunset: Date?
    var solarNoon: Date?

    var hasAnyEvent: Bool {
        sunrise != nil || sunset != nil || solarNoon != nil
    }
}

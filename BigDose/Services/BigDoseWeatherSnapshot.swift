import Foundation

struct BigDoseWeatherSnapshot: Equatable {
    var locationName: String
    var temperatureFahrenheit: Double
    var feelsLikeFahrenheit: Double
    var lowTemperatureFahrenheit: Double
    var highTemperatureFahrenheit: Double
    var conditionText: String
    var symbolName: String
    var cloudCover: Double
    var windMilesPerHour: Double
    var humidityPercent: Double
    var dewPointFahrenheit: Double
    var pressureInchesMercury: Double
    var uvIndex: Double
    var observedAt: Date
    var hourlyUV: [HourlyUVSnapshot]
    var hourlyForecast: [BigDoseHourlyForecast]
    var dailyForecast: [BigDoseDailyForecast]
    var attributionText: String
    var attributionURL: URL?
    var combinedMarkLightURL: URL?
    var combinedMarkDarkURL: URL?
    var isLive: Bool
    var todaySunrise: Date?
    var todaySunset: Date?
    var todaySolarNoon: Date?
    var todaySunEvents: SunEventOverrides?

    var sourceTitle: String {
        isLive ? "WeatherKit" : "Unavailable"
    }

    var skyConditionText: String {
        Self.skyConditionLabel(cloudCover: cloudCover)
    }

    var displayConditionSummary: String {
        let primary = conditionText.trimmingCharacters(in: .whitespacesAndNewlines)
        let sky = skyConditionText
        let primaryLower = primary.lowercased()

        if primaryLower.contains("cloud")
            || primaryLower.contains("clear")
            || primaryLower.contains("sun")
            || primaryLower.contains("overcast")
            || primaryLower == sky.lowercased() {
            return primary
        }

        return "\(primary) · \(sky)"
    }

    var nextSixHourlyForecast: [BigDoseHourlyForecast] {
        Array(hourlyForecast.prefix(6))
    }

    var totalRainNextSixHoursInches: Double {
        nextSixHourlyForecast.reduce(0) { $0 + $1.precipitationAmountInches }
    }

    static func skyConditionLabel(cloudCover: Double) -> String {
        switch cloudCover {
        case ..<0.15:
            "Clear"
        case ..<0.45:
            "Partly Cloudy"
        case ..<0.75:
            "Mostly Cloudy"
        default:
            "Cloudy"
        }
    }
}

struct HourlyUVSnapshot: Identifiable, Equatable {
    var id: Date { date }
    var date: Date
    var uvIndex: Double
}

struct BigDoseHourlyForecast: Identifiable, Equatable {
    var id: Date { date }
    var date: Date
    var temperatureFahrenheit: Double
    var symbolName: String
    var conditionText: String
    var precipitationChance: Double
    var precipitationAmountInches: Double
}

struct BigDoseDailyForecast: Identifiable, Equatable {
    var id: Date { date }
    var date: Date
    var highTemperatureFahrenheit: Double
    var lowTemperatureFahrenheit: Double
    var symbolName: String
    var conditionText: String
    var precipitationChance: Double
    var precipitationAmountInches: Double
    var sunrise: Date?
    var sunset: Date?
    var solarNoon: Date?
}

extension BigDoseWeatherSnapshot {
    /// Most reliable WeatherKit sun times for today's diagram — no calendar matching required.
    /// Absolute timestamps from a prior-day cache must not override today's geometry.
    func preferredTodaySunEvents(calendar: Calendar = .current) -> SunEventOverrides? {
        let cached = SunEventOverrides(
            sunrise: Self.eventIfToday(todaySunrise, calendar: calendar),
            sunset: Self.eventIfToday(todaySunset, calendar: calendar),
            solarNoon: Self.eventIfToday(todaySolarNoon, calendar: calendar)
        )
        if cached.hasAnyEvent {
            return cached
        }

        if let todaySunEvents {
            let todayOnly = SunEventOverrides(
                sunrise: Self.eventIfToday(todaySunEvents.sunrise, calendar: calendar),
                sunset: Self.eventIfToday(todaySunEvents.sunset, calendar: calendar),
                solarNoon: Self.eventIfToday(todaySunEvents.solarNoon, calendar: calendar)
            )
            if todayOnly.hasAnyEvent {
                return todayOnly
            }
        }

        if let first = dailyForecast.first {
            if let overrides = Self.overrides(from: first) {
                return overrides
            }
        }

        return nil
    }

    func resolvedSunEvents(on day: Date, calendar: Calendar = .current) -> SunEventOverrides? {
        if calendar.isDateInToday(day), let todayEvents = preferredTodaySunEvents(calendar: calendar) {
            return todayEvents
        }

        if let match = dailyForecast.first(where: { calendar.isDate($0.date, inSameDayAs: day) }) {
            if let overrides = Self.overrides(from: match) {
                return overrides
            }
        }

        let referenceStart = calendar.startOfDay(for: observedAt)
        let targetStart = calendar.startOfDay(for: day)

        if calendar.isDate(day, inSameDayAs: observedAt) {
            if let todayEvents = preferredTodaySunEvents(calendar: calendar) {
                return todayEvents
            }
        }

        if targetStart == referenceStart, let first = dailyForecast.first {
            if let overrides = Self.overrides(from: first) {
                return overrides
            }
        }

        if let nextStart = calendar.date(byAdding: .day, value: 1, to: referenceStart),
           targetStart == nextStart,
           dailyForecast.count > 1 {
            return Self.overrides(from: dailyForecast[1])
        }

        return nil
    }

    func sunEvents(on day: Date, calendar: Calendar = .current) -> SunEventOverrides? {
        resolvedSunEvents(on: day, calendar: calendar)
    }

    private static func overrides(from day: BigDoseDailyForecast?) -> SunEventOverrides? {
        guard let day else { return nil }
        let overrides = SunEventOverrides(
            sunrise: day.sunrise,
            sunset: day.sunset,
            solarNoon: day.solarNoon
        )
        return overrides.hasAnyEvent ? overrides : nil
    }

    private static func eventIfToday(_ date: Date?, calendar: Calendar) -> Date? {
        guard let date, calendar.isDateInToday(date) else { return nil }
        return date
    }
}

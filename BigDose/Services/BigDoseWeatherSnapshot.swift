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
}

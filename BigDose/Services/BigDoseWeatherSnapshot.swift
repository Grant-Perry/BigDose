import Foundation

struct BigDoseWeatherSnapshot: Equatable {
    var locationName: String
    var temperatureFahrenheit: Double
    var feelsLikeFahrenheit: Double
    var lowTemperatureFahrenheit: Double
    var highTemperatureFahrenheit: Double
    var conditionText: String
    var symbolName: String
    var windMilesPerHour: Double
    var humidityPercent: Double
    var dewPointFahrenheit: Double
    var pressureInchesMercury: Double
    var uvIndex: Double
    var observedAt: Date
    var hourlyUV: [HourlyUVSnapshot]
    var attributionText: String
    var attributionURL: URL?
    var combinedMarkLightURL: URL?
    var combinedMarkDarkURL: URL?
    var isLive: Bool

    var sourceTitle: String {
        isLive ? "WeatherKit" : "Unavailable"
    }
}

struct HourlyUVSnapshot: Identifiable, Equatable {
    var id: Date { date }
    var date: Date
    var uvIndex: Double
}


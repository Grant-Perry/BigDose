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
    var isLive: Bool

    var sourceTitle: String {
        isLive ? "WeatherKit" : "Demo"
    }

    static let demo = BigDoseWeatherSnapshot(
        locationName: "Newport News",
        temperatureFahrenheit: 82,
        feelsLikeFahrenheit: 85,
        lowTemperatureFahrenheit: 72,
        highTemperatureFahrenheit: 89,
        conditionText: "Mostly Sunny",
        symbolName: "sun.max.fill",
        windMilesPerHour: 8,
        humidityPercent: 58,
        dewPointFahrenheit: 62,
        pressureInchesMercury: 29.84,
        uvIndex: 6.4,
        observedAt: .now,
        hourlyUV: [
            HourlyUVSnapshot(date: .now, uvIndex: 6.4),
            HourlyUVSnapshot(date: .now.addingTimeInterval(3_600), uvIndex: 7.1),
            HourlyUVSnapshot(date: .now.addingTimeInterval(7_200), uvIndex: 6.7),
            HourlyUVSnapshot(date: .now.addingTimeInterval(10_800), uvIndex: 4.8)
        ],
        isLive: false
    )
}

struct HourlyUVSnapshot: Identifiable, Equatable {
    var id: Date { date }
    var date: Date
    var uvIndex: Double
}

import Foundation

enum BigDoseWeatherCache {
    private static let storageKey = "bigDose.lastWeatherSnapshot"

    static func save(_ snapshot: BigDoseWeatherSnapshot) {
        guard let data = try? JSONEncoder().encode(CachedWeatherSnapshot(snapshot)) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    static func load() -> BigDoseWeatherSnapshot? {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let cached = try? JSONDecoder().decode(CachedWeatherSnapshot.self, from: data)
        else {
            return nil
        }

        return cached.snapshotForDisplay()
    }
}

private struct CachedWeatherSnapshot: Codable {
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
    var hourlyUV: [CachedHourlyUVSnapshot]
    var hourlyForecast: [CachedHourlyForecast]
    var dailyForecast: [CachedDailyForecast]
    var attributionText: String
    var attributionURLString: String?
    var combinedMarkLightURLString: String?
    var combinedMarkDarkURLString: String?
    var isLive: Bool
    var todaySunrise: Date?
    var todaySunset: Date?
    var todaySolarNoon: Date?

    init(_ snapshot: BigDoseWeatherSnapshot) {
        locationName = snapshot.locationName
        temperatureFahrenheit = snapshot.temperatureFahrenheit
        feelsLikeFahrenheit = snapshot.feelsLikeFahrenheit
        lowTemperatureFahrenheit = snapshot.lowTemperatureFahrenheit
        highTemperatureFahrenheit = snapshot.highTemperatureFahrenheit
        conditionText = snapshot.conditionText
        symbolName = snapshot.symbolName
        cloudCover = snapshot.cloudCover
        windMilesPerHour = snapshot.windMilesPerHour
        humidityPercent = snapshot.humidityPercent
        dewPointFahrenheit = snapshot.dewPointFahrenheit
        pressureInchesMercury = snapshot.pressureInchesMercury
        uvIndex = snapshot.uvIndex
        observedAt = snapshot.observedAt
        hourlyUV = snapshot.hourlyUV.map(CachedHourlyUVSnapshot.init)
        hourlyForecast = snapshot.hourlyForecast.map(CachedHourlyForecast.init)
        dailyForecast = snapshot.dailyForecast.map(CachedDailyForecast.init)
        attributionText = snapshot.attributionText
        attributionURLString = snapshot.attributionURL?.absoluteString
        combinedMarkLightURLString = snapshot.combinedMarkLightURL?.absoluteString
        combinedMarkDarkURLString = snapshot.combinedMarkDarkURL?.absoluteString
        isLive = snapshot.isLive
        todaySunrise = snapshot.todaySunrise
        todaySunset = snapshot.todaySunset
        todaySolarNoon = snapshot.todaySolarNoon
    }

    func snapshotForDisplay(calendar: Calendar = .current) -> BigDoseWeatherSnapshot {
        // Absolute "today" sun stamps are only valid on the observation calendar day.
        let sunEventsAreForToday = calendar.isDateInToday(observedAt)
        let sunrise = sunEventsAreForToday ? todaySunrise : nil
        let sunset = sunEventsAreForToday ? todaySunset : nil
        let solarNoon = sunEventsAreForToday ? todaySolarNoon : nil
        let todaySunEvents = SunEventOverrides(
            sunrise: sunrise,
            sunset: sunset,
            solarNoon: solarNoon
        )

        return BigDoseWeatherSnapshot(
            locationName: locationName,
            temperatureFahrenheit: temperatureFahrenheit,
            feelsLikeFahrenheit: feelsLikeFahrenheit,
            lowTemperatureFahrenheit: lowTemperatureFahrenheit,
            highTemperatureFahrenheit: highTemperatureFahrenheit,
            conditionText: conditionText,
            symbolName: symbolName,
            cloudCover: cloudCover,
            windMilesPerHour: windMilesPerHour,
            humidityPercent: humidityPercent,
            dewPointFahrenheit: dewPointFahrenheit,
            pressureInchesMercury: pressureInchesMercury,
            uvIndex: uvIndex,
            observedAt: observedAt,
            hourlyUV: hourlyUV.map(\.value),
            hourlyForecast: hourlyForecast.map(\.value),
            dailyForecast: dailyForecast.map(\.value),
            attributionText: attributionText,
            attributionURL: attributionURLString.flatMap(URL.init(string:)),
            combinedMarkLightURL: combinedMarkLightURLString.flatMap(URL.init(string:)),
            combinedMarkDarkURL: combinedMarkDarkURLString.flatMap(URL.init(string:)),
            isLive: false,
            todaySunrise: sunrise,
            todaySunset: sunset,
            todaySolarNoon: solarNoon,
            todaySunEvents: todaySunEvents.hasAnyEvent ? todaySunEvents : nil
        )
    }
}

private struct CachedHourlyUVSnapshot: Codable {
    var date: Date
    var uvIndex: Double

    init(_ snapshot: HourlyUVSnapshot) {
        date = snapshot.date
        uvIndex = snapshot.uvIndex
    }

    var value: HourlyUVSnapshot {
        HourlyUVSnapshot(date: date, uvIndex: uvIndex)
    }
}

private struct CachedHourlyForecast: Codable {
    var date: Date
    var temperatureFahrenheit: Double
    var symbolName: String
    var conditionText: String
    var precipitationChance: Double
    var precipitationAmountInches: Double

    init(_ forecast: BigDoseHourlyForecast) {
        date = forecast.date
        temperatureFahrenheit = forecast.temperatureFahrenheit
        symbolName = forecast.symbolName
        conditionText = forecast.conditionText
        precipitationChance = forecast.precipitationChance
        precipitationAmountInches = forecast.precipitationAmountInches
    }

    var value: BigDoseHourlyForecast {
        BigDoseHourlyForecast(
            date: date,
            temperatureFahrenheit: temperatureFahrenheit,
            symbolName: symbolName,
            conditionText: conditionText,
            precipitationChance: precipitationChance,
            precipitationAmountInches: precipitationAmountInches
        )
    }
}

private struct CachedDailyForecast: Codable {
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

    init(_ forecast: BigDoseDailyForecast) {
        date = forecast.date
        highTemperatureFahrenheit = forecast.highTemperatureFahrenheit
        lowTemperatureFahrenheit = forecast.lowTemperatureFahrenheit
        symbolName = forecast.symbolName
        conditionText = forecast.conditionText
        precipitationChance = forecast.precipitationChance
        precipitationAmountInches = forecast.precipitationAmountInches
        sunrise = forecast.sunrise
        sunset = forecast.sunset
        solarNoon = forecast.solarNoon
    }

    var value: BigDoseDailyForecast {
        BigDoseDailyForecast(
            date: date,
            highTemperatureFahrenheit: highTemperatureFahrenheit,
            lowTemperatureFahrenheit: lowTemperatureFahrenheit,
            symbolName: symbolName,
            conditionText: conditionText,
            precipitationChance: precipitationChance,
            precipitationAmountInches: precipitationAmountInches,
            sunrise: sunrise,
            sunset: sunset,
            solarNoon: solarNoon
        )
    }
}

import CoreLocation
import Foundation
import MapKit
import WeatherKit

enum BigDoseWeatherService {
    static func weather(for location: CLLocation) async throws -> BigDoseWeatherSnapshot {
        let service = WeatherService()
        let weather = try await service.weather(for: location)
        let attribution = try? await service.attribution
        let current = weather.currentWeather
        let today = weather.dailyForecast.first
        let locationName = await locationName(for: location) ?? "Current Location"
        let now = Date()

        let upcomingHourly = weather.hourlyForecast.filter { $0.date >= now }

        return BigDoseWeatherSnapshot(
            locationName: locationName,
            temperatureFahrenheit: current.temperature.converted(to: .fahrenheit).value,
            feelsLikeFahrenheit: current.apparentTemperature.converted(to: .fahrenheit).value,
            lowTemperatureFahrenheit: today?.lowTemperature.converted(to: .fahrenheit).value ?? current.temperature.converted(to: .fahrenheit).value,
            highTemperatureFahrenheit: today?.highTemperature.converted(to: .fahrenheit).value ?? current.temperature.converted(to: .fahrenheit).value,
            conditionText: current.condition.description,
            symbolName: current.symbolName,
            cloudCover: current.cloudCover,
            windMilesPerHour: current.wind.speed.converted(to: .milesPerHour).value,
            humidityPercent: current.humidity * 100,
            dewPointFahrenheit: current.dewPoint.converted(to: .fahrenheit).value,
            pressureInchesMercury: current.pressure.converted(to: .inchesOfMercury).value,
            uvIndex: Double(current.uvIndex.value),
            observedAt: current.date,
            hourlyUV: upcomingHourly.prefix(72).map {
                HourlyUVSnapshot(date: $0.date, uvIndex: Double($0.uvIndex.value))
            },
            hourlyForecast: upcomingHourly.prefix(72).map(mapHourlyForecast),
            dailyForecast: weather.dailyForecast.prefix(10).map(mapDailyForecast),
            attributionText: attribution?.legalAttributionText ?? "Weather data provided by Apple Weather.",
            attributionURL: attribution?.legalPageURL ?? URL(string: "https://weatherkit.apple.com/legal-attribution.html"),
            combinedMarkLightURL: attribution?.combinedMarkLightURL,
            combinedMarkDarkURL: attribution?.combinedMarkDarkURL,
            isLive: true
        )
    }

    private static func mapHourlyForecast(_ hour: HourWeather) -> BigDoseHourlyForecast {
        BigDoseHourlyForecast(
            date: hour.date,
            temperatureFahrenheit: hour.temperature.converted(to: .fahrenheit).value,
            symbolName: hour.symbolName,
            conditionText: hour.condition.description,
            precipitationChance: hour.precipitationChance,
            precipitationAmountInches: hour.precipitationAmount.converted(to: .inches).value
        )
    }

    private static func mapDailyForecast(_ day: DayWeather) -> BigDoseDailyForecast {
        BigDoseDailyForecast(
            date: day.date,
            highTemperatureFahrenheit: day.highTemperature.converted(to: .fahrenheit).value,
            lowTemperatureFahrenheit: day.lowTemperature.converted(to: .fahrenheit).value,
            symbolName: day.symbolName,
            conditionText: day.condition.description,
            precipitationChance: day.precipitationChance,
            precipitationAmountInches: day.precipitationAmountByType.precipitation.converted(to: .inches).value
        )
    }

    private static func locationName(for location: CLLocation) async -> String? {
        guard let request = MKReverseGeocodingRequest(location: location),
              let address = try? await request.mapItems.first?.address,
              let shortAddress = address.shortAddress,
              !shortAddress.isEmpty else {
            return nil
        }

        let components = shortAddress
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if let city = components.last {
            return city
        }

        return shortAddress
    }
}

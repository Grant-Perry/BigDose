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

        return BigDoseWeatherSnapshot(
            locationName: locationName,
            temperatureFahrenheit: current.temperature.converted(to: .fahrenheit).value,
            feelsLikeFahrenheit: current.apparentTemperature.converted(to: .fahrenheit).value,
            lowTemperatureFahrenheit: today?.lowTemperature.converted(to: .fahrenheit).value ?? current.temperature.converted(to: .fahrenheit).value,
            highTemperatureFahrenheit: today?.highTemperature.converted(to: .fahrenheit).value ?? current.temperature.converted(to: .fahrenheit).value,
            conditionText: current.condition.description,
            symbolName: current.symbolName,
            windMilesPerHour: current.wind.speed.converted(to: .milesPerHour).value,
            humidityPercent: current.humidity * 100,
            dewPointFahrenheit: current.dewPoint.converted(to: .fahrenheit).value,
            pressureInchesMercury: current.pressure.converted(to: .inchesOfMercury).value,
            uvIndex: Double(current.uvIndex.value),
            observedAt: current.date,
            hourlyUV: weather.hourlyForecast.prefix(12).map {
                HourlyUVSnapshot(date: $0.date, uvIndex: Double($0.uvIndex.value))
            },
            attributionText: attribution?.legalAttributionText ?? "Weather data provided by Apple Weather.",
            attributionURL: attribution?.legalPageURL ?? URL(string: "https://weatherkit.apple.com/legal-attribution.html"),
            combinedMarkLightURL: attribution?.combinedMarkLightURL,
            combinedMarkDarkURL: attribution?.combinedMarkDarkURL,
            isLive: true
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

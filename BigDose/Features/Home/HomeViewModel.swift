import CoreLocation
import Foundation
import Observation

enum WeatherLoadFailure: Equatable {
    case locationDenied
    case locationUnavailable
    case locationUnknown
    case weatherUnavailable(String)
}

@Observable
@MainActor
final class HomeViewModel {
    var weather: BigDoseWeatherSnapshot?
    var dailyPlan: DailySunPlan?
    var isLoading = true
    var statusMessage = "Loading current location and Apple Weather."
    var weatherFailure: WeatherLoadFailure?
    var isShowingCachedWeather = false

    private let locationService = BigDoseLocationService()

    init() {
        if let cached = BigDoseWeatherCache.load() {
            weather = cached
            isShowingCachedWeather = true
            statusMessage = cachedStatusMessage(for: cached)
        }
    }

    func refresh() async {
        isLoading = true
        weatherFailure = nil
        defer { isLoading = false }

        let location: CLLocation

        do {
            location = try await locationService.requestCurrentLocation()
        } catch {
            applyWeatherFailure(for: error)
            return
        }

        do {
            let snapshot = try await BigDoseWeatherService.weather(for: location)
            weather = snapshot
            dailyPlan = nil
            isShowingCachedWeather = false
            weatherFailure = nil
            statusMessage = "WeatherKit data"
            BigDoseWeatherCache.save(snapshot)
        } catch {
            applyWeatherFailure(for: error)
        }
    }

    func refresh(profile: UserProfile) async {
        await refresh()

        guard let weather else { return }

        do {
            let location = try await locationService.requestCurrentLocation()
            dailyPlan = DailySunPlanService.makePlan(profile: profile, weather: weather, location: location)
        } catch {
            dailyPlan = nil
            if weatherFailure == nil {
                statusMessage = solarGuidanceMessage(for: error)
            }
        }
    }

    var locationAuthorizationStatus: CLAuthorizationStatus {
        locationService.authorizationStatus
    }

    func estimate(
        for profile: UserProfile,
        durationSeconds: TimeInterval = 12 * 60,
        latitude: Double = 0,
        longitude: Double = 0
    ) -> VitaminDExposureEstimate {
        guard let weather else {
            return VitaminDExposureEstimate(
                estimatedIU: 0,
                targetDurationSeconds: 0,
                erythemaRiskFraction: 0,
                quality: .noD
            )
        }

        let plan = SunSessionPlanInput(
            startDate: .now,
            durationSeconds: durationSeconds,
            exposedBodySurfaceArea: profile.typicalExposedBodySurfaceArea,
            cloudTransmission: 1,
            sunscreenTransmission: profile.usuallyUsesSunscreen ? 0.35 : 1,
            uvIndex: weather.uvIndex,
            skinType: profile.skinType
        )

        var result = VitaminDCalculator.estimate(
            input: plan.exposureInput(),
            targetIU: Double(profile.preferredDailyIU)
        )
        result.estimatedIU *= SunSessionEligibilityService.vitaminDProductionFactor(
            latitude: latitude,
            longitude: longitude
        )
        return result
    }

    private func applyWeatherFailure(for error: Error) {
        weatherFailure = failureKind(for: error)

        if let cached = BigDoseWeatherCache.load() {
            weather = cached
            isShowingCachedWeather = true
            statusMessage = cachedStatusMessage(for: cached)
        } else {
            weather = nil
            dailyPlan = nil
            isShowingCachedWeather = false
            statusMessage = weatherCardMessage(for: error)
        }
    }

    private func failureKind(for error: Error) -> WeatherLoadFailure {
        switch error {
        case BigDoseLocationError.denied:
            .locationDenied
        case BigDoseLocationError.unavailable:
            .locationUnavailable
        case let error as CLError where error.code == .locationUnknown:
            .locationUnknown
        default:
            .weatherUnavailable(friendlyMessage(for: error))
        }
    }

    private func weatherCardMessage(for error: Error) -> String {
        switch failureKind(for: error) {
        case .locationDenied:
            "Turn on Location for BigDose in Settings to load local weather and UV."
        case .locationUnavailable:
            "Location is unavailable right now. Check Settings and try again."
        case .locationUnknown:
            "Still locating you. Pull to refresh in a moment."
        case .weatherUnavailable(let detail):
            "Apple Weather could not load right now. \(detail)"
        }
    }

    private func solarGuidanceMessage(for error: Error) -> String {
        "Solar guidance unavailable: \(friendlyMessage(for: error))"
    }

    private func cachedStatusMessage(for snapshot: BigDoseWeatherSnapshot) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        let relative = formatter.localizedString(for: snapshot.observedAt, relativeTo: .now)
        return "Showing last saved weather from \(relative)."
    }

    private func friendlyMessage(for error: Error) -> String {
        switch error {
        case BigDoseLocationError.denied:
            "location permission is off"
        case BigDoseLocationError.unavailable:
            "location is unavailable"
        case let error as CLError where error.code == .locationUnknown:
            "still locating you"
        case let error as CLError:
            "\(error.localizedDescription) (\(error.code.rawValue))"
        default:
            error.localizedDescription
        }
    }
}

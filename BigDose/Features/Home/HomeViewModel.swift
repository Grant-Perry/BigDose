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
    var isUsingApproximateLocation = false

    private let locationService = BigDoseLocationService()
    private var locationRetryCount = 0
    private let maxLocationRetries = 3
    private var refreshGeneration = 0

    init() {
        if let cached = BigDoseWeatherCache.load() {
            weather = cached
            isShowingCachedWeather = true
            statusMessage = cachedStatusMessage(for: cached)
        }
    }

    func refresh() async {
        refreshGeneration += 1
        let generation = refreshGeneration
        isLoading = true
        weatherFailure = nil
        defer {
            if generation == refreshGeneration {
                isLoading = false
            }
        }

        let resolved: BigDoseResolvedLocation

        do {
            resolved = try await resolveLocationWithRetries()
        } catch {
            guard generation == refreshGeneration else { return }
            applyWeatherFailure(for: error)
            return
        }

        guard generation == refreshGeneration else { return }
        isUsingApproximateLocation = resolved.isApproximate

        do {
            let snapshot = try await BigDoseWeatherService.weather(for: resolved.location)
            guard generation == refreshGeneration else { return }
            weather = snapshot
            dailyPlan = nil
            isShowingCachedWeather = false
            weatherFailure = nil
            locationRetryCount = 0
            statusMessage = resolved.isApproximate
                ? "Showing weather near you while we refine your exact location. Pull to refresh anytime."
                : "WeatherKit data"
            BigDoseWeatherCache.save(snapshot)
            BigDoseLocationCache.save(resolved.location)
        } catch {
            guard generation == refreshGeneration else { return }
            applyWeatherFailure(for: error)
        }
    }

    private func resolveLocationWithRetries() async throws -> BigDoseResolvedLocation {
        var lastError: Error = BigDoseLocationError.unavailable

        for attempt in 0..<maxLocationRetries {
            locationRetryCount = attempt
            if attempt > 0 {
                statusMessage = "Still locating you for local weather…"
                try? await Task.sleep(for: .seconds(Double(attempt) * 1.5))
            }

            do {
                return try await locationService.resolveLocationForWeather()
            } catch BigDoseLocationError.denied {
                throw BigDoseLocationError.denied
            } catch {
                lastError = error
            }
        }

        throw lastError
    }

    func refresh(profile: UserProfile) async {
        await refresh()
        let planGeneration = refreshGeneration

        // Cached weather is display-only — never drive plans, UV math or sessions.
        guard let weather, hasLiveWeather else { return }

        do {
            let resolved = try await locationService.resolveLocationForWeather()
            guard planGeneration == refreshGeneration else { return }
            dailyPlan = DailySunPlanService.makePlan(
                profile: profile,
                weather: weather,
                location: resolved.location
            )
            isUsingApproximateLocation = resolved.isApproximate
            if resolved.isApproximate {
                if weatherFailure == nil {
                    statusMessage = "Showing weather near you while we refine your exact location. Pull to refresh anytime."
                }
            }
        } catch {
            guard planGeneration == refreshGeneration else { return }
            // Still try plan generation from any cached coordinate so solar guidance is not blank.
            if let cachedLocation = BigDoseLocationCache.load() {
                dailyPlan = DailySunPlanService.makePlan(
                    profile: profile,
                    weather: weather,
                    location: cachedLocation
                )
                isUsingApproximateLocation = true
            } else {
                dailyPlan = nil
                if weatherFailure == nil {
                    statusMessage = solarGuidanceMessage(for: error)
                }
            }
        }
    }

    /// Live WeatherKit snapshot only. Cached fallback must not enable sessions or plan generation.
    var hasLiveWeather: Bool {
        weather != nil && !isShowingCachedWeather
    }

    var canStartSunSession: Bool {
        hasLiveWeather && !isUsingApproximateLocation
    }

    var showsWeatherStatusBanner: Bool {
        isShowingCachedWeather || isUsingApproximateLocation || weatherFailure == .locationDenied
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
        guard hasLiveWeather, let weather else {
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
        let kind = failureKind(for: error)
        weatherFailure = kind
        isUsingApproximateLocation = false

        if let cached = BigDoseWeatherCache.load() {
            weather = cached
            dailyPlan = nil
            isShowingCachedWeather = true
            statusMessage = cachedFailureStatusMessage(kind: kind, snapshot: cached)
        } else {
            weather = nil
            dailyPlan = nil
            isShowingCachedWeather = false
            statusMessage = weatherCardMessage(for: error)
        }
    }

    private func cachedFailureStatusMessage(kind: WeatherLoadFailure, snapshot: BigDoseWeatherSnapshot) -> String {
        switch kind {
        case .locationDenied:
            "Location is off. Showing last saved weather — enable Location in Settings for live UV."
        case .locationUnavailable, .locationUnknown, .weatherUnavailable:
            cachedStatusMessage(for: snapshot)
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

import CoreLocation
import Foundation
import Observation

@Observable
@MainActor
final class HomeViewModel {
    var weather: BigDoseWeatherSnapshot?
    var dailyPlan: DailySunPlan?
    var isLoading = false
    var statusMessage = "Loading current location and Apple Weather."

    private let locationService = BigDoseLocationService()

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        let location: CLLocation

        do {
            location = try await locationService.requestCurrentLocation()
        } catch {
            weather = nil
            dailyPlan = nil
            statusMessage = "Weather unavailable: \(friendlyMessage(for: error))"
            return
        }

        do {
            weather = try await BigDoseWeatherService.weather(for: location)
            dailyPlan = nil
            statusMessage = "Live WeatherKit data"
        } catch {
            weather = nil
            dailyPlan = nil
            statusMessage = "Weather unavailable: \(friendlyMessage(for: error))"
        }
    }

    func refresh(profile: UserProfile) async {
        await refresh()

        if dailyPlan == nil, let weather {
            do {
                let location = try await locationService.requestCurrentLocation()
                dailyPlan = DailySunPlanService.makePlan(profile: profile, weather: weather, location: location)
            } catch {
                dailyPlan = nil
                statusMessage = "Solar guidance unavailable: \(friendlyMessage(for: error))"
            }
        }
    }

    func estimate(for profile: UserProfile, durationSeconds: TimeInterval = 12 * 60) -> VitaminDExposureEstimate {
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

        return VitaminDCalculator.estimate(
            input: plan.exposureInput(),
            targetIU: Double(profile.preferredDailyIU)
        )
    }

    private func friendlyMessage(for error: Error) -> String {
        switch error {
        case BigDoseLocationError.denied:
            "location permission is off"
        case BigDoseLocationError.unavailable:
            "location is unavailable"
        case let error as CLError where error.code == .locationUnknown:
            "location unknown. In Simulator, set Features > Location."
        case let error as CLError:
            "\(error.localizedDescription) (\(error.code.rawValue))"
        default:
            error.localizedDescription
        }
    }
}

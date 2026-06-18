import CoreLocation
import Foundation

enum DailySunPlanService {
    static func makePlan(
        profile: UserProfile,
        weather: BigDoseWeatherSnapshot,
        location: CLLocation,
        now: Date = .now
    ) -> DailySunPlan {
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        let solarDay = SolarGeometryService.solarDay(latitude: latitude, longitude: longitude, date: now)
        let usefulHours = weather.hourlyUV.filter { hour in
            let position = SolarGeometryService.solarPosition(latitude: latitude, longitude: longitude, date: hour.date)
            return position.isVitaminDActive && hour.uvIndex >= 1
        }
        let bestHour = usefulHours.max { $0.uvIndex < $1.uvIndex }
        let nextHour = usefulHours.first { $0.date >= now }
        let peakUV = max(bestHour?.uvIndex ?? weather.uvIndex, weather.uvIndex)
        let targetDuration = VitaminDCalculator.targetDurationSeconds(
            targetIU: Double(profile.preferredDailyIU),
            uvIndex: max(peakUV, 0.1),
            exposedBodySurfaceArea: profile.typicalExposedBodySurfaceArea,
            skinType: profile.skinType
        )
        let estimate = VitaminDCalculator.estimate(
            input: VitaminDExposureInput(
                uvIndex: peakUV,
                durationSeconds: min(max(targetDuration, 10 * 60), 30 * 60),
                exposedBodySurfaceArea: profile.typicalExposedBodySurfaceArea,
                skinType: profile.skinType,
                sunscreenTransmission: profile.usuallyUsesSunscreen ? 0.35 : 1
            ),
            targetIU: Double(profile.preferredDailyIU)
        )
        let fallbackNext = tomorrowSolarNoon(latitude: latitude, longitude: longitude, now: now)

        return DailySunPlan(
            date: Calendar.current.startOfDay(for: now),
            generatedAt: now,
            latitude: latitude,
            longitude: longitude,
            locationLabel: weather.locationName,
            sunrise: solarDay.sunrise,
            solarNoon: solarDay.solarNoon,
            sunset: solarDay.sunset,
            bestWindowStart: bestHour?.date,
            bestWindowEnd: bestHour?.date.addingTimeInterval(3_600),
            nextUsefulStart: nextHour?.date ?? fallbackNext,
            nextUsefulEnd: (nextHour?.date ?? fallbackNext).addingTimeInterval(3_600),
            targetIU: profile.preferredDailyIU,
            estimatedIU: estimate.estimatedIU,
            peakUVIndex: peakUV,
            currentAltitudeDegrees: solarDay.currentPosition.altitudeDegrees,
            quality: estimate.quality,
            weatherAttribution: weather.attributionText
        )
    }

    private static func tomorrowSolarNoon(latitude: Double, longitude: Double, now: Date) -> Date {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now.addingTimeInterval(86_400)
        return SolarGeometryService.solarNoon(latitude: latitude, longitude: longitude, date: tomorrow)
    }

    /// Best remaining sunlight highlight for today — avoids showing a morning peak after it has passed.
    static func displayBestSunlightTime(for plan: DailySunPlan, now: Date = .now) -> Date? {
        if let start = plan.bestWindowStart, start > now {
            return start
        }

        if let next = plan.nextUsefulStart, next > now {
            return next
        }

        if let noon = plan.solarNoon {
            return noon
        }

        return plan.bestWindowStart ?? plan.nextUsefulStart
    }
}

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

        let displayWindow = vitaminDWindowDisplay(latitude: latitude, longitude: longitude, now: now)
        let nextOpportunity = nextVitaminDOpportunity(from: displayWindow, now: now)

        return DailySunPlan(
            date: Calendar.current.startOfDay(for: now),
            generatedAt: now,
            latitude: latitude,
            longitude: longitude,
            locationLabel: weather.locationName,
            sunrise: displayWindow.snapshot.sunrise ?? solarDay.sunrise,
            solarNoon: displayWindow.snapshot.solarNoon,
            sunset: displayWindow.snapshot.sunset ?? solarDay.sunset,
            bestWindowStart: bestHour?.date,
            bestWindowEnd: bestHour?.date.addingTimeInterval(3_600),
            vitaminDWindowStart: displayWindow.snapshot.windowStart,
            vitaminDWindowEnd: displayWindow.snapshot.windowEnd,
            vitaminDWindowReferenceDay: displayWindow.snapshot.referenceDay,
            solarNoonAltitudeDegrees: displayWindow.snapshot.solarNoonAltitudeDegrees,
            vitaminDThresholdDegrees: displayWindow.snapshot.thresholdDegrees,
            nextUsefulStart: nextOpportunity?.date ?? nextHour?.date,
            nextUsefulEnd: nextOpportunity.map { $0.endDate } ?? nextHour?.date.addingTimeInterval(3_600),
            targetIU: profile.preferredDailyIU,
            estimatedIU: estimate.estimatedIU,
            peakUVIndex: peakUV,
            currentAltitudeDegrees: solarDay.currentPosition.altitudeDegrees,
            quality: estimate.quality,
            weatherAttribution: weather.attributionText
        )
    }

    static func vitaminDWindowDisplay(
        latitude: Double,
        longitude: Double,
        now: Date = .now
    ) -> VitaminDWindowDisplay {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: now)
        let todaySnapshot = SolarGeometryService.vitaminDWindow(
            latitude: latitude,
            longitude: longitude,
            date: todayStart
        )

        if let start = todaySnapshot.windowStart,
           let end = todaySnapshot.windowEnd,
           now <= end {
            return VitaminDWindowDisplay(
                snapshot: todaySnapshot,
                isToday: true,
                nextOpportunityStart: now < start ? start : nil,
                nextOpportunityTiming: .today
            )
        }

        let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart) ?? todayStart.addingTimeInterval(86_400)
        let tomorrowSnapshot = SolarGeometryService.vitaminDWindow(
            latitude: latitude,
            longitude: longitude,
            date: tomorrowStart
        )

        return VitaminDWindowDisplay(
            snapshot: tomorrowSnapshot,
            isToday: false,
            nextOpportunityStart: tomorrowSnapshot.windowStart ?? tomorrowSnapshot.solarNoon,
            nextOpportunityTiming: .tomorrow
        )
    }

    static func vitaminDWindowDisplay(for plan: DailySunPlan, now: Date = .now) -> VitaminDWindowDisplay {
        vitaminDWindowDisplay(latitude: plan.latitude, longitude: plan.longitude, now: now)
    }

    /// Best remaining sunlight highlight — never surfaces a past time as if it is still upcoming.
    static func displayBestSunlightHighlight(for plan: DailySunPlan, now: Date = .now) -> BestSunlightHighlight? {
        guard let opportunity = nextVitaminDOpportunity(for: plan, now: now) else { return nil }
        return BestSunlightHighlight(date: opportunity.date, timing: opportunity.timing)
    }

    static func displayBestSunlightTime(for plan: DailySunPlan, now: Date = .now) -> Date? {
        displayBestSunlightHighlight(for: plan, now: now)?.date
    }

    static func nextVitaminDOpportunity(for plan: DailySunPlan, now: Date = .now) -> NextVitaminDOpportunity? {
        nextVitaminDOpportunity(from: vitaminDWindowDisplay(for: plan, now: now), now: now)
    }

    private static func nextVitaminDOpportunity(
        from display: VitaminDWindowDisplay,
        now: Date
    ) -> NextVitaminDOpportunity? {
        if let start = display.nextOpportunityStart, start > now {
            return NextVitaminDOpportunity(
                date: start,
                endDate: display.snapshot.windowEnd ?? start.addingTimeInterval(3_600),
                timing: display.nextOpportunityTiming
            )
        }

        if display.isToday,
           let start = display.snapshot.windowStart,
           let end = display.snapshot.windowEnd,
           now >= start, now <= end {
            return NextVitaminDOpportunity(date: now, endDate: end, timing: .today)
        }

        return nil
    }
}

struct NextVitaminDOpportunity: Equatable {
    var date: Date
    var endDate: Date
    var timing: BestSunlightHighlight.Timing
}

struct BestSunlightHighlight: Equatable {
    enum Timing: Equatable {
        case today
        case tomorrow
    }

    var date: Date
    var timing: Timing

    var title: String {
        let time = date.formatted(date: .omitted, time: .shortened)
        switch timing {
        case .today:
            return "Next D opportunity is today at \(time)"
        case .tomorrow:
            return "Next D opportunity is tomorrow at \(time)"
        }
    }

    var eyebrow: String {
        switch timing {
        case .today:
            return "Up Next"
        case .tomorrow:
            return "Tomorrow's Window"
        }
    }

    var cardTitle: String {
        switch timing {
        case .today:
            return "Vitamin D Window Today"
        case .tomorrow:
            return "Vitamin D Window Tomorrow"
        }
    }
}

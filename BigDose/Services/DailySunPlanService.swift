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

        let displayWindow = vitaminDWindowDisplay(
            latitude: latitude,
            longitude: longitude,
            weather: weather,
            now: now
        )
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
        weather: BigDoseWeatherSnapshot? = nil,
        now: Date = .now
    ) -> VitaminDWindowDisplay {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: now)
        let todaySunEvents = weather?.preferredTodaySunEvents(calendar: calendar)
            ?? weather?.resolvedSunEvents(on: todayStart, calendar: calendar)
        var todaySnapshot = SolarGeometryService.vitaminDWindow(
            latitude: latitude,
            longitude: longitude,
            date: todayStart,
            sunEvents: todaySunEvents
        )
        if let todaySunEvents {
            SunEventApplication.apply(
                todaySunEvents,
                to: &todaySnapshot,
                latitude: latitude,
                longitude: longitude
            )
        }

        if let start = todaySnapshot.windowStart,
           let end = todaySnapshot.windowEnd,
           now <= end {
            return VitaminDWindowDisplay(
                snapshot: todaySnapshot,
                isToday: true,
                nextOpportunityStart: now < start ? start : nil,
                nextOpportunityTiming: .today,
                previousDaylightDuration: daylightDuration(
                    for: todaySnapshot.referenceDay,
                    latitude: latitude,
                    longitude: longitude,
                    weather: weather,
                    calendar: calendar
                )
            )
        }

        let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart) ?? todayStart.addingTimeInterval(86_400)
        let tomorrowSunEvents = weather?.resolvedSunEvents(on: tomorrowStart, calendar: calendar)
        var tomorrowSnapshot = SolarGeometryService.vitaminDWindow(
            latitude: latitude,
            longitude: longitude,
            date: tomorrowStart,
            sunEvents: tomorrowSunEvents
        )
        if let tomorrowSunEvents {
            SunEventApplication.apply(
                tomorrowSunEvents,
                to: &tomorrowSnapshot,
                latitude: latitude,
                longitude: longitude
            )
        }

        return VitaminDWindowDisplay(
            snapshot: tomorrowSnapshot,
            isToday: false,
            nextOpportunityStart: tomorrowSnapshot.windowStart ?? tomorrowSnapshot.solarNoon,
            nextOpportunityTiming: .tomorrow,
            previousDaylightDuration: todaySnapshot.daylightDuration
        )
    }

    private static func daylightDuration(
        for referenceDay: Date,
        latitude: Double,
        longitude: Double,
        weather: BigDoseWeatherSnapshot?,
        calendar: Calendar
    ) -> TimeInterval? {
        guard let previousDay = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: referenceDay)) else {
            return nil
        }

        let previousSunEvents = weather?.resolvedSunEvents(on: previousDay, calendar: calendar)
        var snapshot = SolarGeometryService.vitaminDWindow(
            latitude: latitude,
            longitude: longitude,
            date: previousDay
        )
        if let previousSunEvents {
            SunEventApplication.apply(
                previousSunEvents,
                to: &snapshot,
                latitude: latitude,
                longitude: longitude
            )
        }
        return snapshot.daylightDuration
    }

    static func vitaminDWindowDisplay(for plan: DailySunPlan, weather: BigDoseWeatherSnapshot? = nil, now: Date = .now) -> VitaminDWindowDisplay {
        vitaminDWindowDisplay(latitude: plan.latitude, longitude: plan.longitude, weather: weather, now: now)
    }

    /// Best remaining sunlight highlight — never surfaces a past time as if it is still upcoming.
    static func displayBestSunlightHighlight(for plan: DailySunPlan, now: Date = .now) -> BestSunlightHighlight? {
        let display = vitaminDWindowDisplay(for: plan, now: now)

        if display.isWindowOpenNow {
            return BestSunlightHighlight(date: now, timing: .today, isOpenNow: true)
        }

        guard let opportunity = nextVitaminDOpportunity(from: display, now: now) else { return nil }
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
    var isOpenNow: Bool = false

    var title: String {
        if isOpenNow {
            return "Right Now!"
        }

        return VitaminDWindowHeadline.scheduledOpeningTitle(nextOpening: date)
    }

    var eyebrow: String {
        if isOpenNow {
            return "D Window Open"
        }

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

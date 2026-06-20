import Foundation

struct DailyVitaminDAvailability: Equatable {
    var estimatedIU: Int?
    var windowDurationLabel: String?
    var hasWindow: Bool

    var primaryLabel: String {
        if let estimatedIU {
            return "~\(estimatedIU) IU"
        }

        if hasWindow, let windowDurationLabel {
            return windowDurationLabel
        }

        return "No D"
    }

    var showsWindowDuration: Bool {
        hasWindow && windowDurationLabel != nil
    }
}

enum DailyVitaminDAvailabilityService {
    static func availability(
        for day: Date,
        latitude: Double,
        longitude: Double,
        profile: UserProfile,
        hourlyUV: [HourlyUVSnapshot]
    ) -> DailyVitaminDAvailability {
        guard SunSessionEligibilityService.hasCoordinates(latitude: latitude, longitude: longitude) else {
            return DailyVitaminDAvailability(estimatedIU: nil, windowDurationLabel: nil, hasWindow: false)
        }

        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: day)
        let snapshot = SolarGeometryService.vitaminDWindow(
            latitude: latitude,
            longitude: longitude,
            date: dayStart
        )

        guard snapshot.hasWindow,
              let windowStart = snapshot.windowStart,
              let windowEnd = snapshot.windowEnd,
              let windowDuration = snapshot.duration,
              windowDuration > 0 else {
            return DailyVitaminDAvailability(estimatedIU: nil, windowDurationLabel: nil, hasWindow: false)
        }

        let windowDurationLabel = snapshot.durationLabel
        let peakUV = peakUVInWindow(
            windowStart: windowStart,
            windowEnd: windowEnd,
            day: day,
            latitude: latitude,
            longitude: longitude,
            hourlyUV: hourlyUV
        )

        guard peakUV >= 1 else {
            return DailyVitaminDAvailability(
                estimatedIU: nil,
                windowDurationLabel: windowDurationLabel,
                hasWindow: true
            )
        }

        let sunscreen = profile.usuallyUsesSunscreen ? 0.35 : 1.0
        let targetDuration = VitaminDCalculator.targetDurationSeconds(
            targetIU: Double(profile.preferredDailyIU),
            uvIndex: peakUV,
            exposedBodySurfaceArea: profile.typicalExposedBodySurfaceArea,
            skinType: profile.skinType
        )
        let practicalDuration = min(max(targetDuration, 10 * 60), windowDuration, 60 * 60)
        let estimate = VitaminDCalculator.estimate(
            input: VitaminDExposureInput(
                uvIndex: peakUV,
                durationSeconds: practicalDuration,
                exposedBodySurfaceArea: profile.typicalExposedBodySurfaceArea,
                skinType: profile.skinType,
                sunscreenTransmission: sunscreen
            ),
            targetIU: Double(profile.preferredDailyIU)
        )

        return DailyVitaminDAvailability(
            estimatedIU: Int(estimate.estimatedIU.rounded()),
            windowDurationLabel: windowDurationLabel,
            hasWindow: true
        )
    }

    private static func peakUVInWindow(
        windowStart: Date,
        windowEnd: Date,
        day: Date,
        latitude: Double,
        longitude: Double,
        hourlyUV: [HourlyUVSnapshot]
    ) -> Double {
        let calendar = Calendar.current
        let dayHours = hourlyUV.filter { calendar.isDate($0.date, inSameDayAs: day) }

        let measuredPeak = dayHours
            .filter { hour in
                hour.date >= windowStart
                    && hour.date <= windowEnd
                    && hour.uvIndex >= 1
                    && isVitaminDActive(
                        latitude: latitude,
                        longitude: longitude,
                        date: hour.date
                    )
            }
            .map(\.uvIndex)
            .max()

        if let measuredPeak {
            return measuredPeak
        }

        return synthesizedPeakUV(
            windowStart: windowStart,
            windowEnd: windowEnd,
            latitude: latitude,
            longitude: longitude
        )
    }

    private static func synthesizedPeakUV(
        windowStart: Date,
        windowEnd: Date,
        latitude: Double,
        longitude: Double
    ) -> Double {
        let solarNoon = SolarGeometryService.solarNoon(
            latitude: latitude,
            longitude: longitude,
            date: windowStart
        )

        guard solarNoon >= windowStart, solarNoon <= windowEnd else {
            let midpoint = windowStart.addingTimeInterval(windowEnd.timeIntervalSince(windowStart) / 2)
            return synthesizedUV(at: midpoint, latitude: latitude, longitude: longitude)
        }

        return synthesizedUV(at: solarNoon, latitude: latitude, longitude: longitude)
    }

    private static func synthesizedUV(
        at date: Date,
        latitude: Double,
        longitude: Double
    ) -> Double {
        let altitude = SolarGeometryService.solarPosition(
            latitude: latitude,
            longitude: longitude,
            date: date
        ).altitudeDegrees

        guard altitude >= SolarPosition.vitaminDSynthesisAltitudeDegrees else { return 0 }

        // Rough clear-sky UV index proxy from sun altitude when WeatherKit hourly UV is unavailable.
        let normalized = min(max((altitude - 30) / 45, 0), 1)
        return 2 + normalized * 8
    }

    private static func isVitaminDActive(
        latitude: Double,
        longitude: Double,
        date: Date
    ) -> Bool {
        SolarGeometryService.solarPosition(
            latitude: latitude,
            longitude: longitude,
            date: date
        ).isVitaminDActive
    }
}

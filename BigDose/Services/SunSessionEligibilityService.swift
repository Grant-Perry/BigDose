import Foundation

enum SunSessionStartGate: Equatable {
    case allowed
    case warn(title: String, detail: String)
    case blocked(title: String, detail: String)
}

enum SunSessionEligibilityService {
    static let minimumUVIndex = 1.0
    static let minimumSunAltitudeDegrees = 15.0

    static func startGate(
        latitude: Double,
        longitude: Double,
        uvIndex: Double,
        now: Date = .now
    ) -> SunSessionStartGate {
        let position = SolarGeometryService.solarPosition(
            latitude: latitude,
            longitude: longitude,
            date: now
        )
        let display = DailySunPlanService.vitaminDWindowDisplay(
            latitude: latitude,
            longitude: longitude,
            now: now
        )

        if uvIndex < minimumUVIndex || position.altitudeDegrees < minimumSunAltitudeDegrees {
            return .blocked(
                title: "Sun session unavailable",
                detail: blockedReason(
                    uvIndex: uvIndex,
                    altitudeDegrees: position.altitudeDegrees,
                    display: display,
                    now: now
                )
            )
        }

        if !display.isWindowOpenNow {
            return .warn(
                title: "Outside D window",
                detail: outsideWindowDetail(display: display, now: now)
            )
        }

        return .allowed
    }

    static func vitaminDProductionFactor(
        latitude: Double,
        longitude: Double,
        now: Date = .now
    ) -> Double {
        guard hasCoordinates(latitude: latitude, longitude: longitude) else { return 1 }

        let altitude = SolarGeometryService.solarPosition(
            latitude: latitude,
            longitude: longitude,
            date: now
        ).altitudeDegrees

        if altitude >= SolarPosition.vitaminDSynthesisAltitudeDegrees {
            return 1
        }

        if altitude < minimumSunAltitudeDegrees {
            return 0.08
        }

        let ramp = (altitude - minimumSunAltitudeDegrees)
            / (SolarPosition.vitaminDSynthesisAltitudeDegrees - minimumSunAltitudeDegrees)
        return max(0.08, min(1, ramp))
    }

    static func isOutsideVitaminDWindow(
        latitude: Double,
        longitude: Double,
        now: Date = .now
    ) -> Bool {
        guard hasCoordinates(latitude: latitude, longitude: longitude) else { return false }

        let display = DailySunPlanService.vitaminDWindowDisplay(
            latitude: latitude,
            longitude: longitude,
            now: now
        )
        return !display.isWindowOpenNow
    }

    static func hasCoordinates(latitude: Double, longitude: Double) -> Bool {
        latitude != 0 || longitude != 0
    }

    private static func blockedReason(
        uvIndex: Double,
        altitudeDegrees: Double,
        display: VitaminDWindowDisplay,
        now: Date
    ) -> String {
        if uvIndex < minimumUVIndex, altitudeDegrees < minimumSunAltitudeDegrees {
            return "UV is below 1 and the sun is too low for meaningful vitamin D. Try again during tomorrow's D window."
        }

        if uvIndex < minimumUVIndex {
            return "UV is below 1 right now, so vitamin D production would be negligible."
        }

        if let nextOpening = display.nextOpportunityStart ?? display.snapshot.windowStart {
            if Calendar.current.isDateInTomorrow(nextOpening) || !Calendar.current.isDateInToday(nextOpening) {
                return "The sun is too low tonight. Next D window opens tomorrow at \(VitaminDWindowHeadline.formatTime(nextOpening))."
            }
            return "The sun is too low right now. Next D window opens at \(VitaminDWindowHeadline.formatTime(nextOpening))."
        }

        return "The sun is too low for meaningful vitamin D at your location right now."
    }

    private static func outsideWindowDetail(display: VitaminDWindowDisplay, now: Date) -> String {
        if let end = display.snapshot.windowEnd,
           now > end,
           Calendar.current.isDateInToday(end) {
            return "Today's D window closed at \(VitaminDWindowHeadline.formatTime(end)). You may still get trace UVB, but BigDose will scale IU estimates down."
        }

        if let start = display.snapshot.windowStart, now < start {
            return "Today's D window opens at \(VitaminDWindowHeadline.formatTime(start)). Starting now will produce only trace vitamin D."
        }

        return "The sun is not high enough for efficient vitamin D. BigDose will scale IU estimates down for this session."
    }
}

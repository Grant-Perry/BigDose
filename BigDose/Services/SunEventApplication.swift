import Foundation

enum SunEventApplication {
    static func apply(
        from weather: BigDoseWeatherSnapshot?,
        on day: Date,
        to snapshot: inout VitaminDWindowSnapshot,
        latitude: Double,
        longitude: Double,
        calendar: Calendar = .current
    ) {
        guard let weather else {
            DebugPrint.log("No weather snapshot — keeping geometry sun times", mode: .sunEvents)
            return
        }

        let overrides = weather.resolvedSunEvents(on: day, calendar: calendar)
            ?? (calendar.isDateInToday(day) ? weather.preferredTodaySunEvents(calendar: calendar) : nil)

        guard let overrides else {
            DebugPrint.log(
                "WeatherKit sun events missing for \(Self.dayLabel(day, calendar: calendar)); geometry sunrise=\(BigDoseSunTimeFormat.debugDescription(for: snapshot.sunrise)) sunset=\(BigDoseSunTimeFormat.debugDescription(for: snapshot.sunset))",
                mode: .sunEvents
            )
            return
        }

        let geometrySunrise = snapshot.sunrise
        let geometrySunset = snapshot.sunset
        apply(overrides, to: &snapshot, latitude: latitude, longitude: longitude)

        DebugPrint.log(
            "Applied WeatherKit sun for \(Self.dayLabel(day, calendar: calendar)): sunrise \(BigDoseSunTimeFormat.debugDescription(for: geometrySunrise))→\(BigDoseSunTimeFormat.debugDescription(for: snapshot.sunrise)) sunset \(BigDoseSunTimeFormat.debugDescription(for: geometrySunset))→\(BigDoseSunTimeFormat.debugDescription(for: snapshot.sunset))",
            mode: .sunEvents
        )
    }

    static func apply(
        _ overrides: SunEventOverrides,
        to snapshot: inout VitaminDWindowSnapshot,
        latitude: Double,
        longitude: Double
    ) {
        if let sunrise = overrides.sunrise {
            snapshot.sunrise = sunrise
        }
        if let sunset = overrides.sunset {
            snapshot.sunset = sunset
        }
        if let solarNoon = overrides.solarNoon {
            snapshot.solarNoon = solarNoon
            snapshot.solarNoonAltitudeDegrees = SolarGeometryService.solarPosition(
                latitude: latitude,
                longitude: longitude,
                date: solarNoon
            ).altitudeDegrees
        }
    }

    static func resolvedSnapshot(
        from snapshot: VitaminDWindowSnapshot,
        weather: BigDoseWeatherSnapshot?,
        latitude: Double,
        longitude: Double,
        calendar: Calendar = .current
    ) -> VitaminDWindowSnapshot {
        var resolved = snapshot
        apply(
            from: weather,
            on: snapshot.referenceDay,
            to: &resolved,
            latitude: latitude,
            longitude: longitude,
            calendar: calendar
        )
        return resolved
    }

    private static func dayLabel(_ day: Date, calendar: Calendar) -> String {
        day.formatted(.dateTime.month(.abbreviated).day().hour().minute())
    }
}

import Foundation

enum SolarGeometryService {
    static func solarDay(
        latitude: Double,
        longitude: Double,
        date: Date = .now,
        timeZone: TimeZone = .current
    ) -> SolarDay {
        let position = solarPosition(latitude: latitude, longitude: longitude, date: date, timeZone: timeZone)
        let solarNoon = solarNoon(latitude: latitude, longitude: longitude, date: date, timeZone: timeZone)
        let events = sunriseAndSunset(latitude: latitude, longitude: longitude, date: date, timeZone: timeZone)

        return SolarDay(
            sunrise: events.sunrise,
            solarNoon: solarNoon,
            sunset: events.sunset,
            currentPosition: position
        )
    }

    static func solarPosition(
        latitude: Double,
        longitude: Double,
        date: Date,
        timeZone: TimeZone = .current
    ) -> SolarPosition {
        let calendar = calendar(timeZone: timeZone)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let components = calendar.dateComponents([.hour, .minute, .second], from: date)
        let hour = Double(components.hour ?? 0)
        let minute = Double(components.minute ?? 0)
        let second = Double(components.second ?? 0)
        let fractionalHour = hour + minute / 60 + second / 3_600
        let gamma = fractionalYear(dayOfYear: dayOfYear, hour: fractionalHour)
        let equation = equationOfTime(gamma)
        let declination = solarDeclination(gamma)
        let timezoneHours = Double(timeZone.secondsFromGMT(for: date)) / 3_600
        let timeOffset = equation + 4 * longitude - 60 * timezoneHours
        let trueSolarTime = fractionalHour * 60 + timeOffset
        let hourAngle = degreesToRadians(trueSolarTime / 4 - 180)
        let latitudeRadians = degreesToRadians(latitude)

        let zenithCosine = sin(latitudeRadians) * sin(declination) + cos(latitudeRadians) * cos(declination) * cos(hourAngle)
        let zenith = acos(clamped(zenithCosine, lower: -1, upper: 1))
        let altitude = 90 - radiansToDegrees(zenith)

        let azimuthRadians = atan2(
            sin(hourAngle),
            cos(hourAngle) * sin(latitudeRadians) - tan(declination) * cos(latitudeRadians)
        )
        let azimuth = (radiansToDegrees(azimuthRadians) + 180).truncatingRemainder(dividingBy: 360)

        return SolarPosition(date: date, altitudeDegrees: altitude, azimuthDegrees: azimuth)
    }

    static func vitaminDWindow(
        latitude: Double,
        longitude: Double,
        date: Date,
        altitudeThreshold: Double = SolarPosition.vitaminDSynthesisAltitudeDegrees,
        timeZone: TimeZone = .current
    ) -> VitaminDWindowSnapshot {
        let solarDay = solarDay(latitude: latitude, longitude: longitude, date: date, timeZone: timeZone)
        let crossings = timesAtAltitude(
            latitude: latitude,
            longitude: longitude,
            date: date,
            altitudeDegrees: altitudeThreshold,
            timeZone: timeZone
        )
        let noonPosition = solarPosition(
            latitude: latitude,
            longitude: longitude,
            date: solarDay.solarNoon,
            timeZone: timeZone
        )

        return VitaminDWindowSnapshot(
            referenceDay: Calendar.current.startOfDay(for: date),
            sunrise: solarDay.sunrise,
            sunset: solarDay.sunset,
            solarNoon: solarDay.solarNoon,
            solarNoonAltitudeDegrees: noonPosition.altitudeDegrees,
            windowStart: crossings.morning,
            windowEnd: crossings.evening,
            thresholdDegrees: altitudeThreshold
        )
    }

    static func amLightWindow(
        latitude: Double,
        longitude: Double,
        date: Date,
        timeZone: TimeZone = .current
    ) -> (start: Date?, end: Date?) {
        let lowerCrossing = timesAtAltitude(
            latitude: latitude,
            longitude: longitude,
            date: date,
            altitudeDegrees: SolarPosition.amLightWindowLowerAltitudeDegrees,
            timeZone: timeZone
        )
        let upperCrossing = timesAtAltitude(
            latitude: latitude,
            longitude: longitude,
            date: date,
            altitudeDegrees: SolarPosition.amLightWindowUpperAltitudeDegrees,
            timeZone: timeZone
        )

        return (lowerCrossing.morning, upperCrossing.morning)
    }

    static func timesAtAltitude(
        latitude: Double,
        longitude: Double,
        date: Date,
        altitudeDegrees: Double,
        timeZone: TimeZone = .current
    ) -> (morning: Date?, evening: Date?) {
        let calendar = calendar(timeZone: timeZone)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let gamma = fractionalYear(dayOfYear: dayOfYear, hour: 12)
        let equation = equationOfTime(gamma)
        let declination = solarDeclination(gamma)
        let latitudeRadians = degreesToRadians(latitude)
        let zenith = degreesToRadians(90 - altitudeDegrees)

        let hourAngleCosine = (cos(zenith) / (cos(latitudeRadians) * cos(declination))) - tan(latitudeRadians) * tan(declination)
        guard hourAngleCosine >= -1, hourAngleCosine <= 1 else {
            return (nil, nil)
        }

        let hourAngle = radiansToDegrees(acos(hourAngleCosine))
        let timezoneHours = Double(timeZone.secondsFromGMT(for: date)) / 3_600
        let solarNoonMinutes = 720 - 4 * longitude - equation + timezoneHours * 60
        let morningMinutes = solarNoonMinutes - hourAngle * 4
        let eveningMinutes = solarNoonMinutes + hourAngle * 4

        return (
            dateByAdding(minutes: morningMinutes, toStartOfDayFor: date, timeZone: timeZone),
            dateByAdding(minutes: eveningMinutes, toStartOfDayFor: date, timeZone: timeZone)
        )
    }

    static func solarNoon(
        latitude _: Double,
        longitude: Double,
        date: Date,
        timeZone: TimeZone = .current
    ) -> Date {
        let calendar = calendar(timeZone: timeZone)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let gamma = fractionalYear(dayOfYear: dayOfYear, hour: 12)
        let equation = equationOfTime(gamma)
        let timezoneHours = Double(timeZone.secondsFromGMT(for: date)) / 3_600
        let minutes = 720 - 4 * longitude - equation + timezoneHours * 60
        return dateByAdding(minutes: minutes, toStartOfDayFor: date, timeZone: timeZone)
    }

    private static func sunriseAndSunset(
        latitude: Double,
        longitude: Double,
        date: Date,
        timeZone: TimeZone
    ) -> (sunrise: Date?, sunset: Date?) {
        let calendar = calendar(timeZone: timeZone)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let gamma = fractionalYear(dayOfYear: dayOfYear, hour: 12)
        let equation = equationOfTime(gamma)
        let declination = solarDeclination(gamma)
        let latitudeRadians = degreesToRadians(latitude)
        let zenith = degreesToRadians(90.833)

        let hourAngleCosine = (cos(zenith) / (cos(latitudeRadians) * cos(declination))) - tan(latitudeRadians) * tan(declination)
        guard hourAngleCosine >= -1, hourAngleCosine <= 1 else {
            return (nil, nil)
        }

        let hourAngle = radiansToDegrees(acos(hourAngleCosine))
        let timezoneHours = Double(timeZone.secondsFromGMT(for: date)) / 3_600
        let solarNoonMinutes = 720 - 4 * longitude - equation + timezoneHours * 60
        let sunriseMinutes = solarNoonMinutes - hourAngle * 4
        let sunsetMinutes = solarNoonMinutes + hourAngle * 4

        return (
            dateByAdding(minutes: sunriseMinutes, toStartOfDayFor: date, timeZone: timeZone),
            dateByAdding(minutes: sunsetMinutes, toStartOfDayFor: date, timeZone: timeZone)
        )
    }

    private static func fractionalYear(dayOfYear: Int, hour: Double) -> Double {
        2 * .pi / 365 * (Double(dayOfYear) - 1 + (hour - 12) / 24)
    }

    private static func equationOfTime(_ gamma: Double) -> Double {
        229.18 * (
            0.000075
                + 0.001868 * cos(gamma)
                - 0.032077 * sin(gamma)
                - 0.014615 * cos(2 * gamma)
                - 0.040849 * sin(2 * gamma)
        )
    }

    private static func solarDeclination(_ gamma: Double) -> Double {
        0.006918
            - 0.399912 * cos(gamma)
            + 0.070257 * sin(gamma)
            - 0.006758 * cos(2 * gamma)
            + 0.000907 * sin(2 * gamma)
            - 0.002697 * cos(3 * gamma)
            + 0.00148 * sin(3 * gamma)
    }

    private static func dateByAdding(minutes: Double, toStartOfDayFor date: Date, timeZone: TimeZone) -> Date {
        let calendar = calendar(timeZone: timeZone)
        let startOfDay = calendar.startOfDay(for: date)
        return startOfDay.addingTimeInterval(minutes * 60)
    }

    private static func calendar(timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    private static func degreesToRadians(_ degrees: Double) -> Double {
        degrees * .pi / 180
    }

    private static func radiansToDegrees(_ radians: Double) -> Double {
        radians * 180 / .pi
    }

    private static func clamped(_ value: Double, lower: Double, upper: Double) -> Double {
        min(max(value, lower), upper)
    }
}

import Foundation
import SwiftData

@Model
final class DailySunPlan {
    #Index<DailySunPlan>([\.date])

    var date: Date = Date.now
    var generatedAt: Date = Date.now
    var latitude: Double = 0
    var longitude: Double = 0
    var locationLabel: String = "Current Location"
    var sunrise: Date?
    var solarNoon: Date?
    var sunset: Date?
    var bestWindowStart: Date?
    var bestWindowEnd: Date?
    var nextUsefulStart: Date?
    var nextUsefulEnd: Date?
    var targetIU: Int = 1_000
    var estimatedIU: Double = 0
    var peakUVIndex: Double = 0
    var currentAltitudeDegrees: Double = 0
    var quality: SunWindowQuality = SunWindowQuality.noD
    var weatherAttribution: String?

    init(
        date: Date = .now,
        generatedAt: Date = .now,
        latitude: Double = 0,
        longitude: Double = 0,
        locationLabel: String = "Current Location",
        sunrise: Date? = nil,
        solarNoon: Date? = nil,
        sunset: Date? = nil,
        bestWindowStart: Date? = nil,
        bestWindowEnd: Date? = nil,
        nextUsefulStart: Date? = nil,
        nextUsefulEnd: Date? = nil,
        targetIU: Int = 1_000,
        estimatedIU: Double = 0,
        peakUVIndex: Double = 0,
        currentAltitudeDegrees: Double = 0,
        quality: SunWindowQuality = .noD,
        weatherAttribution: String? = nil
    ) {
        self.date = date
        self.generatedAt = generatedAt
        self.latitude = latitude
        self.longitude = longitude
        self.locationLabel = locationLabel
        self.sunrise = sunrise
        self.solarNoon = solarNoon
        self.sunset = sunset
        self.bestWindowStart = bestWindowStart
        self.bestWindowEnd = bestWindowEnd
        self.nextUsefulStart = nextUsefulStart
        self.nextUsefulEnd = nextUsefulEnd
        self.targetIU = targetIU
        self.estimatedIU = estimatedIU
        self.peakUVIndex = peakUVIndex
        self.currentAltitudeDegrees = currentAltitudeDegrees
        self.quality = quality
        self.weatherAttribution = weatherAttribution
    }
}

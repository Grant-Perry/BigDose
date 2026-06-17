import Foundation
import SwiftData

@Model
final class DailySunPlan {
    #Index<DailySunPlan>([\.date])

    var date: Date
    var generatedAt: Date
    var latitude: Double
    var longitude: Double
    var locationLabel: String
    var sunrise: Date?
    var solarNoon: Date?
    var sunset: Date?
    var bestWindowStart: Date?
    var bestWindowEnd: Date?
    var targetIU: Int
    var estimatedIU: Double
    var peakUVIndex: Double
    var quality: SunWindowQuality
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
        targetIU: Int = 1_000,
        estimatedIU: Double = 0,
        peakUVIndex: Double = 0,
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
        self.targetIU = targetIU
        self.estimatedIU = estimatedIU
        self.peakUVIndex = peakUVIndex
        self.quality = quality
        self.weatherAttribution = weatherAttribution
    }
}

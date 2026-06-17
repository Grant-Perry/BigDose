import Foundation

struct SolarPosition {
    var date: Date
    var altitudeDegrees: Double
    var azimuthDegrees: Double

    var isVitaminDActive: Bool {
        altitudeDegrees >= 45
    }
}

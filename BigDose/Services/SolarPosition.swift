import Foundation

struct SolarPosition {
    static let vitaminDSynthesisAltitudeDegrees = 30.0

    var date: Date
    var altitudeDegrees: Double
    var azimuthDegrees: Double

    var isVitaminDActive: Bool {
        altitudeDegrees >= Self.vitaminDSynthesisAltitudeDegrees
    }
}

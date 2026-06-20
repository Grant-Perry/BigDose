import Foundation

struct SolarPosition {
    static let vitaminDSynthesisAltitudeDegrees = 30.0
    static let amLightWindowLowerAltitudeDegrees = 1.0
    static let amLightWindowUpperAltitudeDegrees = 3.0

    var date: Date
    var altitudeDegrees: Double
    var azimuthDegrees: Double

    var isVitaminDActive: Bool {
        altitudeDegrees >= Self.vitaminDSynthesisAltitudeDegrees
    }
}

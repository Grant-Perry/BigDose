import Foundation

struct VitaminDExposureInput {
    var uvIndex: Double
    var durationSeconds: TimeInterval
    var exposedBodySurfaceArea: Double
    var skinType: FitzpatrickSkinType
    var sunscreenTransmission: Double

    init(
        uvIndex: Double,
        durationSeconds: TimeInterval,
        exposedBodySurfaceArea: Double,
        skinType: FitzpatrickSkinType,
        sunscreenTransmission: Double = 1
    ) {
        self.uvIndex = uvIndex
        self.durationSeconds = durationSeconds
        self.exposedBodySurfaceArea = exposedBodySurfaceArea
        self.skinType = skinType
        self.sunscreenTransmission = sunscreenTransmission
    }
}

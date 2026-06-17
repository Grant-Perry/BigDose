import Foundation

enum VitaminDCalculator {
    private static let erythemalConstant = 40.0
    private static let holickCoefficient = 21_120.0

    static func estimate(input: VitaminDExposureInput, targetIU: Double) -> VitaminDExposureEstimate {
        let effectiveUVIndex = max(0, input.uvIndex) * clamped(input.sunscreenTransmission, lower: 0, upper: 1)
        let exposedArea = clamped(input.exposedBodySurfaceArea, lower: 0.01, upper: 0.85)
        let med = input.skinType.minimalErythemaDoseJoulesPerSquareMeter

        let estimatedIU = holickCoefficient * effectiveUVIndex * input.durationSeconds * exposedArea / (erythemalConstant * med)
        let targetDuration = targetDurationSeconds(
            targetIU: targetIU,
            uvIndex: effectiveUVIndex,
            exposedBodySurfaceArea: exposedArea,
            med: med
        )
        let erythemaDose = effectiveUVIndex * input.durationSeconds / erythemalConstant
        let riskFraction = med > 0 ? erythemaDose / med : 0

        return VitaminDExposureEstimate(
            estimatedIU: estimatedIU,
            targetDurationSeconds: targetDuration,
            erythemaRiskFraction: riskFraction,
            quality: quality(for: effectiveUVIndex, riskFraction: riskFraction)
        )
    }

    static func targetDurationSeconds(
        targetIU: Double,
        uvIndex: Double,
        exposedBodySurfaceArea: Double,
        skinType: FitzpatrickSkinType
    ) -> TimeInterval {
        targetDurationSeconds(
            targetIU: targetIU,
            uvIndex: uvIndex,
            exposedBodySurfaceArea: exposedBodySurfaceArea,
            med: skinType.minimalErythemaDoseJoulesPerSquareMeter
        )
    }

    static func quality(for uvIndex: Double, riskFraction: Double = 0) -> SunWindowQuality {
        if riskFraction >= 0.75 || uvIndex >= 9 {
            return .risk
        }

        switch uvIndex {
        case ..<1:
            return .noD
        case ..<3:
            return .low
        case ..<6:
            return .prime
        case ..<8:
            return .strong
        default:
            return .risk
        }
    }

    private static func targetDurationSeconds(
        targetIU: Double,
        uvIndex: Double,
        exposedBodySurfaceArea: Double,
        med: Double
    ) -> TimeInterval {
        guard uvIndex > 0, exposedBodySurfaceArea > 0, med > 0 else {
            return 0
        }

        return targetIU * erythemalConstant * med / (holickCoefficient * uvIndex * exposedBodySurfaceArea)
    }

    private static func clamped(_ value: Double, lower: Double, upper: Double) -> Double {
        min(max(value, lower), upper)
    }
}

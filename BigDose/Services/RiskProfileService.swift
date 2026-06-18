import Foundation

struct BigDoseRiskProfile {
    var sunStrengthScore: Int
    var skinLimitScore: Int
    var deficiencyProgressScore: Int
    var confidence: String
    var summary: String

    var safetyLabel: String {
        switch skinLimitScore {
        case 0..<35:
            "Low"
        case 35..<70:
            "Moderate"
        default:
            "High"
        }
    }
}

enum RiskProfileService {
    static func evaluate(
        profile: UserProfile,
        weather: BigDoseWeatherSnapshot?,
        dailyPlan: DailySunPlan?,
        progress: BigDoseProgressSnapshot?
    ) -> BigDoseRiskProfile {
        let altitude = max(dailyPlan?.currentAltitudeDegrees ?? 0, 0)
        let uvIndex = weather?.uvIndex ?? dailyPlan?.peakUVIndex ?? 0
        let uvScore = min(Int((uvIndex / 11) * 100), 100)
        let altitudeScore = min(Int((altitude / 70) * 100), 100)
        let sunStrength = max(uvScore, altitudeScore)
        let skinSensitivity = skinSensitivityScore(for: profile.skinType)
        let exposedSkin = Int(profile.typicalExposedBodySurfaceArea * 100)
        let sunscreenOffset = profile.usuallyUsesSunscreen ? 18 : 0
        let skinLimit = min(max((sunStrength + skinSensitivity + exposedSkin) / 3 - sunscreenOffset, 0), 100)
        let estimatedLevel = progress?.estimatedLevel
            ?? profile.baselineNanogramsPerMilliliter
            ?? ProgressAggregationService.conservativeBaseline(for: profile)
        let target = max(profile.goalNanogramsPerMilliliter, 1)
        let deficiencyProgress = min(max(Int((estimatedLevel / target) * 100), 0), 100)
        let confidence = progress?.confidence ?? (weather == nil && dailyPlan == nil ? "Weather unavailable" : "Profile and weather based")

        return BigDoseRiskProfile(
            sunStrengthScore: sunStrength,
            skinLimitScore: skinLimit,
            deficiencyProgressScore: deficiencyProgress,
            confidence: confidence,
            summary: summary(skinLimit: skinLimit, deficiencyProgress: deficiencyProgress)
        )
    }

    private static func skinSensitivityScore(for skinType: FitzpatrickSkinType) -> Int {
        switch skinType {
        case .typeI:
            95
        case .typeII:
            82
        case .typeIII:
            68
        case .typeIV:
            48
        case .typeV:
            34
        case .typeVI:
            22
        }
    }

    private static func summary(skinLimit: Int, deficiencyProgress: Int) -> String {
        if skinLimit >= 70 {
            return "Short sessions and clear stop prompts matter today."
        }

        if deficiencyProgress < 60 {
            return "Your estimate is below target, so consistent intake matters more than long exposure."
        }

        return "Conditions look manageable when you stay inside your skin limit."
    }
}

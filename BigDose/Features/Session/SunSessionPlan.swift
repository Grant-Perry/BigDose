import Foundation

struct SunSessionPlan: Equatable {
    var startedAt: Date
    var durationSeconds: TimeInterval
    var exposedBodySurfaceArea: Double
    var cloudCover: CloudCoverPreset
    var sunscreenTransmission: Double
    var uvIndex: Double
    var currentTemperatureFahrenheit: Double
    var skinType: FitzpatrickSkinType
    var locationName: String
    var targetIU: Double
    var exitLeadFraction: Double

    var input: SunSessionPlanInput {
        SunSessionPlanInput(
            startDate: startedAt,
            durationSeconds: durationSeconds,
            exposedBodySurfaceArea: exposedBodySurfaceArea,
            cloudTransmission: cloudCover.transmission,
            sunscreenTransmission: sunscreenTransmission,
            uvIndex: uvIndex,
            skinType: skinType
        )
    }

    var estimate: VitaminDExposureEstimate {
        VitaminDCalculator.estimate(input: input.exposureInput(), targetIU: targetIU)
    }

    var iuPerMinute: Double {
        liveIUProductionRatePerMinute
    }

    /// Current production rate for one minute at the active skin, cloud, and UV settings.
    var liveIUProductionRatePerMinute: Double {
        let oneMinuteInput = SunSessionPlanInput(
            startDate: startedAt,
            durationSeconds: 60,
            exposedBodySurfaceArea: exposedBodySurfaceArea,
            cloudTransmission: cloudCover.transmission,
            sunscreenTransmission: sunscreenTransmission,
            uvIndex: uvIndex,
            skinType: skinType
        )
        return VitaminDCalculator.estimate(
            input: oneMinuteInput.exposureInput(),
            targetIU: targetIU
        ).estimatedIU
    }

    func estimatedIU(at elapsedSeconds: TimeInterval) -> Double {
        guard elapsedSeconds > 0 else { return 0 }
        return liveIUProductionRatePerMinute * (elapsedSeconds / 60)
    }

    func goalProgress(at elapsedSeconds: TimeInterval) -> Double {
        guard targetIU > 0 else { return 0 }
        return min(estimatedIU(at: elapsedSeconds) / targetIU, 1)
    }

    func minutesToGoal(at elapsedSeconds: TimeInterval) -> Int? {
        let currentIU = estimatedIU(at: elapsedSeconds)
        guard liveIUProductionRatePerMinute > 0, currentIU < targetIU else { return nil }
        let remainingIU = targetIU - currentIU
        return max(1, Int(ceil(remainingIU / liveIUProductionRatePerMinute)))
    }

    func hasReachedGoal(at elapsedSeconds: TimeInterval) -> Bool {
        targetIU > 0 && estimatedIU(at: elapsedSeconds) >= targetIU
    }

    var medTimeSeconds: TimeInterval {
        let effectiveUV = input.effectiveUVIndex
        let med = skinType.minimalErythemaDoseJoulesPerSquareMeter
        guard effectiveUV > 0 else { return 0 }
        return med * 40 / effectiveUV
    }

    var turnOverAlertSeconds: TimeInterval {
        let halfSession = durationSeconds / 2
        guard medTimeSeconds > 0 else { return halfSession }
        return min(halfSession, medTimeSeconds * 0.5)
    }

    var medWarningSeconds: TimeInterval {
        guard medTimeSeconds > 0 else { return durationSeconds }
        return medTimeSeconds * 0.75
    }

    var stopAlertSeconds: TimeInterval {
        guard medTimeSeconds > 0 else { return durationSeconds }
        return medTimeSeconds * 0.9
    }

    static let defaultExitLeadFraction = 0.20

    /// Fires early enough to pack up before the stop alert.
    var prepareExitAlertSeconds: TimeInterval {
        guard stopAlertSeconds > 0 else { return durationSeconds }
        return stopAlertSeconds * (1 - exitLeadFraction)
    }

    var prepareExitLeadSeconds: TimeInterval {
        max(0, stopAlertSeconds - prepareExitAlertSeconds)
    }

    var prepareExitCountdownText: String {
        Self.durationClockText(prepareExitLeadSeconds)
    }

    static func durationClockText(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        let minutes = total / 60
        let secondsPart = total % 60
        return "\(minutes):\(String(format: "%02d", secondsPart))"
    }
}

struct SunSessionResult: Equatable {
    var plan: SunSessionPlan
    var endedAt: Date
    var elapsedSeconds: TimeInterval
    var estimatedIU: Double

    var averageRate: Double {
        guard elapsedSeconds > 0 else { return 0 }
        return estimatedIU / (elapsedSeconds / 60)
    }

    var percentOfTarget: Double {
        guard plan.targetIU > 0 else { return 0 }
        return min(estimatedIU / plan.targetIU, 1)
    }
}

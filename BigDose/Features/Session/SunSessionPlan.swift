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
    var latitude: Double = 0
    var longitude: Double = 0

    var vitaminDProductionFactor: Double {
        SunSessionEligibilityService.vitaminDProductionFactor(
            latitude: latitude,
            longitude: longitude,
            now: startedAt
        )
    }

    var isOutsideVitaminDWindow: Bool {
        SunSessionEligibilityService.isOutsideVitaminDWindow(
            latitude: latitude,
            longitude: longitude,
            now: startedAt
        )
    }

    var isTraceVitaminDConditions: Bool {
        vitaminDProductionFactor < 0.95
    }

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
        var result = VitaminDCalculator.estimate(input: input.exposureInput(), targetIU: targetIU)
        result.estimatedIU *= vitaminDProductionFactor
        return result
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
        ).estimatedIU * vitaminDProductionFactor
    }

    func estimatedIU(at elapsedSeconds: TimeInterval) -> Double {
        guard elapsedSeconds > 0 else { return 0 }
        return liveIUProductionRatePerMinute * (elapsedSeconds / 60)
    }

    func medUsedFraction(at elapsedSeconds: TimeInterval) -> Double {
        guard medTimeSeconds > 0 else { return 0 }
        return elapsedSeconds / medTimeSeconds
    }

    func medUsedPercent(at elapsedSeconds: TimeInterval) -> Int {
        Int((medUsedFraction(at: elapsedSeconds) * 100).rounded())
    }

    func medRemainingMinutes(at elapsedSeconds: TimeInterval) -> Int {
        max(0, Int(((medTimeSeconds - elapsedSeconds) / 60).rounded()))
    }

    func safetyAlertMessage(for alert: SunSessionSafetyAlertKind, elapsedSeconds: TimeInterval) -> String {
        let medPercent = medUsedPercent(at: elapsedSeconds)
        let skin = skinType.title

        switch alert {
        case .turnOver:
            return "You are at about \(medPercent)% of your estimated MED for \(skin) skin at this UV. Flip sides, rotate or change exposure so one area doesn't take all of it."
        case .medWarning:
            return "You are at about \(medPercent)% of your estimated MED — the UV dose that would start to redden \(skin) skin. Consider wrapping up soon."
        case .prepareExit(let countdown):
            return "You are at about \(medPercent)% of MED. Start heading inside — your recommended stop point is in \(countdown)."
        case .stop:
            return "You are at about \(medPercent)% of your estimated MED for \(skin) skin. BigDose paused the timer because continued exposure risks exceeding your conservative limit."
        }
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

    /// Minutes of exposure at current settings to reach the session IU goal.
    var goalDurationSeconds: TimeInterval {
        guard liveIUProductionRatePerMinute > 0, targetIU > 0 else { return 60 }
        return max(60, ceil(targetIU / liveIUProductionRatePerMinute) * 60)
    }

    /// Maximum planned session length — capped at the conservative MED stop point.
    var safeMaxDurationSeconds: TimeInterval {
        guard medTimeSeconds > 0 else { return 30 * 60 }
        return max(60, stopAlertSeconds)
    }

    /// Default planned duration: enough for the goal without exceeding safe MED headroom.
    var recommendedDurationSeconds: TimeInterval {
        clampedPlannedDuration(min(goalDurationSeconds, safeMaxDurationSeconds))
    }

    var safetyTimelineMinutes: SunSessionSafetyTimeline? {
        guard medTimeSeconds > 0 else { return nil }
        return SunSessionSafetyTimeline(
            turnOver: max(1, Int((turnOverAlertSeconds / 60).rounded())),
            wrapUp: max(1, Int((medWarningSeconds / 60).rounded())),
            safeExit: max(1, Int((stopAlertSeconds / 60).rounded()))
        )
    }

    func clampedPlannedDuration(_ seconds: TimeInterval) -> TimeInterval {
        let rounded = (seconds / 60).rounded() * 60
        return min(max(rounded, 60), safeMaxDurationSeconds)
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

struct SunSessionSafetyTimeline: Equatable {
    var turnOver: Int
    var wrapUp: Int
    var safeExit: Int
}

enum SunSessionDurationPreset: CaseIterable {
    case toGoal
    case safeMax

    func durationSeconds(for plan: SunSessionPlan) -> TimeInterval {
        switch self {
        case .toGoal:
            plan.clampedPlannedDuration(plan.goalDurationSeconds)
        case .safeMax:
            plan.safeMaxDurationSeconds
        }
    }

    func title(for plan: SunSessionPlan) -> String {
        let minutes = Int((durationSeconds(for: plan) / 60).rounded())
        switch self {
        case .toGoal:
            return "To goal (~\(minutes) min)"
        case .safeMax:
            return "Safe max (~\(minutes) min)"
        }
    }
}

enum SunSessionSafetyAlertKind {
    case turnOver
    case medWarning
    case prepareExit(countdown: String)
    case stop
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

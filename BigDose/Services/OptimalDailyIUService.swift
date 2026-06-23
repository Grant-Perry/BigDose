import Foundation

struct OptimalDailyIURecommendation: Equatable, Sendable {
    var totalDailyIU: Int
    var maintenanceIU: Int
    var levelCorrectionIU: Int
    var weightAdjustmentIU: Int
    var sunSessionTargetIU: Int

    var supplementOffsetIU: Int
    var startingLevelNgML: Double
    var goalLevelNgML: Double

    /// One-line label for badges and captions.
    var summaryLine: String {
        "BigDose recommends \(totalDailyIU.formatted()) IU/day total — \(sunSessionTargetIU.formatted()) IU from tracked sun after supplements."
    }
}

enum OptimalDailyIUService {
    /// Matches ProgressAggregationService: ~10,000 IU surplus over 90 days ≈ +1 ng/mL.
    private static let iuPerNgMLGapPerDay = 10_000.0 / 90.0
    private static let referenceWeightKilograms = 70.0
    private static let minimumSunSessionIU = 400

    static func recommend(
        dateOfBirth: Date?,
        biologicalSex: BiologicalSex,
        weightKilograms: Double?,
        goalNanogramsPerMilliliter: Double,
        baselineNanogramsPerMilliliter: Double?,
        levelKnowledge: VitaminDLevelKnowledge,
        incidentalSunMinutesPerWeek: Int,
        defaultSupplementIU: Int,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> OptimalDailyIURecommendation {
        let age = ageYears(from: dateOfBirth, now: now, calendar: calendar)
        let maintenance = maintenanceIU(age: age, biologicalSex: biologicalSex, goalNgML: goalNanogramsPerMilliliter)
        let startingLevel = baselineNanogramsPerMilliliter
            ?? conservativeStartingLevel(
                levelKnowledge: levelKnowledge,
                incidentalSunMinutesPerWeek: incidentalSunMinutesPerWeek
            )
        let gap = max(0, goalNanogramsPerMilliliter - startingLevel)
        let levelCorrection = Int((gap * iuPerNgMLGapPerDay).rounded())
        let weightAdjustment = weightAdjustmentIU(weightKilograms: weightKilograms)
        let total = roundedTarget(maintenance + levelCorrection + weightAdjustment)
        let sunTarget = sunSessionTargetIU(
            totalDailyIU: total,
            defaultSupplementIU: defaultSupplementIU
        )

        return OptimalDailyIURecommendation(
            totalDailyIU: total,
            maintenanceIU: maintenance,
            levelCorrectionIU: levelCorrection,
            weightAdjustmentIU: weightAdjustment,
            sunSessionTargetIU: sunTarget,
            supplementOffsetIU: defaultSupplementIU,
            startingLevelNgML: startingLevel,
            goalLevelNgML: goalNanogramsPerMilliliter
        )
    }

    static func recommend(for profile: UserProfile, now: Date = .now) -> OptimalDailyIURecommendation {
        recommend(
            dateOfBirth: profile.dateOfBirth,
            biologicalSex: profile.biologicalSex,
            weightKilograms: profile.weightKilograms,
            goalNanogramsPerMilliliter: profile.goalNanogramsPerMilliliter,
            baselineNanogramsPerMilliliter: profile.baselineNanogramsPerMilliliter,
            levelKnowledge: profile.levelKnowledge,
            incidentalSunMinutesPerWeek: profile.incidentalSunMinutesPerWeek,
            defaultSupplementIU: profile.defaultSupplementIU,
            now: now
        )
    }

    private static func maintenanceIU(age: Int, biologicalSex: BiologicalSex, goalNgML: Double) -> Int {
        var base: Int
        if age >= 70 {
            base = 800
        } else if age >= 1 {
            base = 600
        } else {
            base = 600
        }

        if goalNgML >= 40 {
            base = max(base, 1_500)
        }

        if biologicalSex == .female, age >= 14, age <= 50 {
            base = max(base, 600)
        }

        return base
    }

    private static func conservativeStartingLevel(
        levelKnowledge: VitaminDLevelKnowledge,
        incidentalSunMinutesPerWeek: Int
    ) -> Double {
        switch levelKnowledge {
        case .knowsRecentResult:
            25
        case .wantsEstimate:
            incidentalSunMinutesPerWeek >= 90 ? 30 : 25
        case .willAddLater:
            25
        }
    }

    private static func weightAdjustmentIU(weightKilograms: Double?) -> Int {
        guard let weightKilograms, weightKilograms > referenceWeightKilograms else { return 0 }
        let excessKilograms = weightKilograms - referenceWeightKilograms
        return Int((excessKilograms / 10 * 25).rounded())
    }

    private static func sunSessionTargetIU(totalDailyIU: Int, defaultSupplementIU: Int) -> Int {
        let remainder = totalDailyIU - defaultSupplementIU
        return roundedTarget(max(minimumSunSessionIU, remainder))
    }

    private static func roundedTarget(_ value: Int) -> Int {
        let rounded = Int((Double(value) / 100).rounded()) * 100
        return max(400, rounded)
    }

    private static func ageYears(from dateOfBirth: Date?, now: Date, calendar: Calendar) -> Int {
        guard let dateOfBirth else { return 40 }
        return max(calendar.dateComponents([.year], from: dateOfBirth, to: now).year ?? 40, 1)
    }
}

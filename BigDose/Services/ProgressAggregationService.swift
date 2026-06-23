import Foundation

struct BigDoseProgressSnapshot {
    var startDate: Date
    var endDate: Date
    var sunIU: Double
    var supplementIU: Double
    var foodIU: Double
    var targetIU: Double
    var latestLab: LabResult?
    var estimatedLevel: Double
    var confidence: String

    var totalIU: Double {
        sunIU + supplementIU + foodIU
    }

    var goalProgress: Double {
        guard targetIU > 0 else { return 0 }
        return min(sunIU / targetIU, 1)
    }

    var levelProgress: Double {
        guard let goal = latestLab?.nanogramsPerMilliliter ?? Optional(estimatedLevel), goal > 0 else {
            return 0
        }
        return min(goal / max(1, targetIU), 1)
    }
}

enum ProgressAggregationService {
    static func snapshot(
        profile: UserProfile,
        sessions: [ExposureSession],
        supplements: [SupplementDose],
        foods: [FoodVitaminDEntry],
        labs: [LabResult],
        days: Int = 7,
        calendar: Calendar = .current,
        now: Date = .now
    ) -> BigDoseProgressSnapshot {
        let start = calendar.date(byAdding: .day, value: -days, to: now) ?? now
        let sunIU = sessions
            .filter { $0.startedAt >= start && $0.startedAt <= now }
            .reduce(0) { $0 + $1.estimatedIU }
        let supplementIU = supplements
            .filter { $0.takenAt >= start && $0.takenAt <= now }
            .reduce(0) { $0 + Double($1.internationalUnits) }
        let foodIU = foods
            .filter { $0.loggedAt >= start && $0.loggedAt <= now }
            .reduce(0) { $0 + Double($1.estimatedIU) }
        let latestLab = labs.sorted { $0.measuredAt > $1.measuredAt }.first
        let dailyTarget = Double(max(profile.preferredDailyIU, 1))
        let estimatedLevel = estimatedBloodLevel(profile: profile, latestLab: latestLab, recentIU: sunIU + supplementIU + foodIU, days: days)

        return BigDoseProgressSnapshot(
            startDate: start,
            endDate: now,
            sunIU: sunIU,
            supplementIU: supplementIU,
            foodIU: foodIU,
            targetIU: dailyTarget * Double(days),
            latestLab: latestLab,
            estimatedLevel: estimatedLevel,
            confidence: latestLab == nil ? "Estimated baseline" : "Anchored by latest lab"
        )
    }

    static func estimatedBloodLevel(
        profile: UserProfile,
        latestLab: LabResult?,
        recentIU: Double,
        days: Int
    ) -> Double {
        let anchor = latestLab?.nanogramsPerMilliliter
            ?? profile.baselineNanogramsPerMilliliter
            ?? conservativeBaseline(for: profile)
        let expectedIU = Double(max(profile.preferredDailyIU, 1) * max(days, 1))
        let delta = (recentIU - expectedIU) / 10_000
        return max(5, anchor + delta)
    }

    static func conservativeBaseline(for profile: UserProfile) -> Double {
        switch profile.levelKnowledge {
        case .knowsRecentResult:
            profile.baselineNanogramsPerMilliliter ?? 25
        case .wantsEstimate:
            profile.incidentalSunMinutesPerWeek >= 90 ? 30 : 25
        case .willAddLater:
            25
        }
    }
}

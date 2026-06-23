import Foundation

struct DailyIUIntakeSummary: Equatable, Sendable {
    var sunIU: Double
    var supplementIU: Double
    var foodIU: Double

    var totalIU: Double {
        sunIU + supplementIU + foodIU
    }

    /// Progress toward the daily IU target from sun exposure only — excludes supplements and food.
    func sunGoalProgress(dailyTargetIU: Double) -> Double {
        guard dailyTargetIU > 0 else { return 0 }
        return min(max(sunIU / dailyTargetIU, 0), 1)
    }

    func remainingSunIUForGoal(dailyTargetIU: Double) -> Double {
        max(dailyTargetIU - sunIU, 0)
    }
}

enum DailyIUIntakeAggregation {
    static func today(
        sessions: [ExposureSession],
        supplements: [SupplementDose],
        foods: [FoodVitaminDEntry],
        calendar: Calendar = .current
    ) -> DailyIUIntakeSummary {
        let sunIU = sessions
            .filter { calendar.isDateInToday($0.startedAt) }
            .reduce(0) { $0 + $1.estimatedIU }
        let supplementIU = supplements
            .filter { calendar.isDateInToday($0.takenAt) }
            .reduce(0) { $0 + Double($1.internationalUnits) }
        let foodIU = foods
            .filter { calendar.isDateInToday($0.loggedAt) }
            .reduce(0) { $0 + Double($1.estimatedIU) }

        return DailyIUIntakeSummary(
            sunIU: sunIU,
            supplementIU: supplementIU,
            foodIU: foodIU
        )
    }
}

import Foundation

struct TodaySunBreakdown: Equatable, Sendable {
    var trackedIU: Double
    var incidentalIU: Double
    var importedIU: Double

    var totalSunIU: Double {
        trackedIU + incidentalIU + importedIU
    }

    static let empty = TodaySunBreakdown(trackedIU: 0, incidentalIU: 0, importedIU: 0)
}

struct DailyIUIntakeSummary: Equatable, Sendable {
    var sunIU: Double
    var supplementIU: Double
    var foodIU: Double
    var sunBreakdown: TodaySunBreakdown
    var medExcessSeconds: TimeInterval = 0

    var totalIU: Double {
        sunIU + supplementIU + foodIU
    }

    /// Progress toward the daily IU target from sun (+ food) — excludes supplements.
    func sunGoalProgress(dailyTargetIU: Double) -> Double {
        dailyGoalProgress(
            sunTargetIU: dailyTargetIU,
            totalDailyTargetIU: dailyTargetIU,
            includesSupplements: false
        )
    }

    /// Progress toward the daily IU target. Optionally counts logged supplement IU against the recommended total.
    /// Food IU always counts toward the same numerator used for Today totals.
    func dailyGoalProgress(
        sunTargetIU: Double,
        totalDailyTargetIU: Double,
        includesSupplements: Bool
    ) -> Double {
        let base = includesSupplements ? sunIU + supplementIU : sunIU
        let numerator = base + foodIU
        let denominator = includesSupplements ? totalDailyTargetIU : sunTargetIU
        guard denominator > 0 else { return 0 }
        return min(max(numerator / denominator, 0), 1)
    }

    /// Remaining IU still needed from sun to finish the daily goal.
    func remainingSunIUForGoal(
        sunTargetIU: Double,
        totalDailyTargetIU: Double,
        includesSupplements: Bool
    ) -> Double {
        if includesSupplements {
            return max(totalDailyTargetIU - sunIU - supplementIU - foodIU, 0)
        }
        return max(sunTargetIU - sunIU - foodIU, 0)
    }
}

enum DailyIUIntakeAggregation {
    static func today(
        sessions: [ExposureSession],
        supplements: [SupplementDose],
        foods: [FoodVitaminDEntry],
        calendar: Calendar = .current,
        now: Date = .now
    ) -> DailyIUIntakeSummary {
        let sunBreakdown = todaySunBreakdown(from: sessions, calendar: calendar, now: now)
        let medExcessSeconds = SunExposureAggregation.todayMedExcessSeconds(
            from: sessions,
            calendar: calendar
        )
        let supplementIU = supplements
            .filter { calendar.isDateInToday($0.takenAt) }
            .reduce(0) { $0 + Double($1.internationalUnits) }
        let foodIU = foods
            .filter { calendar.isDateInToday($0.loggedAt) }
            .reduce(0) { $0 + Double($1.estimatedIU) }

        return DailyIUIntakeSummary(
            sunIU: sunBreakdown.totalSunIU,
            supplementIU: supplementIU,
            foodIU: foodIU,
            sunBreakdown: sunBreakdown,
            medExcessSeconds: medExcessSeconds
        )
    }

    static func todaySunBreakdown(
        from sessions: [ExposureSession],
        calendar: Calendar = .current,
        now: Date = .now
    ) -> TodaySunBreakdown {
        sunBreakdown(from: sessions, on: now, calendar: calendar)
    }

    static func sunBreakdown(from sessions: [ExposureSession]) -> TodaySunBreakdown {
        var trackedIU = 0.0
        var incidentalIU = 0.0
        var importedIU = 0.0

        for session in sessions {
            switch session.source {
            case .healthKitDaylight:
                incidentalIU += session.estimatedIU
            case .healthKit:
                importedIU += session.estimatedIU
            case .liveTracked, .manual, .planned, .rescueFile:
                trackedIU += session.estimatedIU
            }
        }

        return TodaySunBreakdown(
            trackedIU: trackedIU,
            incidentalIU: incidentalIU,
            importedIU: importedIU
        )
    }

    /// Attributes IU to a calendar day by wall-clock overlap (handles midnight straddles).
    static func sunBreakdown(
        from sessions: [ExposureSession],
        on day: Date,
        calendar: Calendar = .current
    ) -> TodaySunBreakdown {
        var trackedIU = 0.0
        var incidentalIU = 0.0
        var importedIU = 0.0

        for session in sessions {
            let iu = ExposureSessionDaySplit.attributedIU(for: session, on: day, calendar: calendar)
            guard iu > 0 else { continue }

            switch session.source {
            case .healthKitDaylight:
                incidentalIU += iu
            case .healthKit:
                importedIU += iu
            case .liveTracked, .manual, .planned, .rescueFile:
                trackedIU += iu
            }
        }

        return TodaySunBreakdown(
            trackedIU: trackedIU,
            incidentalIU: incidentalIU,
            importedIU: importedIU
        )
    }
}

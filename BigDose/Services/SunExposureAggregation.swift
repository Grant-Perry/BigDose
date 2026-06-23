import Foundation

enum SunSessionSafetyThresholds {
    static let turnOverPercent = 50
    static let wrapUpPercent = 75
    static let guidanceLimitPercent = 95
    static let nannyReminderPercent = 98
    static let overLimitBaselinePercent = 100

    static func medOverLimitPercent(for peakMedUsedPercent: Int) -> Int {
        max(0, peakMedUsedPercent - overLimitBaselinePercent)
    }
}

struct TodaySunRiskSummary: Equatable, Sendable {
    var liveSessionCount: Int
    var totalMedUsedPercent: Int
    var totalMedOverLimitPercent: Int

    var hasOverLimitExposure: Bool {
        totalMedOverLimitPercent > 0
    }

    static let empty = TodaySunRiskSummary(
        liveSessionCount: 0,
        totalMedUsedPercent: 0,
        totalMedOverLimitPercent: 0
    )
}

enum SunExposureAggregation {
    static func todayLiveSessionRisk(
        from sessions: [ExposureSession],
        now: Date = .now
    ) -> TodaySunRiskSummary {
        let calendar = Calendar.current
        let todayLive = sessions.filter {
            calendar.isDateInToday($0.startedAt) && $0.source == .liveTracked
        }

        guard !todayLive.isEmpty else { return .empty }

        return TodaySunRiskSummary(
            liveSessionCount: todayLive.count,
            totalMedUsedPercent: todayLive.reduce(0) { $0 + $1.peakMedUsedPercent },
            totalMedOverLimitPercent: todayLive.reduce(0) { $0 + $1.medOverLimitPercent }
        )
    }
}

import Foundation

struct BigDoseWidgetSnapshot: Codable, Sendable, Equatable {
    var generatedAt: Date
    var locationLabel: String
    var currentUVIndex: Double
    var peakUVIndex: Double
    var windowQualityTitle: String
    var bestWindowStart: Date?
    var bestWindowEnd: Date?
    var nextUsefulStart: Date?
    var nextUsefulEnd: Date?
    var todayCollectedIU: Double
    var targetIU: Int
    var isInBestWindow: Bool
    var isOnboardingComplete: Bool
    var activeSession: ActiveSessionWidgetState?

    var todayGoalProgress: Double {
        guard targetIU > 0 else { return 0 }
        return min(max(todayCollectedIU / Double(targetIU), 0), 1)
    }

    var nextTimelineRefreshDate: Date {
        let now = Date.now
        let calendar = Calendar.current

        if activeSession != nil {
            return calendar.date(byAdding: .second, value: 15, to: now) ?? now.addingTimeInterval(15)
        }

        if isInBestWindow, let end = bestWindowEnd, end > now {
            return end
        }

        if let start = nextUsefulStart, start > now {
            return start
        }

        if let start = bestWindowStart, start > now {
            return start
        }

        return calendar.date(byAdding: .minute, value: 30, to: now) ?? now.addingTimeInterval(1_800)
    }

    var widgetDeepLinkURL: URL? {
        if let sessionID = activeSession?.sessionID {
            return SunSessionActivityAttributes.appOpenURL(sessionID: sessionID)
        }

        return URL(string: "bigdose://home")
    }

    static let placeholder = BigDoseWidgetSnapshot(
        generatedAt: .now,
        locationLabel: "BigDose",
        currentUVIndex: 0,
        peakUVIndex: 0,
        windowQualityTitle: "Open app",
        bestWindowStart: nil,
        bestWindowEnd: nil,
        nextUsefulStart: nil,
        nextUsefulEnd: nil,
        todayCollectedIU: 0,
        targetIU: 1_000,
        isInBestWindow: false,
        isOnboardingComplete: false,
        activeSession: nil
    )
}

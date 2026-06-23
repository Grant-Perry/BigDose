import Foundation

nonisolated struct BigDoseWidgetSnapshot: Codable, Sendable, Equatable {
    var generatedAt: Date
    var locationLabel: String
    var currentUVIndex: Double
    var peakUVIndex: Double
    var windowQualityTitle: String
    var bestWindowStart: Date?
    var bestWindowEnd: Date?
    var nextUsefulStart: Date?
    var nextUsefulEnd: Date?
    var vitaminDWindowStart: Date?
    var vitaminDWindowEnd: Date?
    var nextVitaminDWindowStart: Date?
    var isVitaminDWindowOpenNow: Bool
    var todaySunIU: Double
    var targetIU: Int
    var isInBestWindow: Bool
    var isOnboardingComplete: Bool
    var activeSession: ActiveSessionWidgetState?

    var todayGoalProgress: Double {
        guard targetIU > 0 else { return 0 }
        return min(max(todaySunIU / Double(targetIU), 0), 1)
    }

    enum CodingKeys: String, CodingKey {
        case generatedAt
        case locationLabel
        case currentUVIndex
        case peakUVIndex
        case windowQualityTitle
        case bestWindowStart
        case bestWindowEnd
        case nextUsefulStart
        case nextUsefulEnd
        case vitaminDWindowStart
        case vitaminDWindowEnd
        case nextVitaminDWindowStart
        case isVitaminDWindowOpenNow
        case todaySunIU = "todayCollectedIU"
        case targetIU
        case isInBestWindow
        case isOnboardingComplete
        case activeSession
    }

    var nextTimelineRefreshDate: Date {
        let now = Date.now
        let calendar = Calendar.current

        if activeSession != nil {
            return calendar.date(byAdding: .second, value: 15, to: now) ?? now.addingTimeInterval(15)
        }

        if isVitaminDWindowOpenNow, let end = vitaminDWindowEnd, end > now {
            return end
        }

        if let start = nextVitaminDWindowStart, start > now {
            return start
        }

        if let end = vitaminDWindowEnd, end > now {
            return end
        }

        return calendar.date(byAdding: .minute, value: 30, to: now) ?? now.addingTimeInterval(1_800)
    }

    var nextWindowTitle: String {
        VitaminDWindowHeadline.nextWindowTitle(
            isOpenNow: isVitaminDWindowOpenNow,
            nextOpening: nextVitaminDWindowStart
        )
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
        vitaminDWindowStart: nil,
        vitaminDWindowEnd: nil,
        nextVitaminDWindowStart: nil,
        isVitaminDWindowOpenNow: false,
        todaySunIU: 0,
        targetIU: 1_000,
        isInBestWindow: false,
        isOnboardingComplete: false,
        activeSession: nil
    )
}

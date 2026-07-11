import Foundation

nonisolated struct BigDoseWidgetSnapshot: Codable, Sendable, Equatable {
    var generatedAt: Date
    var locationLabel: String
    var currentUVIndex: Double
    var peakUVIndex: Double
    var isWeatherLive: Bool
    var weatherObservedAt: Date?
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
    var todaySupplementIU: Double
    var targetIU: Int
    var totalDailyTargetIU: Int
    var includesSupplementsInDailyProgress: Bool
    var isInBestWindow: Bool
    var isOnboardingComplete: Bool
    var activeSession: ActiveSessionWidgetState?

    var todayGoalProgress: Double {
        let includesSupplements = includesSupplementsInDailyProgress
        let numerator = includesSupplements ? todaySunIU + todaySupplementIU : todaySunIU
        let denominator = includesSupplements
            ? Double(max(totalDailyTargetIU, 1))
            : Double(max(targetIU, 1))
        return min(max(numerator / denominator, 0), 1)
    }

    enum CodingKeys: String, CodingKey {
        case generatedAt
        case locationLabel
        case currentUVIndex
        case peakUVIndex
        case isWeatherLive
        case weatherObservedAt
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
        case todaySupplementIU
        case targetIU
        case totalDailyTargetIU
        case includesSupplementsInDailyProgress
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

    init(
        generatedAt: Date,
        locationLabel: String,
        currentUVIndex: Double,
        peakUVIndex: Double,
        isWeatherLive: Bool,
        weatherObservedAt: Date?,
        windowQualityTitle: String,
        bestWindowStart: Date?,
        bestWindowEnd: Date?,
        nextUsefulStart: Date?,
        nextUsefulEnd: Date?,
        vitaminDWindowStart: Date?,
        vitaminDWindowEnd: Date?,
        nextVitaminDWindowStart: Date?,
        isVitaminDWindowOpenNow: Bool,
        todaySunIU: Double,
        todaySupplementIU: Double = 0,
        targetIU: Int,
        totalDailyTargetIU: Int? = nil,
        includesSupplementsInDailyProgress: Bool = true,
        isInBestWindow: Bool,
        isOnboardingComplete: Bool,
        activeSession: ActiveSessionWidgetState?
    ) {
        self.generatedAt = generatedAt
        self.locationLabel = locationLabel
        self.currentUVIndex = currentUVIndex
        self.peakUVIndex = peakUVIndex
        self.isWeatherLive = isWeatherLive
        self.weatherObservedAt = weatherObservedAt
        self.windowQualityTitle = windowQualityTitle
        self.bestWindowStart = bestWindowStart
        self.bestWindowEnd = bestWindowEnd
        self.nextUsefulStart = nextUsefulStart
        self.nextUsefulEnd = nextUsefulEnd
        self.vitaminDWindowStart = vitaminDWindowStart
        self.vitaminDWindowEnd = vitaminDWindowEnd
        self.nextVitaminDWindowStart = nextVitaminDWindowStart
        self.isVitaminDWindowOpenNow = isVitaminDWindowOpenNow
        self.todaySunIU = todaySunIU
        self.todaySupplementIU = todaySupplementIU
        self.targetIU = targetIU
        self.totalDailyTargetIU = totalDailyTargetIU ?? targetIU
        self.includesSupplementsInDailyProgress = includesSupplementsInDailyProgress
        self.isInBestWindow = isInBestWindow
        self.isOnboardingComplete = isOnboardingComplete
        self.activeSession = activeSession
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        generatedAt = try container.decode(Date.self, forKey: .generatedAt)
        locationLabel = try container.decode(String.self, forKey: .locationLabel)
        currentUVIndex = try container.decode(Double.self, forKey: .currentUVIndex)
        peakUVIndex = try container.decode(Double.self, forKey: .peakUVIndex)
        isWeatherLive = try container.decodeIfPresent(Bool.self, forKey: .isWeatherLive) ?? false
        weatherObservedAt = try container.decodeIfPresent(Date.self, forKey: .weatherObservedAt)
        windowQualityTitle = try container.decode(String.self, forKey: .windowQualityTitle)
        bestWindowStart = try container.decodeIfPresent(Date.self, forKey: .bestWindowStart)
        bestWindowEnd = try container.decodeIfPresent(Date.self, forKey: .bestWindowEnd)
        nextUsefulStart = try container.decodeIfPresent(Date.self, forKey: .nextUsefulStart)
        nextUsefulEnd = try container.decodeIfPresent(Date.self, forKey: .nextUsefulEnd)
        vitaminDWindowStart = try container.decodeIfPresent(Date.self, forKey: .vitaminDWindowStart)
        vitaminDWindowEnd = try container.decodeIfPresent(Date.self, forKey: .vitaminDWindowEnd)
        nextVitaminDWindowStart = try container.decodeIfPresent(Date.self, forKey: .nextVitaminDWindowStart)
        isVitaminDWindowOpenNow = try container.decode(Bool.self, forKey: .isVitaminDWindowOpenNow)
        todaySunIU = try container.decode(Double.self, forKey: .todaySunIU)
        todaySupplementIU = try container.decodeIfPresent(Double.self, forKey: .todaySupplementIU) ?? 0
        targetIU = try container.decode(Int.self, forKey: .targetIU)
        totalDailyTargetIU = try container.decodeIfPresent(Int.self, forKey: .totalDailyTargetIU) ?? targetIU
        includesSupplementsInDailyProgress = try container.decodeIfPresent(Bool.self, forKey: .includesSupplementsInDailyProgress) ?? true
        isInBestWindow = try container.decode(Bool.self, forKey: .isInBestWindow)
        isOnboardingComplete = try container.decode(Bool.self, forKey: .isOnboardingComplete)
        activeSession = try container.decodeIfPresent(ActiveSessionWidgetState.self, forKey: .activeSession)
    }

    static let placeholder = BigDoseWidgetSnapshot(
        generatedAt: .now,
        locationLabel: "BigDose",
        currentUVIndex: 0,
        peakUVIndex: 0,
        isWeatherLive: false,
        weatherObservedAt: nil,
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
        todaySupplementIU: 0,
        targetIU: 1_000,
        totalDailyTargetIU: 1_000,
        includesSupplementsInDailyProgress: true,
        isInBestWindow: false,
        isOnboardingComplete: false,
        activeSession: nil
    )
}

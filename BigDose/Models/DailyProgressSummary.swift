import Foundation
import SwiftData

@Model
final class DailyProgressSummary {
    #Index<DailyProgressSummary>([\.date])

    var date: Date
    var sunIU: Double
    var supplementIU: Double
    var foodIU: Double
    var targetIU: Double
    var sufficientDay: Bool
    var streakCount: Int

    init(
        date: Date = .now,
        sunIU: Double = 0,
        supplementIU: Double = 0,
        foodIU: Double = 0,
        targetIU: Double = 1_000,
        sufficientDay: Bool = false,
        streakCount: Int = 0
    ) {
        self.date = date
        self.sunIU = sunIU
        self.supplementIU = supplementIU
        self.foodIU = foodIU
        self.targetIU = targetIU
        self.sufficientDay = sufficientDay
        self.streakCount = streakCount
    }
}

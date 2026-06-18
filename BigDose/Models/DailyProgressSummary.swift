import Foundation
import SwiftData

@Model
final class DailyProgressSummary {
    #Index<DailyProgressSummary>([\.date])

    var date: Date = Date.now
    var sunIU: Double = 0
    var supplementIU: Double = 0
    var foodIU: Double = 0
    var targetIU: Double = 1_000
    var sufficientDay: Bool = false
    var streakCount: Int = 0

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

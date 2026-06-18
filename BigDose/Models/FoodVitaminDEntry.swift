import Foundation
import SwiftData

@Model
final class FoodVitaminDEntry {
    #Index<FoodVitaminDEntry>([\.loggedAt])

    var loggedAt: Date = Date.now
    var foodName: String = ""
    var estimatedIU: Int = 0

    init(loggedAt: Date = .now, foodName: String = "", estimatedIU: Int = 0) {
        self.loggedAt = loggedAt
        self.foodName = foodName
        self.estimatedIU = estimatedIU
    }
}

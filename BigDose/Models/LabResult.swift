import Foundation
import SwiftData

@Model
final class LabResult {
    #Index<LabResult>([\.measuredAt])

    var measuredAt: Date
    var nanogramsPerMilliliter: Double
    var note: String

    init(measuredAt: Date = .now, nanogramsPerMilliliter: Double = 30, note: String = "") {
        self.measuredAt = measuredAt
        self.nanogramsPerMilliliter = nanogramsPerMilliliter
        self.note = note
    }
}

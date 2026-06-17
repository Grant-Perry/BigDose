import Foundation
import SwiftData

@Model
final class SupplementDose {
    #Index<SupplementDose>([\.takenAt])

    var takenAt: Date
    var internationalUnits: Int
    var note: String

    init(takenAt: Date = .now, internationalUnits: Int = 1_000, note: String = "") {
        self.takenAt = takenAt
        self.internationalUnits = internationalUnits
        self.note = note
    }
}

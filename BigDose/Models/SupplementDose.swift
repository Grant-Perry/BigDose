import Foundation
import SwiftData

@Model
final class SupplementDose {
    #Index<SupplementDose>([\.takenAt])

    var takenAt: Date
    var internationalUnits: Int
    var note: String
    var source: DataRecordSource
    var externalIdentifier: String?

    init(
        takenAt: Date = .now,
        internationalUnits: Int = 1_000,
        note: String = "",
        source: DataRecordSource = .manual,
        externalIdentifier: String? = nil
    ) {
        self.takenAt = takenAt
        self.internationalUnits = internationalUnits
        self.note = note
        self.source = source
        self.externalIdentifier = externalIdentifier
    }
}

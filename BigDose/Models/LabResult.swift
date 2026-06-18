import Foundation
import SwiftData

@Model
final class LabResult {
    #Index<LabResult>([\.measuredAt])

    var measuredAt: Date
    var nanogramsPerMilliliter: Double
    var note: String
    var source: DataRecordSource
    var externalIdentifier: String?

    init(
        measuredAt: Date = .now,
        nanogramsPerMilliliter: Double = 30,
        note: String = "",
        source: DataRecordSource = .manual,
        externalIdentifier: String? = nil
    ) {
        self.measuredAt = measuredAt
        self.nanogramsPerMilliliter = nanogramsPerMilliliter
        self.note = note
        self.source = source
        self.externalIdentifier = externalIdentifier
    }
}

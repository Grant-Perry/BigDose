import Foundation
import SwiftData

@Model
final class LabResult {
    #Index<LabResult>([\.measuredAt])

    var measuredAt: Date = Date.now
    var nanogramsPerMilliliter: Double = 30
    var note: String = ""
    var source: DataRecordSource = DataRecordSource.manual
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

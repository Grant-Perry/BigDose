import Foundation
import SwiftData

@Model
final class HealthImportBatch {
    #Index<HealthImportBatch>([\.importedAt], [\.startDate], [\.endDate])

    var importedAt: Date
    var startDate: Date
    var endDate: Date
    var source: DataRecordSource
    var workoutCount: Int
    var acceptedExposureCount: Int
    var skippedCount: Int
    var note: String

    init(
        importedAt: Date = .now,
        startDate: Date,
        endDate: Date,
        source: DataRecordSource = .healthKit,
        workoutCount: Int = 0,
        acceptedExposureCount: Int = 0,
        skippedCount: Int = 0,
        note: String = ""
    ) {
        self.importedAt = importedAt
        self.startDate = startDate
        self.endDate = endDate
        self.source = source
        self.workoutCount = workoutCount
        self.acceptedExposureCount = acceptedExposureCount
        self.skippedCount = skippedCount
        self.note = note
    }
}

import Foundation
import SwiftData

@Model
final class HealthImportBatch {
    #Index<HealthImportBatch>([\.importedAt], [\.startDate], [\.endDate])

    var importedAt: Date = Date.now
    var startDate: Date = Date.now
    var endDate: Date = Date.now
    var source: DataRecordSource = DataRecordSource.healthKit
    var workoutCount: Int = 0
    var acceptedExposureCount: Int = 0
    var skippedCount: Int = 0
    var note: String = ""

    init(
        importedAt: Date = .now,
        startDate: Date = .now,
        endDate: Date = .now,
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

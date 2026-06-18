import Foundation
import SwiftData

@Model
final class HealthImportItem {
    #Index<HealthImportItem>([\.startedAt], [\.externalIdentifier])

    var externalIdentifier: String
    var batchImportedAt: Date
    var startedAt: Date
    var endedAt: Date
    var activityName: String
    var durationSeconds: TimeInterval
    var wasAcceptedForExposure: Bool
    var confidence: Double
    var note: String

    init(
        externalIdentifier: String,
        batchImportedAt: Date = .now,
        startedAt: Date,
        endedAt: Date,
        activityName: String,
        durationSeconds: TimeInterval,
        wasAcceptedForExposure: Bool = false,
        confidence: Double = 0,
        note: String = ""
    ) {
        self.externalIdentifier = externalIdentifier
        self.batchImportedAt = batchImportedAt
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.activityName = activityName
        self.durationSeconds = durationSeconds
        self.wasAcceptedForExposure = wasAcceptedForExposure
        self.confidence = confidence
        self.note = note
    }
}

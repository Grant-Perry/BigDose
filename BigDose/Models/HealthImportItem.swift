import Foundation
import SwiftData

@Model
final class HealthImportItem {
    #Index<HealthImportItem>([\.startedAt], [\.externalIdentifier])

    var externalIdentifier: String = ""
    var batchImportedAt: Date = Date.now
    var startedAt: Date = Date.now
    var endedAt: Date = Date.now
    var activityName: String = ""
    var durationSeconds: TimeInterval = 0
    var wasAcceptedForExposure: Bool = false
    var confidence: Double = 0
    var note: String = ""

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

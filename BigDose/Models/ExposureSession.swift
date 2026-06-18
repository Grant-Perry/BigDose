import Foundation
import SwiftData

@Model
final class ExposureSession {
    #Index<ExposureSession>([\.startedAt], [\.endedAt])

    var startedAt: Date = Date.now
    var endedAt: Date = Date.now
    var durationSeconds: TimeInterval = 0
    var averageUVIndex: Double = 0
    var maxUVIndex: Double = 0
    var estimatedIU: Double = 0
    var exposedBodySurfaceArea: Double = 0.25
    var sunscreenFactor: Double = 1
    var source: ExposureSource = ExposureSource.manual
    var quality: SunWindowQuality = SunWindowQuality.low
    var locationLabel: String?
    var latitude: Double?
    var longitude: Double?
    var externalIdentifier: String?
    var importBatchImportedAt: Date?
    var sourceAppName: String?
    var confidence: Double = 1
    var note: String = ""

    init(
        startedAt: Date = .now,
        endedAt: Date = .now,
        durationSeconds: TimeInterval = 0,
        averageUVIndex: Double = 0,
        maxUVIndex: Double = 0,
        estimatedIU: Double = 0,
        exposedBodySurfaceArea: Double = 0.25,
        sunscreenFactor: Double = 1,
        source: ExposureSource = .manual,
        quality: SunWindowQuality = .low,
        locationLabel: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        externalIdentifier: String? = nil,
        importBatchImportedAt: Date? = nil,
        sourceAppName: String? = nil,
        confidence: Double = 1,
        note: String = ""
    ) {
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationSeconds = durationSeconds
        self.averageUVIndex = averageUVIndex
        self.maxUVIndex = maxUVIndex
        self.estimatedIU = estimatedIU
        self.exposedBodySurfaceArea = exposedBodySurfaceArea
        self.sunscreenFactor = sunscreenFactor
        self.source = source
        self.quality = quality
        self.locationLabel = locationLabel
        self.latitude = latitude
        self.longitude = longitude
        self.externalIdentifier = externalIdentifier
        self.importBatchImportedAt = importBatchImportedAt
        self.sourceAppName = sourceAppName
        self.confidence = confidence
        self.note = note
    }
}

extension ExposureSession {
    var historySourceTitle: String {
        guard let sourceAppName else {
            return source.title
        }

        let trimmed = sourceAppName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? source.title : trimmed
    }
}

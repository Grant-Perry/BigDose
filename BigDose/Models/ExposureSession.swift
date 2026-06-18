import Foundation
import SwiftData

@Model
final class ExposureSession {
    #Index<ExposureSession>([\.startedAt], [\.endedAt])

    var startedAt: Date
    var endedAt: Date
    var durationSeconds: TimeInterval
    var averageUVIndex: Double
    var maxUVIndex: Double
    var estimatedIU: Double
    var exposedBodySurfaceArea: Double
    var sunscreenFactor: Double
    var source: ExposureSource
    var quality: SunWindowQuality
    var locationLabel: String?
    var latitude: Double?
    var longitude: Double?
    var externalIdentifier: String?
    var importBatchImportedAt: Date?
    var confidence: Double
    var note: String

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
        self.confidence = confidence
        self.note = note
    }
}

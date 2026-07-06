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
    var peakMedUsedPercent: Int = 0
    var medOverLimitPercent: Int = 0
    var cloudCoverRaw: String = CloudCoverPreset.clear.rawValue
    var skinTypeRaw: String = ""
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
    var sessionTargetIU: Double = 0

    init(
        startedAt: Date = .now,
        endedAt: Date = .now,
        durationSeconds: TimeInterval = 0,
        averageUVIndex: Double = 0,
        maxUVIndex: Double = 0,
        estimatedIU: Double = 0,
        peakMedUsedPercent: Int = 0,
        medOverLimitPercent: Int = 0,
        cloudCoverRaw: String = CloudCoverPreset.clear.rawValue,
        skinTypeRaw: String = "",
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
        note: String = "",
        sessionTargetIU: Double = 0
    ) {
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationSeconds = durationSeconds
        self.averageUVIndex = averageUVIndex
        self.maxUVIndex = maxUVIndex
        self.estimatedIU = estimatedIU
        self.peakMedUsedPercent = peakMedUsedPercent
        self.medOverLimitPercent = medOverLimitPercent
        self.cloudCoverRaw = cloudCoverRaw
        self.skinTypeRaw = skinTypeRaw
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
        self.sessionTargetIU = sessionTargetIU
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

    var showsHolickEstimate: Bool {
        source == .healthKit || source == .healthKitDaylight
    }

    var historyIUText: String {
        let value = Int(estimatedIU.rounded())
        return showsHolickEstimate ? "~\(value)" : "\(value)"
    }

    var historySubtitle: String? {
        switch source {
        case .healthKitDaylight:
            let minutes = Int((durationSeconds / 60).rounded())
            return "\(minutes) min incidental · Holick est."
        case .healthKit:
            return "Holick est. · assumed UV"
        default:
            return nil
        }
    }

    var trackedSessionDetail: String? {
        guard source == .liveTracked else { return nil }

        let duration = SunSessionDurationFormatting.compact(durationSeconds)
        if medOverLimitPercent > 0 {
            return "\(duration) · \(peakMedUsedPercent)% MED · +\(medOverLimitPercent)% past 100%"
        }

        return "\(duration) · \(peakMedUsedPercent)% MED (burn risk) used"
    }

    func resolvedSessionTargetIU(profile: UserProfile) -> Double {
        sessionTargetIU > 0 ? sessionTargetIU : Double(profile.preferredDailyIU)
    }

    func historyTimestamp(calendar: Calendar = .current) -> String {
        if source == .healthKitDaylight {
            if calendar.isDateInToday(startedAt) {
                return "Today · daily total"
            }

            if calendar.isDateInYesterday(startedAt) {
                return "Yesterday · daily total"
            }

            return "\(startedAt.formatted(date: .abbreviated, time: .omitted)) · daily total"
        }

        if calendar.isDateInToday(startedAt) {
            return "Today, \(startedAt.formatted(date: .omitted, time: .shortened))"
        }

        if calendar.isDateInYesterday(startedAt) {
            return "Yesterday, \(startedAt.formatted(date: .omitted, time: .shortened))"
        }

        return startedAt.formatted(date: .abbreviated, time: .shortened)
    }
}

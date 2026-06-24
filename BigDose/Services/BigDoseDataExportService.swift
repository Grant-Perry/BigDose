import Foundation
import SwiftData

struct BigDoseExportPayload: Codable {
    var schemaVersion: Int
    var exportedAt: Date
    var profiles: [ProfileDTO]
    var sessions: [ExposureSessionDTO]
    var supplements: [SupplementDoseDTO]
    var labs: [LabResultDTO]
    var foods: [FoodEntryDTO]
    var dailyPlans: [DailySunPlanDTO]
    var healthImportBatches: [HealthImportBatchDTO]
    var healthImportItems: [HealthImportItemDTO]
}

enum BigDoseDataExportService {
    static let schemaVersion = 1

    @MainActor
    static func makePayload(
        profiles: [UserProfile],
        sessions: [ExposureSession],
        supplements: [SupplementDose],
        labs: [LabResult],
        foods: [FoodVitaminDEntry],
        dailyPlans: [DailySunPlan],
        healthImportBatches: [HealthImportBatch],
        healthImportItems: [HealthImportItem]
    ) -> BigDoseExportPayload {
        BigDoseExportPayload(
            schemaVersion: schemaVersion,
            exportedAt: .now,
            profiles: profiles.map(ProfileDTO.init),
            sessions: sessions.map(ExposureSessionDTO.init),
            supplements: supplements.map(SupplementDoseDTO.init),
            labs: labs.map(LabResultDTO.init),
            foods: foods.map(FoodEntryDTO.init),
            dailyPlans: dailyPlans.map(DailySunPlanDTO.init),
            healthImportBatches: healthImportBatches.map(HealthImportBatchDTO.init),
            healthImportItems: healthImportItems.map(HealthImportItemDTO.init)
        )
    }

    static func writeTemporaryExport(_ payload: BigDoseExportPayload) throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(payload)
        let fileName = "BigDose-Export-\(Self.fileDateFormatter.string(from: payload.exportedAt)).json"
        let url = FileManager.default.temporaryDirectory.appending(path: fileName)
        try data.write(to: url, options: .atomic)
        return url
    }

    static func decodePayload(from url: URL) throws -> BigDoseExportPayload {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(BigDoseExportPayload.self, from: data)
    }

    @MainActor
    static func restore(_ payload: BigDoseExportPayload, into modelContext: ModelContext) {
        for dto in payload.labs {
            modelContext.insert(dto.model)
        }
        for dto in payload.supplements {
            modelContext.insert(dto.model)
        }
        for dto in payload.sessions {
            modelContext.insert(dto.model)
        }
        for dto in payload.foods {
            modelContext.insert(dto.model)
        }
        for dto in payload.dailyPlans {
            modelContext.insert(dto.model)
        }
        for dto in payload.healthImportBatches {
            modelContext.insert(dto.model)
        }
        for dto in payload.healthImportItems {
            modelContext.insert(dto.model)
        }
        try? modelContext.save()
    }

    private static let fileDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()
}

struct ProfileDTO: Codable {
    var displayName: String
    var skinType: FitzpatrickSkinType
    var goalNanogramsPerMilliliter: Double
    var baselineNanogramsPerMilliliter: Double?
    var preferredDailyIU: Int

    init(_ profile: UserProfile) {
        displayName = profile.displayName
        skinType = profile.skinType
        goalNanogramsPerMilliliter = profile.goalNanogramsPerMilliliter
        baselineNanogramsPerMilliliter = profile.baselineNanogramsPerMilliliter
        preferredDailyIU = profile.preferredDailyIU
    }
}

struct ExposureSessionDTO: Codable {
    var startedAt: Date
    var endedAt: Date
    var durationSeconds: TimeInterval
    var averageUVIndex: Double
    var maxUVIndex: Double
    var estimatedIU: Double
    var peakMedUsedPercent: Int
    var medOverLimitPercent: Int
    var cloudCoverRaw: String
    var skinTypeRaw: String
    var exposedBodySurfaceArea: Double
    var sunscreenFactor: Double
    var source: ExposureSource
    var quality: SunWindowQuality
    var locationLabel: String?
    var externalIdentifier: String?
    var confidence: Double
    var note: String

    init(_ model: ExposureSession) {
        startedAt = model.startedAt
        endedAt = model.endedAt
        durationSeconds = model.durationSeconds
        averageUVIndex = model.averageUVIndex
        maxUVIndex = model.maxUVIndex
        estimatedIU = model.estimatedIU
        peakMedUsedPercent = model.peakMedUsedPercent
        medOverLimitPercent = model.medOverLimitPercent
        cloudCoverRaw = model.cloudCoverRaw
        skinTypeRaw = model.skinTypeRaw
        exposedBodySurfaceArea = model.exposedBodySurfaceArea
        sunscreenFactor = model.sunscreenFactor
        source = model.source
        quality = model.quality
        locationLabel = model.locationLabel
        externalIdentifier = model.externalIdentifier
        confidence = model.confidence
        note = model.note
    }

    var model: ExposureSession {
        ExposureSession(
            startedAt: startedAt,
            endedAt: endedAt,
            durationSeconds: durationSeconds,
            averageUVIndex: averageUVIndex,
            maxUVIndex: maxUVIndex,
            estimatedIU: estimatedIU,
            peakMedUsedPercent: peakMedUsedPercent,
            medOverLimitPercent: medOverLimitPercent,
            cloudCoverRaw: cloudCoverRaw,
            skinTypeRaw: skinTypeRaw,
            exposedBodySurfaceArea: exposedBodySurfaceArea,
            sunscreenFactor: sunscreenFactor,
            source: source,
            quality: quality,
            locationLabel: locationLabel,
            externalIdentifier: externalIdentifier,
            confidence: confidence,
            note: note
        )
    }
}

struct SupplementDoseDTO: Codable {
    var takenAt: Date
    var internationalUnits: Int
    var note: String

    init(_ model: SupplementDose) {
        takenAt = model.takenAt
        internationalUnits = model.internationalUnits
        note = model.note
    }

    var model: SupplementDose {
        SupplementDose(takenAt: takenAt, internationalUnits: internationalUnits, note: note, source: .rescueFile)
    }
}

struct LabResultDTO: Codable {
    var measuredAt: Date
    var nanogramsPerMilliliter: Double
    var note: String

    init(_ model: LabResult) {
        measuredAt = model.measuredAt
        nanogramsPerMilliliter = model.nanogramsPerMilliliter
        note = model.note
    }

    var model: LabResult {
        LabResult(measuredAt: measuredAt, nanogramsPerMilliliter: nanogramsPerMilliliter, note: note, source: .rescueFile)
    }
}

struct FoodEntryDTO: Codable {
    var loggedAt: Date
    var foodName: String
    var estimatedIU: Int

    init(_ model: FoodVitaminDEntry) {
        loggedAt = model.loggedAt
        foodName = model.foodName
        estimatedIU = model.estimatedIU
    }

    var model: FoodVitaminDEntry {
        FoodVitaminDEntry(loggedAt: loggedAt, foodName: foodName, estimatedIU: estimatedIU)
    }
}

struct DailySunPlanDTO: Codable {
    var date: Date
    var generatedAt: Date
    var locationLabel: String
    var estimatedIU: Double
    var peakUVIndex: Double
    var quality: SunWindowQuality

    init(_ model: DailySunPlan) {
        date = model.date
        generatedAt = model.generatedAt
        locationLabel = model.locationLabel
        estimatedIU = model.estimatedIU
        peakUVIndex = model.peakUVIndex
        quality = model.quality
    }

    var model: DailySunPlan {
        DailySunPlan(date: date, generatedAt: generatedAt, locationLabel: locationLabel, estimatedIU: estimatedIU, peakUVIndex: peakUVIndex, quality: quality)
    }
}

struct HealthImportBatchDTO: Codable {
    var importedAt: Date
    var startDate: Date
    var endDate: Date
    var workoutCount: Int
    var acceptedExposureCount: Int
    var skippedCount: Int
    var note: String

    init(_ model: HealthImportBatch) {
        importedAt = model.importedAt
        startDate = model.startDate
        endDate = model.endDate
        workoutCount = model.workoutCount
        acceptedExposureCount = model.acceptedExposureCount
        skippedCount = model.skippedCount
        note = model.note
    }

    var model: HealthImportBatch {
        HealthImportBatch(importedAt: importedAt, startDate: startDate, endDate: endDate, workoutCount: workoutCount, acceptedExposureCount: acceptedExposureCount, skippedCount: skippedCount, note: note)
    }
}

struct HealthImportItemDTO: Codable {
    var externalIdentifier: String
    var batchImportedAt: Date
    var startedAt: Date
    var endedAt: Date
    var activityName: String
    var durationSeconds: TimeInterval
    var wasAcceptedForExposure: Bool
    var confidence: Double
    var note: String

    init(_ model: HealthImportItem) {
        externalIdentifier = model.externalIdentifier
        batchImportedAt = model.batchImportedAt
        startedAt = model.startedAt
        endedAt = model.endedAt
        activityName = model.activityName
        durationSeconds = model.durationSeconds
        wasAcceptedForExposure = model.wasAcceptedForExposure
        confidence = model.confidence
        note = model.note
    }

    var model: HealthImportItem {
        HealthImportItem(externalIdentifier: externalIdentifier, batchImportedAt: batchImportedAt, startedAt: startedAt, endedAt: endedAt, activityName: activityName, durationSeconds: durationSeconds, wasAcceptedForExposure: wasAcceptedForExposure, confidence: confidence, note: note)
    }
}

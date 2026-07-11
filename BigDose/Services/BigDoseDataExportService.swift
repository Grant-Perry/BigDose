import Foundation
import SwiftData

private func restoredDateMatches(_ lhs: Date, _ rhs: Date) -> Bool {
    abs(lhs.timeIntervalSince(rhs)) < 1
}

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
    static let schemaVersion = 2

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
        let payload = try decoder.decode(BigDoseExportPayload.self, from: data)
        guard payload.schemaVersion <= schemaVersion else {
            throw BigDoseDataExportError.unsupportedSchema(payload.schemaVersion)
        }
        return payload
    }

    @MainActor
    static func restore(_ payload: BigDoseExportPayload, into modelContext: ModelContext) throws {
        let profiles = try modelContext.fetch(FetchDescriptor<UserProfile>())
        if let dto = payload.profiles.max(by: { ($0.updatedAt ?? .distantPast) < ($1.updatedAt ?? .distantPast) }) {
            if let profile = UserProfile.canonical(from: profiles) {
                dto.apply(to: profile, schemaVersion: payload.schemaVersion)
            } else {
                let profile = UserProfile()
                dto.apply(to: profile, schemaVersion: payload.schemaVersion)
                modelContext.insert(profile)
            }
        }

        var existingLabs = try modelContext.fetch(FetchDescriptor<LabResult>())
        for dto in payload.labs where !existingLabs.contains(where: { dto.matches($0) }) {
            let model = dto.model
            modelContext.insert(model)
            existingLabs.append(model)
        }

        var existingSupplements = try modelContext.fetch(FetchDescriptor<SupplementDose>())
        for dto in payload.supplements where !existingSupplements.contains(where: { dto.matches($0) }) {
            let model = dto.model
            modelContext.insert(model)
            existingSupplements.append(model)
        }

        var existingSessions = try modelContext.fetch(FetchDescriptor<ExposureSession>())
        for dto in payload.sessions where !existingSessions.contains(where: { dto.matches($0) }) {
            let model = dto.model
            modelContext.insert(model)
            existingSessions.append(model)
        }

        var existingFoods = try modelContext.fetch(FetchDescriptor<FoodVitaminDEntry>())
        for dto in payload.foods where !existingFoods.contains(where: { dto.matches($0) }) {
            let model = dto.model
            modelContext.insert(model)
            existingFoods.append(model)
        }

        var existingPlans = try modelContext.fetch(FetchDescriptor<DailySunPlan>())
        for dto in payload.dailyPlans {
            if let existing = existingPlans.first(where: { Calendar.current.isDate($0.date, inSameDayAs: dto.date) }) {
                dto.apply(to: existing)
            } else {
                let plan = dto.model
                modelContext.insert(plan)
                existingPlans.append(plan)
            }
        }

        var existingBatches = try modelContext.fetch(FetchDescriptor<HealthImportBatch>())
        for dto in payload.healthImportBatches where !existingBatches.contains(where: { dto.matches($0) }) {
            let model = dto.model
            modelContext.insert(model)
            existingBatches.append(model)
        }

        var existingItems = try modelContext.fetch(FetchDescriptor<HealthImportItem>())
        for dto in payload.healthImportItems where !existingItems.contains(where: { dto.matches($0) }) {
            let model = dto.model
            modelContext.insert(model)
            existingItems.append(model)
        }

        try modelContext.save()
    }

    private static let fileDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()
}

enum BigDoseDataExportError: LocalizedError {
    case unsupportedSchema(Int)

    var errorDescription: String? {
        switch self {
        case .unsupportedSchema(let version):
            "This rescue file uses unsupported schema version \(version). Update BigDose and try again."
        }
    }
}

struct ProfileDTO: Codable {
    var displayName: String
    var skinType: FitzpatrickSkinType
    var goalNanogramsPerMilliliter: Double
    var baselineNanogramsPerMilliliter: Double?
    var preferredDailyIU: Int
    var createdAt: Date?
    var updatedAt: Date?
    var isOnboardingComplete: Bool?
    var avatarImageData: Data?
    var biologicalSex: BiologicalSex?
    var dateOfBirth: Date?
    var heightCentimeters: Double?
    var weightKilograms: Double?
    var typicalExposedBodySurfaceArea: Double?
    var usuallyUsesSunscreen: Bool?
    var wantsWindowReminders: Bool?
    var wantsRiskAlerts: Bool?
    var wantsActiveSessionReminders: Bool?
    var wantsNannyMode: Bool?
    var levelKnowledge: VitaminDLevelKnowledge?
    var incidentalSunMinutesPerWeek: Int?
    var defaultSupplementIU: Int?
    var autoApplyDailySupplementIU: Bool?
    var includesSupplementsInDailyProgress: Bool?
    var wantsSolarWindowAlerts: Bool?
    var wantsDWindowOpeningAlerts: Bool?
    var wantsDWindowClosingAlerts: Bool?
    var wantsSolarNoonAlerts: Bool?
    var wantsSunriseSunsetAlerts: Bool?
    var wantsAMLightWindowAlerts: Bool?
    var wantsNextDOpportunityAlerts: Bool?
    var wantsSupplementReminders: Bool?
    var wantsLabReminders: Bool?
    var wantsWeeklyProgressAlerts: Bool?
    var wantsLevelTrendAlerts: Bool?
    var wantsMilestoneAlerts: Bool?
    var wantsWeatherBreakAlerts: Bool?
    var quietHoursEnabled: Bool?
    var quietHoursStartHour: Int?
    var quietHoursEndHour: Int?
    var supplementReminderHour: Int?
    var supplementReminderMinute: Int?
    var labReminderIntervalDays: Int?
    var lastHealthKitImportAt: Date?
    var lastHealthKitAutoSyncAt: Date?
    var healthKitImportStatus: HealthImportStatus?
    var wantsHealthKitSync: Bool?
    var wantsHealthKitSupplementExport: Bool?
    var hasAcceptedWellnessDisclaimer: Bool?
    var prepareExitLeadPercent: Int?

    init(_ profile: UserProfile) {
        displayName = profile.displayName
        skinType = profile.skinType
        goalNanogramsPerMilliliter = profile.goalNanogramsPerMilliliter
        baselineNanogramsPerMilliliter = profile.baselineNanogramsPerMilliliter
        preferredDailyIU = profile.preferredDailyIU
        createdAt = profile.createdAt
        updatedAt = profile.updatedAt
        isOnboardingComplete = profile.isOnboardingComplete
        avatarImageData = profile.avatarImageData
        biologicalSex = profile.biologicalSex
        dateOfBirth = profile.dateOfBirth
        heightCentimeters = profile.heightCentimeters
        weightKilograms = profile.weightKilograms
        typicalExposedBodySurfaceArea = profile.typicalExposedBodySurfaceArea
        usuallyUsesSunscreen = profile.usuallyUsesSunscreen
        wantsWindowReminders = profile.wantsWindowReminders
        wantsRiskAlerts = profile.wantsRiskAlerts
        wantsActiveSessionReminders = profile.wantsActiveSessionReminders
        wantsNannyMode = profile.wantsNannyMode
        levelKnowledge = profile.levelKnowledge
        incidentalSunMinutesPerWeek = profile.incidentalSunMinutesPerWeek
        defaultSupplementIU = profile.defaultSupplementIU
        autoApplyDailySupplementIU = profile.autoApplyDailySupplementIU
        includesSupplementsInDailyProgress = profile.includesSupplementsInDailyProgress
        wantsSolarWindowAlerts = profile.wantsSolarWindowAlerts
        wantsDWindowOpeningAlerts = profile.wantsDWindowOpeningAlerts
        wantsDWindowClosingAlerts = profile.wantsDWindowClosingAlerts
        wantsSolarNoonAlerts = profile.wantsSolarNoonAlerts
        wantsSunriseSunsetAlerts = profile.wantsSunriseSunsetAlerts
        wantsAMLightWindowAlerts = profile.wantsAMLightWindowAlerts
        wantsNextDOpportunityAlerts = profile.wantsNextDOpportunityAlerts
        wantsSupplementReminders = profile.wantsSupplementReminders
        wantsLabReminders = profile.wantsLabReminders
        wantsWeeklyProgressAlerts = profile.wantsWeeklyProgressAlerts
        wantsLevelTrendAlerts = profile.wantsLevelTrendAlerts
        wantsMilestoneAlerts = profile.wantsMilestoneAlerts
        wantsWeatherBreakAlerts = profile.wantsWeatherBreakAlerts
        quietHoursEnabled = profile.quietHoursEnabled
        quietHoursStartHour = profile.quietHoursStartHour
        quietHoursEndHour = profile.quietHoursEndHour
        supplementReminderHour = profile.supplementReminderHour
        supplementReminderMinute = profile.supplementReminderMinute
        labReminderIntervalDays = profile.labReminderIntervalDays
        lastHealthKitImportAt = profile.lastHealthKitImportAt
        lastHealthKitAutoSyncAt = profile.lastHealthKitAutoSyncAt
        healthKitImportStatus = profile.healthKitImportStatus
        wantsHealthKitSync = profile.wantsHealthKitSync
        wantsHealthKitSupplementExport = profile.wantsHealthKitSupplementExport
        hasAcceptedWellnessDisclaimer = profile.hasAcceptedWellnessDisclaimer
        prepareExitLeadPercent = profile.prepareExitLeadPercent
    }

    @MainActor
    func apply(to profile: UserProfile, schemaVersion: Int) {
        profile.displayName = displayName
        profile.skinType = skinType
        profile.goalNanogramsPerMilliliter = goalNanogramsPerMilliliter
        profile.baselineNanogramsPerMilliliter = baselineNanogramsPerMilliliter
        profile.preferredDailyIU = preferredDailyIU

        guard schemaVersion >= 2 else { return }
        profile.createdAt = createdAt ?? profile.createdAt
        profile.updatedAt = updatedAt ?? profile.updatedAt
        profile.isOnboardingComplete = isOnboardingComplete ?? profile.isOnboardingComplete
        profile.avatarImageData = avatarImageData
        profile.biologicalSex = biologicalSex ?? profile.biologicalSex
        profile.dateOfBirth = dateOfBirth
        profile.heightCentimeters = heightCentimeters
        profile.weightKilograms = weightKilograms
        profile.typicalExposedBodySurfaceArea = typicalExposedBodySurfaceArea ?? profile.typicalExposedBodySurfaceArea
        profile.usuallyUsesSunscreen = usuallyUsesSunscreen ?? profile.usuallyUsesSunscreen
        profile.wantsWindowReminders = wantsWindowReminders ?? profile.wantsWindowReminders
        profile.wantsRiskAlerts = wantsRiskAlerts ?? profile.wantsRiskAlerts
        profile.wantsActiveSessionReminders = wantsActiveSessionReminders ?? profile.wantsActiveSessionReminders
        profile.wantsNannyMode = wantsNannyMode ?? profile.wantsNannyMode
        profile.levelKnowledge = levelKnowledge ?? profile.levelKnowledge
        profile.incidentalSunMinutesPerWeek = incidentalSunMinutesPerWeek ?? profile.incidentalSunMinutesPerWeek
        profile.defaultSupplementIU = defaultSupplementIU ?? profile.defaultSupplementIU
        profile.autoApplyDailySupplementIU = autoApplyDailySupplementIU ?? profile.autoApplyDailySupplementIU
        profile.includesSupplementsInDailyProgress = includesSupplementsInDailyProgress ?? profile.includesSupplementsInDailyProgress
        profile.wantsSolarWindowAlerts = wantsSolarWindowAlerts ?? profile.wantsSolarWindowAlerts
        profile.wantsDWindowOpeningAlerts = wantsDWindowOpeningAlerts ?? profile.wantsDWindowOpeningAlerts
        profile.wantsDWindowClosingAlerts = wantsDWindowClosingAlerts ?? profile.wantsDWindowClosingAlerts
        profile.wantsSolarNoonAlerts = wantsSolarNoonAlerts ?? profile.wantsSolarNoonAlerts
        profile.wantsSunriseSunsetAlerts = wantsSunriseSunsetAlerts ?? profile.wantsSunriseSunsetAlerts
        profile.wantsAMLightWindowAlerts = wantsAMLightWindowAlerts ?? profile.wantsAMLightWindowAlerts
        profile.wantsNextDOpportunityAlerts = wantsNextDOpportunityAlerts ?? profile.wantsNextDOpportunityAlerts
        profile.wantsSupplementReminders = wantsSupplementReminders ?? profile.wantsSupplementReminders
        profile.wantsLabReminders = wantsLabReminders ?? profile.wantsLabReminders
        profile.wantsWeeklyProgressAlerts = wantsWeeklyProgressAlerts ?? profile.wantsWeeklyProgressAlerts
        profile.wantsLevelTrendAlerts = wantsLevelTrendAlerts ?? profile.wantsLevelTrendAlerts
        profile.wantsMilestoneAlerts = wantsMilestoneAlerts ?? profile.wantsMilestoneAlerts
        profile.wantsWeatherBreakAlerts = wantsWeatherBreakAlerts ?? profile.wantsWeatherBreakAlerts
        profile.quietHoursEnabled = quietHoursEnabled ?? profile.quietHoursEnabled
        profile.quietHoursStartHour = quietHoursStartHour ?? profile.quietHoursStartHour
        profile.quietHoursEndHour = quietHoursEndHour ?? profile.quietHoursEndHour
        profile.supplementReminderHour = supplementReminderHour ?? profile.supplementReminderHour
        profile.supplementReminderMinute = supplementReminderMinute ?? profile.supplementReminderMinute
        profile.labReminderIntervalDays = labReminderIntervalDays ?? profile.labReminderIntervalDays
        profile.lastHealthKitImportAt = lastHealthKitImportAt
        profile.lastHealthKitAutoSyncAt = lastHealthKitAutoSyncAt
        profile.healthKitImportStatus = healthKitImportStatus ?? profile.healthKitImportStatus
        profile.wantsHealthKitSync = wantsHealthKitSync ?? profile.wantsHealthKitSync
        profile.wantsHealthKitSupplementExport = wantsHealthKitSupplementExport ?? profile.wantsHealthKitSupplementExport
        profile.hasAcceptedWellnessDisclaimer = hasAcceptedWellnessDisclaimer ?? profile.hasAcceptedWellnessDisclaimer
        profile.prepareExitLeadPercent = prepareExitLeadPercent ?? profile.prepareExitLeadPercent
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
    var latitude: Double?
    var longitude: Double?
    var importBatchImportedAt: Date?
    var sourceAppName: String?
    var sessionTargetIU: Double?

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
        latitude = model.latitude
        longitude = model.longitude
        importBatchImportedAt = model.importBatchImportedAt
        sourceAppName = model.sourceAppName
        sessionTargetIU = model.sessionTargetIU
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
            latitude: latitude,
            longitude: longitude,
            externalIdentifier: externalIdentifier,
            importBatchImportedAt: importBatchImportedAt,
            sourceAppName: sourceAppName,
            confidence: confidence,
            note: note,
            sessionTargetIU: sessionTargetIU ?? 0
        )
    }

    func matches(_ model: ExposureSession) -> Bool {
        if let externalIdentifier, let modelIdentifier = model.externalIdentifier {
            return externalIdentifier == modelIdentifier && source == model.source
        }
        return restoredDateMatches(startedAt, model.startedAt)
            && restoredDateMatches(endedAt, model.endedAt)
            && durationSeconds == model.durationSeconds
            && source == model.source
    }
}

struct SupplementDoseDTO: Codable {
    var takenAt: Date
    var internationalUnits: Int
    var note: String
    var source: DataRecordSource?
    var externalIdentifier: String?

    init(_ model: SupplementDose) {
        takenAt = model.takenAt
        internationalUnits = model.internationalUnits
        note = model.note
        source = model.source
        externalIdentifier = model.externalIdentifier
    }

    var model: SupplementDose {
        SupplementDose(
            takenAt: takenAt,
            internationalUnits: internationalUnits,
            note: note,
            source: source ?? .rescueFile,
            externalIdentifier: externalIdentifier
        )
    }

    func matches(_ model: SupplementDose) -> Bool {
        if let externalIdentifier, let modelIdentifier = model.externalIdentifier {
            return externalIdentifier == modelIdentifier
        }
        return restoredDateMatches(takenAt, model.takenAt)
            && internationalUnits == model.internationalUnits
            && note == model.note
    }
}

struct LabResultDTO: Codable {
    var measuredAt: Date
    var nanogramsPerMilliliter: Double
    var note: String
    var source: DataRecordSource?
    var externalIdentifier: String?

    init(_ model: LabResult) {
        measuredAt = model.measuredAt
        nanogramsPerMilliliter = model.nanogramsPerMilliliter
        note = model.note
        source = model.source
        externalIdentifier = model.externalIdentifier
    }

    var model: LabResult {
        LabResult(
            measuredAt: measuredAt,
            nanogramsPerMilliliter: nanogramsPerMilliliter,
            note: note,
            source: source ?? .rescueFile,
            externalIdentifier: externalIdentifier
        )
    }

    func matches(_ model: LabResult) -> Bool {
        if let externalIdentifier, let modelIdentifier = model.externalIdentifier {
            return externalIdentifier == modelIdentifier
        }
        return restoredDateMatches(measuredAt, model.measuredAt)
            && nanogramsPerMilliliter == model.nanogramsPerMilliliter
            && note == model.note
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

    func matches(_ model: FoodVitaminDEntry) -> Bool {
        restoredDateMatches(loggedAt, model.loggedAt)
            && foodName == model.foodName
            && estimatedIU == model.estimatedIU
    }
}

struct DailySunPlanDTO: Codable {
    var date: Date
    var generatedAt: Date
    var locationLabel: String
    var estimatedIU: Double
    var peakUVIndex: Double
    var quality: SunWindowQuality
    var latitude: Double?
    var longitude: Double?
    var sunrise: Date?
    var solarNoon: Date?
    var sunset: Date?
    var bestWindowStart: Date?
    var bestWindowEnd: Date?
    var vitaminDWindowStart: Date?
    var vitaminDWindowEnd: Date?
    var vitaminDWindowReferenceDay: Date?
    var solarNoonAltitudeDegrees: Double?
    var vitaminDThresholdDegrees: Double?
    var nextUsefulStart: Date?
    var nextUsefulEnd: Date?
    var targetIU: Int?
    var currentAltitudeDegrees: Double?
    var weatherAttribution: String?

    init(_ model: DailySunPlan) {
        date = model.date
        generatedAt = model.generatedAt
        locationLabel = model.locationLabel
        estimatedIU = model.estimatedIU
        peakUVIndex = model.peakUVIndex
        quality = model.quality
        latitude = model.latitude
        longitude = model.longitude
        sunrise = model.sunrise
        solarNoon = model.solarNoon
        sunset = model.sunset
        bestWindowStart = model.bestWindowStart
        bestWindowEnd = model.bestWindowEnd
        vitaminDWindowStart = model.vitaminDWindowStart
        vitaminDWindowEnd = model.vitaminDWindowEnd
        vitaminDWindowReferenceDay = model.vitaminDWindowReferenceDay
        solarNoonAltitudeDegrees = model.solarNoonAltitudeDegrees
        vitaminDThresholdDegrees = model.vitaminDThresholdDegrees
        nextUsefulStart = model.nextUsefulStart
        nextUsefulEnd = model.nextUsefulEnd
        targetIU = model.targetIU
        currentAltitudeDegrees = model.currentAltitudeDegrees
        weatherAttribution = model.weatherAttribution
    }

    var model: DailySunPlan {
        DailySunPlan(
            date: date,
            generatedAt: generatedAt,
            latitude: latitude ?? 0,
            longitude: longitude ?? 0,
            locationLabel: locationLabel,
            sunrise: sunrise,
            solarNoon: solarNoon,
            sunset: sunset,
            bestWindowStart: bestWindowStart,
            bestWindowEnd: bestWindowEnd,
            vitaminDWindowStart: vitaminDWindowStart,
            vitaminDWindowEnd: vitaminDWindowEnd,
            vitaminDWindowReferenceDay: vitaminDWindowReferenceDay,
            solarNoonAltitudeDegrees: solarNoonAltitudeDegrees ?? 0,
            vitaminDThresholdDegrees: vitaminDThresholdDegrees ?? SolarPosition.vitaminDSynthesisAltitudeDegrees,
            nextUsefulStart: nextUsefulStart,
            nextUsefulEnd: nextUsefulEnd,
            targetIU: targetIU ?? 1_000,
            estimatedIU: estimatedIU,
            peakUVIndex: peakUVIndex,
            currentAltitudeDegrees: currentAltitudeDegrees ?? 0,
            quality: quality,
            weatherAttribution: weatherAttribution
        )
    }

    func apply(to model: DailySunPlan) {
        let restored = self.model
        model.date = restored.date
        model.generatedAt = restored.generatedAt
        model.latitude = restored.latitude
        model.longitude = restored.longitude
        model.locationLabel = restored.locationLabel
        model.sunrise = restored.sunrise
        model.solarNoon = restored.solarNoon
        model.sunset = restored.sunset
        model.bestWindowStart = restored.bestWindowStart
        model.bestWindowEnd = restored.bestWindowEnd
        model.vitaminDWindowStart = restored.vitaminDWindowStart
        model.vitaminDWindowEnd = restored.vitaminDWindowEnd
        model.vitaminDWindowReferenceDay = restored.vitaminDWindowReferenceDay
        model.solarNoonAltitudeDegrees = restored.solarNoonAltitudeDegrees
        model.vitaminDThresholdDegrees = restored.vitaminDThresholdDegrees
        model.nextUsefulStart = restored.nextUsefulStart
        model.nextUsefulEnd = restored.nextUsefulEnd
        model.targetIU = restored.targetIU
        model.estimatedIU = restored.estimatedIU
        model.peakUVIndex = restored.peakUVIndex
        model.currentAltitudeDegrees = restored.currentAltitudeDegrees
        model.quality = restored.quality
        model.weatherAttribution = restored.weatherAttribution
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
    var source: DataRecordSource?
    var daylightDayCount: Int?

    init(_ model: HealthImportBatch) {
        importedAt = model.importedAt
        startDate = model.startDate
        endDate = model.endDate
        workoutCount = model.workoutCount
        acceptedExposureCount = model.acceptedExposureCount
        skippedCount = model.skippedCount
        note = model.note
        source = model.source
        daylightDayCount = model.daylightDayCount
    }

    var model: HealthImportBatch {
        HealthImportBatch(
            importedAt: importedAt,
            startDate: startDate,
            endDate: endDate,
            source: source ?? .rescueFile,
            workoutCount: workoutCount,
            acceptedExposureCount: acceptedExposureCount,
            skippedCount: skippedCount,
            daylightDayCount: daylightDayCount ?? 0,
            note: note
        )
    }

    func matches(_ model: HealthImportBatch) -> Bool {
        restoredDateMatches(importedAt, model.importedAt)
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

    func matches(_ model: HealthImportItem) -> Bool {
        externalIdentifier == model.externalIdentifier
            && restoredDateMatches(batchImportedAt, model.batchImportedAt)
    }
}

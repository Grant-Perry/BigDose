import Foundation
@preconcurrency import HealthKit
import SwiftData

struct HealthWorkoutImportCandidate: Identifiable, Sendable {
    var id: String
    var startedAt: Date
    var endedAt: Date
    var activityName: String
    var sourceAppName: String?
    var durationSeconds: TimeInterval
    var confidence: Double
    var shouldImport: Bool
    var note: String
}

struct HealthImportResult: Sendable {
    var importedAt: Date
    var workoutCount: Int
    var acceptedCount: Int
    var skippedCount: Int
    var daylightDayCount: Int
}

struct HealthProfileMetricUpdatePlan: Sendable {
    var heightCentimeters: Double?
    var weightKilograms: Double?

    var isEmpty: Bool {
        heightCentimeters == nil && weightKilograms == nil
    }

    var confirmationMessage: String {
        var parts: [String] = []

        if let heightCentimeters {
            let inches = Int((heightCentimeters / 2.54).rounded())
            parts.append("height (\(inches / 12)′\(inches % 12)″)")
        }

        if let weightKilograms {
            let pounds = Int((weightKilograms * 2.20462).rounded())
            parts.append("weight (\(pounds) lb)")
        }

        return "BigDose can update your \(parts.joined(separator: " and ")) in Apple Health."
    }
}

struct HealthProfileAutofill: Sendable {
    var dateOfBirth: Date?
    var biologicalSex: BiologicalSex?
    var heightCentimeters: Double?
    var weightKilograms: Double?
    var skinType: FitzpatrickSkinType?
    var suggestedDefaultSupplementIU: Int?

    var filledFields: [String] {
        var fields: [String] = []
        if dateOfBirth != nil { fields.append("date of birth") }
        if biologicalSex != nil { fields.append("biological sex") }
        if heightCentimeters != nil { fields.append("height") }
        if weightKilograms != nil { fields.append("weight") }
        if skinType != nil { fields.append("skin type") }
        if suggestedDefaultSupplementIU != nil { fields.append("default supplement") }
        return fields
    }

    var missingFields: [String] {
        var fields: [String] = []
        if dateOfBirth == nil { fields.append("date of birth") }
        if biologicalSex == nil { fields.append("biological sex") }
        if heightCentimeters == nil { fields.append("height") }
        if weightKilograms == nil { fields.append("weight") }
        if skinType == nil { fields.append("skin type") }
        return fields
    }
}

enum HealthKitImportError: LocalizedError {
    case unavailable
    case authorizationDenied
    case supplementTypeUnavailable

    var errorDescription: String? {
        switch self {
        case .unavailable:
            "Health data is not available on this device."
        case .authorizationDenied:
            "Apple Health permission was not granted."
        case .supplementTypeUnavailable:
            "Apple Health does not expose dietary vitamin D on this device."
        }
    }
}

@MainActor
final class HealthKitImportService {
    private let healthStore = HKHealthStore()

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async throws {
        try await requestOnboardingAuthorization()
    }

    func requestProfileAuthorization() async throws {
        try await requestOnboardingAuthorization()
    }

    func requestOnboardingAuthorization() async throws {
        guard isAvailable else { throw HealthKitImportError.unavailable }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.requestAuthorization(
                toShare: Self.onboardingShareTypes,
                read: Self.onboardingReadTypes
            ) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: HealthKitImportError.authorizationDenied)
                }
            }
        }
    }

    func fetchProfileAutofill() async throws -> HealthProfileAutofill {
        try await requestOnboardingAuthorization()

        let dateOfBirthComponents = try? healthStore.dateOfBirthComponents()
        let dateOfBirth = dateOfBirthComponents.flatMap { Calendar.current.date(from: $0) }
        let biologicalSex = try? healthStore.biologicalSex().biologicalSex.bigDoseSex
        let skinType = try? healthStore.fitzpatrickSkinType().skinType.bigDoseSkinType
        let height = try await latestQuantity(.height, unit: .meter()).map { $0 * 100 }
        let weight = try await latestQuantity(.bodyMass, unit: .gramUnit(with: .kilo))
        let suggestedDefaultSupplementIU = try await fetchSuggestedDefaultSupplementIU()

        return HealthProfileAutofill(
            dateOfBirth: dateOfBirth,
            biologicalSex: biologicalSex,
            heightCentimeters: height,
            weightKilograms: weight,
            skinType: skinType,
            suggestedDefaultSupplementIU: suggestedDefaultSupplementIU
        )
    }

    func requestSupplementWriteAuthorization() async throws {
        guard isAvailable else { throw HealthKitImportError.unavailable }
        guard !Self.supplementShareTypes.isEmpty else { throw HealthKitImportError.supplementTypeUnavailable }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.requestAuthorization(toShare: Self.supplementShareTypes, read: []) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: HealthKitImportError.authorizationDenied)
                }
            }
        }
    }

    func fetchSuggestedDefaultSupplementIU(lookbackDays: Int = 14) async throws -> Int? {
        guard let type = HKObjectType.quantityType(forIdentifier: .dietaryVitaminD) else {
            return nil
        }

        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -lookbackDays, to: end) ?? end.addingTimeInterval(-Double(lookbackDays) * 86_400)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let samples = try await quantitySamples(for: type, predicate: predicate)
        guard !samples.isEmpty else { return nil }

        var dailyMicrograms: [Date: Double] = [:]
        let calendar = Calendar.current

        for sample in samples {
            let day = calendar.startOfDay(for: sample.startDate)
            let micrograms = sample.quantity.doubleValue(for: Self.vitaminDMicrogramUnit)
            dailyMicrograms[day, default: 0] += micrograms
        }

        let dailyInternationalUnits = dailyMicrograms.values
            .map { Self.internationalUnits(fromMicrograms: $0) }
            .filter { $0 > 0 }
            .sorted()

        guard !dailyInternationalUnits.isEmpty else { return nil }

        let median = dailyInternationalUnits[dailyInternationalUnits.count / 2]
        return Self.roundedSupplementIU(median)
    }

    func saveSupplementDose(internationalUnits: Int, takenAt: Date) async throws -> UUID {
        guard isAvailable else { throw HealthKitImportError.unavailable }
        guard let type = HKObjectType.quantityType(forIdentifier: .dietaryVitaminD) else {
            throw HealthKitImportError.supplementTypeUnavailable
        }

        let micrograms = Self.micrograms(fromInternationalUnits: internationalUnits)
        let quantity = HKQuantity(unit: Self.vitaminDMicrogramUnit, doubleValue: micrograms)
        let sample = HKQuantitySample(
            type: type,
            quantity: quantity,
            start: takenAt,
            end: takenAt,
            metadata: [
                "BigDoseSource": "supplement-log"
            ]
        )

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.save(sample) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: HealthKitImportError.authorizationDenied)
                }
            }
        }

        return sample.uuid
    }

    func deleteSupplementDose(externalIdentifier: String) async throws {
        guard isAvailable else { throw HealthKitImportError.unavailable }
        guard let sampleUUID = UUID(uuidString: externalIdentifier),
              let type = HKObjectType.quantityType(forIdentifier: .dietaryVitaminD) else {
            return
        }

        let predicate = HKQuery.predicateForObject(with: sampleUUID)
        let samples = try await quantitySamples(for: type, predicate: predicate)
        guard !samples.isEmpty else { return }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.delete(samples) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: HealthKitImportError.authorizationDenied)
                }
            }
        }
    }

    func requestProfileMetricsReadAuthorization() async throws {
        guard isAvailable else { throw HealthKitImportError.unavailable }
        guard !Self.profileMetricReadTypes.isEmpty else { throw HealthKitImportError.unavailable }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.requestAuthorization(toShare: [], read: Self.profileMetricReadTypes) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: HealthKitImportError.authorizationDenied)
                }
            }
        }
    }

    func requestProfileMetricsWriteAuthorization() async throws {
        guard isAvailable else { throw HealthKitImportError.unavailable }
        guard !Self.profileMetricShareTypes.isEmpty else { throw HealthKitImportError.unavailable }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.requestAuthorization(toShare: Self.profileMetricShareTypes, read: []) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: HealthKitImportError.authorizationDenied)
                }
            }
        }
    }

    func profileMetricUpdatePlan(
        heightCentimeters: Double?,
        weightKilograms: Double?
    ) async -> HealthProfileMetricUpdatePlan? {
        guard isAvailable else { return nil }

        do {
            try await requestProfileMetricsReadAuthorization()

            var plan = HealthProfileMetricUpdatePlan()

            if let heightCentimeters {
                let healthKitHeight = try await latestQuantity(.height, unit: .meter()).map { $0 * 100 }
                if Self.shouldUpdateHealthKit(
                    stored: healthKitHeight,
                    newValue: heightCentimeters,
                    tolerance: Self.heightToleranceCentimeters
                ) {
                    plan.heightCentimeters = heightCentimeters
                }
            }

            if let weightKilograms {
                let healthKitWeight = try await latestQuantity(.bodyMass, unit: .gramUnit(with: .kilo))
                if Self.shouldUpdateHealthKit(
                    stored: healthKitWeight,
                    newValue: weightKilograms,
                    tolerance: Self.weightToleranceKilograms
                ) {
                    plan.weightKilograms = weightKilograms
                }
            }

            return plan.isEmpty ? nil : plan
        } catch {
            return nil
        }
    }

    func applyProfileMetricUpdates(_ plan: HealthProfileMetricUpdatePlan) async throws {
        guard isAvailable else { throw HealthKitImportError.unavailable }

        if let heightCentimeters = plan.heightCentimeters {
            try await saveHeight(centimeters: heightCentimeters)
        }

        if let weightKilograms = plan.weightKilograms {
            try await saveWeight(kilograms: weightKilograms)
        }
    }

    func syncSupplementDoseToHealth(_ dose: SupplementDose, profile: UserProfile) async {
        guard profile.wantsHealthKitSupplementExport else { return }

        do {
            let sampleID = try await saveSupplementDose(
                internationalUnits: dose.internationalUnits,
                takenAt: dose.takenAt
            )
            dose.externalIdentifier = sampleID.uuidString
            if Task.isCancelled {
                try? await deleteSupplementDose(externalIdentifier: sampleID.uuidString)
                dose.externalIdentifier = nil
            }
        } catch {
            return
        }
    }

    func removeSupplementDoseFromHealth(_ dose: SupplementDose) async {
        guard let externalIdentifier = dose.externalIdentifier else { return }

        do {
            try await deleteSupplementDose(externalIdentifier: externalIdentifier)
            dose.externalIdentifier = nil
        } catch {
            return
        }
    }

    func fetchWorkoutCandidates(days: Int = 90, existingIDs: Set<String> = []) async throws -> [HealthWorkoutImportCandidate] {
        guard isAvailable else { throw HealthKitImportError.unavailable }

        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -days, to: end) ?? end.addingTimeInterval(-Double(days) * 86_400)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let candidates = (samples as? [HKWorkout] ?? []).map { workout in
                    Self.candidate(from: workout, existingIDs: existingIDs)
                }
                continuation.resume(returning: candidates)
            }

            healthStore.execute(query)
        }
    }

    nonisolated static let autoSyncLookbackDays = 7
    nonisolated static let autoSyncMinimumInterval: TimeInterval = 3_600

    func silentRefreshIfNeeded(
        profile: UserProfile,
        modelContext: ModelContext,
        force: Bool = false,
        requiresOnboardingComplete: Bool = true
    ) async {
        guard profile.wantsHealthKitSync else { return }
        if requiresOnboardingComplete, !profile.isOnboardingComplete { return }
        guard isAvailable else { return }

        if !force,
           let lastSync = profile.lastHealthKitAutoSyncAt,
           Date().timeIntervalSince(lastSync) < Self.autoSyncMinimumInterval {
            return
        }

        do {
            try await requestOnboardingAuthorization()
            _ = try await syncDaylightIncidental(
                profile: profile,
                modelContext: modelContext,
                days: Self.autoSyncLookbackDays
            )
            _ = try await syncWorkoutsSilently(
                profile: profile,
                modelContext: modelContext,
                days: Self.autoSyncLookbackDays
            )
            profile.lastHealthKitAutoSyncAt = .now
            profile.lastHealthKitImportAt = .now
            profile.healthKitImportStatus = .imported
            try? modelContext.save()
        } catch {
            return
        }
    }

    func syncWorkoutsSilently(
        profile: UserProfile,
        modelContext: ModelContext,
        days: Int
    ) async throws -> Int {
        guard isAvailable else { throw HealthKitImportError.unavailable }

        let existingIDs = Set(
            fetchExposureSessions(modelContext: modelContext)
                .filter { $0.source == .healthKit }
                .compactMap(\.externalIdentifier)
        )
        let candidates = try await fetchWorkoutCandidates(days: days, existingIDs: existingIDs)
        let currentIDs = Set(
            fetchExposureSessions(modelContext: modelContext)
                .filter { $0.source == .healthKit }
                .compactMap(\.externalIdentifier)
        )
        let accepted = candidates.filter { $0.shouldImport && !currentIDs.contains($0.id) }

        for candidate in accepted {
            insertWorkoutExposure(
                from: candidate,
                profile: profile,
                modelContext: modelContext,
                importBatchImportedAt: nil
            )
        }

        if !accepted.isEmpty {
            try? modelContext.save()
        }

        return accepted.count
    }

    func fetchDaylightPreview(
        days: Int = 90,
        profile: UserProfile,
        modelContext: ModelContext
    ) async throws -> DaylightImportPreview {
        guard isAvailable else { throw HealthKitImportError.unavailable }

        let daylightMinutesByDay = try await fetchDaylightMinutesByDay(days: days)
        let existingSessions = fetchExposureSessions(modelContext: modelContext)
        return DaylightIncidentalImportService.preview(
            daylightMinutesByDay: daylightMinutesByDay,
            existingSessions: existingSessions,
            profile: profile,
            lookbackDays: days
        )
    }

    func syncDaylightIncidental(
        profile: UserProfile,
        modelContext: ModelContext,
        days: Int = 90,
        importBatchImportedAt: Date? = nil
    ) async throws -> Int {
        guard isAvailable else { throw HealthKitImportError.unavailable }

        let daylightMinutesByDay = try await fetchDaylightMinutesByDay(days: days)
        let existingSessions = fetchExposureSessions(modelContext: modelContext)
        let plans = DaylightIncidentalImportService.buildPlans(
            daylightMinutesByDay: daylightMinutesByDay,
            existingSessions: existingSessions,
            profile: profile
        )

        let calendar = Calendar.current
        var importedDayCount = 0

        for plan in plans {
            if let existing = existingSessions.first(where: { $0.externalIdentifier == plan.externalIdentifier }) {
                if plan.netMinutes < DaylightIncidentalImportService.minimumNetMinutes {
                    modelContext.delete(existing)
                    continue
                }

                apply(plan: plan, to: existing, profile: profile, calendar: calendar)
                importedDayCount += 1
                continue
            }

            guard plan.netMinutes >= DaylightIncidentalImportService.minimumNetMinutes else { continue }

            let estimate = DaylightIncidentalImportService.holickEstimate(
                profile: profile,
                netMinutes: plan.netMinutes
            )
            let timestamp = DaylightIncidentalImportService.representativeTimestamp(for: plan.day, calendar: calendar)
            let durationSeconds = plan.netMinutes * 60

            modelContext.insert(
                ExposureSession(
                    startedAt: timestamp,
                    endedAt: timestamp.addingTimeInterval(durationSeconds),
                    durationSeconds: durationSeconds,
                    averageUVIndex: DaylightIncidentalImportService.nominalUVIndex,
                    maxUVIndex: DaylightIncidentalImportService.nominalUVIndex,
                    estimatedIU: estimate.estimatedIU,
                    exposedBodySurfaceArea: DaylightIncidentalImportService.incidentalExposedArea(
                        typicalExposedBodySurfaceArea: profile.typicalExposedBodySurfaceArea
                    ),
                    sunscreenFactor: profile.usuallyUsesSunscreen ? 0.35 : 1,
                    source: .healthKitDaylight,
                    quality: estimate.quality,
                    locationLabel: "Incidental daylight",
                    externalIdentifier: plan.externalIdentifier,
                    importBatchImportedAt: importBatchImportedAt,
                    sourceAppName: "Apple Watch",
                    confidence: plan.confidence,
                    note: plan.note
                )
            )
            importedDayCount += 1
        }

        if importedDayCount > 0 || importBatchImportedAt != nil {
            profile.lastHealthKitImportAt = .now
            profile.healthKitImportStatus = .imported
        }

        try? modelContext.save()
        return importedDayCount
    }

    func commit(
        candidates: [HealthWorkoutImportCandidate],
        profile: UserProfile,
        modelContext: ModelContext
    ) async -> HealthImportResult {
        let now = Date()
        let existingIDs = Set(
            fetchExposureSessions(modelContext: modelContext)
                .filter { $0.source == .healthKit }
                .compactMap(\.externalIdentifier)
        )
        let accepted = candidates.filter { $0.shouldImport && !existingIDs.contains($0.id) }
        let acceptedIDs = Set(accepted.map(\.id))
        let skipped = candidates.count - accepted.count
        let start = candidates.map(\.startedAt).min() ?? now
        let end = candidates.map(\.endedAt).max() ?? now
        let batch = HealthImportBatch(
            importedAt: now,
            startDate: start,
            endDate: end,
            workoutCount: candidates.count,
            acceptedExposureCount: accepted.count,
            skippedCount: skipped,
            note: "Imported outdoor workouts from Apple Health."
        )
        modelContext.insert(batch)

        for candidate in candidates {
            let wasAccepted = acceptedIDs.contains(candidate.id)
            modelContext.insert(
                HealthImportItem(
                    externalIdentifier: candidate.id,
                    batchImportedAt: now,
                    startedAt: candidate.startedAt,
                    endedAt: candidate.endedAt,
                    activityName: candidate.activityName,
                    durationSeconds: candidate.durationSeconds,
                    wasAcceptedForExposure: wasAccepted,
                    confidence: candidate.confidence,
                    note: candidate.shouldImport && !wasAccepted
                        ? "Already imported."
                        : candidate.note
                )
            )

            guard wasAccepted else { continue }

            insertWorkoutExposure(
                from: candidate,
                profile: profile,
                modelContext: modelContext,
                importBatchImportedAt: now
            )
        }

        profile.lastHealthKitImportAt = now
        profile.healthKitImportStatus = .imported
        try? modelContext.save()

        let daylightDayCount: Int
        do {
            daylightDayCount = try await syncDaylightIncidental(
                profile: profile,
                modelContext: modelContext,
                days: 90,
                importBatchImportedAt: now
            )
        } catch {
            daylightDayCount = 0
        }

        batch.daylightDayCount = daylightDayCount
        batch.note = "Imported outdoor workouts and Apple Watch Time in Daylight from Apple Health."
        try? modelContext.save()

        return HealthImportResult(
            importedAt: now,
            workoutCount: candidates.count,
            acceptedCount: accepted.count,
            skippedCount: skipped,
            daylightDayCount: daylightDayCount
        )
    }

    private nonisolated static func candidate(from workout: HKWorkout, existingIDs: Set<String>) -> HealthWorkoutImportCandidate {
        let id = workout.uuid.uuidString
        let isDuplicate = existingIDs.contains(id)
        let isOutdoorActivity = workout.workoutActivityType.isOutdoorCandidate
        let isIndoor = (workout.metadata?[HKMetadataKeyIndoorWorkout] as? NSNumber)?.boolValue == true
        let shouldImport = isOutdoorActivity && !isIndoor && !isDuplicate
        let confidence = shouldImport ? 0.55 : 0.15
        let note: String

        if isDuplicate {
            note = "Already imported."
        } else if isIndoor {
            note = "Marked as indoor in Apple Health."
        } else if !isOutdoorActivity {
            note = "Workout type is not treated as outdoor sun exposure."
        } else {
            note = "Holick est. from outdoor workout with conservative assumed UV."
        }

        return HealthWorkoutImportCandidate(
            id: id,
            startedAt: workout.startDate,
            endedAt: workout.endDate,
            activityName: workout.workoutActivityType.bigDoseTitle,
            sourceAppName: Self.sourceAppName(from: workout),
            durationSeconds: workout.duration,
            confidence: confidence,
            shouldImport: shouldImport,
            note: note
        )
    }

    private nonisolated static func sourceAppName(from workout: HKWorkout) -> String? {
        let name = workout.sourceRevision.source.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        return name
    }

    private func conservativeEstimate(profile: UserProfile, durationSeconds: TimeInterval, confidence: Double) -> VitaminDExposureEstimate {
        VitaminDCalculator.estimate(
            input: VitaminDExposureInput(
                uvIndex: 2 * confidence,
                durationSeconds: durationSeconds,
                exposedBodySurfaceArea: profile.typicalExposedBodySurfaceArea,
                skinType: profile.skinType,
                sunscreenTransmission: profile.usuallyUsesSunscreen ? 0.35 : 1
            ),
            targetIU: Double(profile.preferredDailyIU)
        )
    }

    nonisolated static var onboardingReadTypes: Set<HKObjectType> {
        var readTypes = Set<HKObjectType>()
        readTypes.insert(HKObjectType.workoutType())

        if let biologicalSex = HKObjectType.characteristicType(forIdentifier: .biologicalSex) {
            readTypes.insert(biologicalSex)
        }
        if let dateOfBirth = HKObjectType.characteristicType(forIdentifier: .dateOfBirth) {
            readTypes.insert(dateOfBirth)
        }
        if let fitzpatrickSkinType = HKObjectType.characteristicType(forIdentifier: .fitzpatrickSkinType) {
            readTypes.insert(fitzpatrickSkinType)
        }
        if let height = HKObjectType.quantityType(forIdentifier: .height) {
            readTypes.insert(height)
        }
        if let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            readTypes.insert(bodyMass)
        }
        if let dietaryVitaminD = HKObjectType.quantityType(forIdentifier: .dietaryVitaminD) {
            readTypes.insert(dietaryVitaminD)
        }
        if let timeInDaylight = HKObjectType.quantityType(forIdentifier: .timeInDaylight) {
            readTypes.insert(timeInDaylight)
        }

        return readTypes
    }

    nonisolated static var onboardingShareTypes: Set<HKSampleType> {
        profileMetricShareTypes
    }

    nonisolated static var profileMetricReadTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()

        if let height = HKObjectType.quantityType(forIdentifier: .height) {
            types.insert(height)
        }
        if let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            types.insert(bodyMass)
        }

        return types
    }

    nonisolated static var profileMetricShareTypes: Set<HKSampleType> {
        var types = Set<HKSampleType>()

        if let height = HKObjectType.quantityType(forIdentifier: .height) {
            types.insert(height)
        }
        if let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            types.insert(bodyMass)
        }

        return types
    }

    nonisolated static let heightToleranceCentimeters = 0.5
    nonisolated static let weightToleranceKilograms = 0.1

    nonisolated static var supplementShareTypes: Set<HKSampleType> {
        guard let dietaryVitaminD = HKObjectType.quantityType(forIdentifier: .dietaryVitaminD) else {
            return []
        }

        return [dietaryVitaminD]
    }

    nonisolated static let vitaminDMicrogramUnit = HKUnit.gramUnit(with: .micro)

    nonisolated static func internationalUnits(fromMicrograms micrograms: Double) -> Int {
        Int((micrograms * 40).rounded())
    }

    nonisolated static func micrograms(fromInternationalUnits internationalUnits: Int) -> Double {
        Double(internationalUnits) / 40.0
    }

    nonisolated static func roundedSupplementIU(_ internationalUnits: Int) -> Int {
        max(100, Int((Double(internationalUnits) / 100).rounded()) * 100)
    }

    private func quantitySamples(for type: HKQuantityType, predicate: NSPredicate?) async throws -> [HKQuantitySample] {
        try await withCheckedThrowingContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: samples as? [HKQuantitySample] ?? [])
            }

            healthStore.execute(query)
        }
    }

    private func saveHeight(centimeters: Double) async throws {
        guard let type = HKObjectType.quantityType(forIdentifier: .height) else { return }

        let quantity = HKQuantity(unit: .meter(), doubleValue: centimeters / 100)
        let now = Date()
        let sample = HKQuantitySample(
            type: type,
            quantity: quantity,
            start: now,
            end: now,
            metadata: [
                "BigDoseSource": "profile-sync"
            ]
        )

        try await saveQuantitySample(sample)
    }

    private func saveWeight(kilograms: Double) async throws {
        guard let type = HKObjectType.quantityType(forIdentifier: .bodyMass) else { return }

        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kilograms)
        let now = Date()
        let sample = HKQuantitySample(
            type: type,
            quantity: quantity,
            start: now,
            end: now,
            metadata: [
                "BigDoseSource": "profile-sync"
            ]
        )

        try await saveQuantitySample(sample)
    }

    private func saveQuantitySample(_ sample: HKQuantitySample) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.save(sample) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: HealthKitImportError.authorizationDenied)
                }
            }
        }
    }

    nonisolated static func shouldUpdateHealthKit(stored: Double?, newValue: Double, tolerance: Double) -> Bool {
        guard let stored else { return true }
        return abs(stored - newValue) > tolerance
    }

    private func latestQuantity(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async throws -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else {
            return nil
        }

        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double?, Error>) in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }

            healthStore.execute(query)
        }
    }

    private func insertWorkoutExposure(
        from candidate: HealthWorkoutImportCandidate,
        profile: UserProfile,
        modelContext: ModelContext,
        importBatchImportedAt: Date?
    ) {
        let estimate = conservativeEstimate(
            profile: profile,
            durationSeconds: candidate.durationSeconds,
            confidence: candidate.confidence
        )
        modelContext.insert(
            ExposureSession(
                startedAt: candidate.startedAt,
                endedAt: candidate.endedAt,
                durationSeconds: candidate.durationSeconds,
                averageUVIndex: 2,
                maxUVIndex: 2,
                estimatedIU: estimate.estimatedIU,
                exposedBodySurfaceArea: profile.typicalExposedBodySurfaceArea,
                sunscreenFactor: profile.usuallyUsesSunscreen ? 0.35 : 1,
                source: .healthKit,
                quality: estimate.quality,
                locationLabel: candidate.activityName,
                externalIdentifier: candidate.id,
                importBatchImportedAt: importBatchImportedAt,
                sourceAppName: candidate.sourceAppName,
                confidence: candidate.confidence,
                note: candidate.note
            )
        )
    }

    private func fetchExposureSessions(modelContext: ModelContext) -> [ExposureSession] {
        let descriptor = FetchDescriptor<ExposureSession>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func fetchDaylightMinutesByDay(days: Int) async throws -> [Date: TimeInterval] {
        guard let type = HKObjectType.quantityType(forIdentifier: .timeInDaylight) else {
            return [:]
        }

        let calendar = Calendar.current
        let end = Date()
        let start = calendar.date(byAdding: .day, value: -days, to: end) ?? end.addingTimeInterval(-Double(days) * 86_400)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let samples = try await quantitySamples(for: type, predicate: predicate)
        let minuteUnit = HKUnit.minute()

        var minutesByDay: [Date: TimeInterval] = [:]
        for sample in samples {
            let day = calendar.startOfDay(for: sample.startDate)
            let minutes = sample.quantity.doubleValue(for: minuteUnit)
            minutesByDay[day, default: 0] += minutes
        }

        return minutesByDay
    }

    private func apply(
        plan: DaylightDayImportPlan,
        to session: ExposureSession,
        profile: UserProfile,
        calendar: Calendar
    ) {
        let estimate = DaylightIncidentalImportService.holickEstimate(
            profile: profile,
            netMinutes: plan.netMinutes
        )
        let timestamp = DaylightIncidentalImportService.representativeTimestamp(for: plan.day, calendar: calendar)
        let durationSeconds = plan.netMinutes * 60

        session.startedAt = timestamp
        session.endedAt = timestamp.addingTimeInterval(durationSeconds)
        session.durationSeconds = durationSeconds
        session.averageUVIndex = DaylightIncidentalImportService.nominalUVIndex
        session.maxUVIndex = DaylightIncidentalImportService.nominalUVIndex
        session.estimatedIU = estimate.estimatedIU
        session.exposedBodySurfaceArea = DaylightIncidentalImportService.incidentalExposedArea(
            typicalExposedBodySurfaceArea: profile.typicalExposedBodySurfaceArea
        )
        session.sunscreenFactor = profile.usuallyUsesSunscreen ? 0.35 : 1
        session.source = .healthKitDaylight
        session.quality = estimate.quality
        session.locationLabel = "Incidental daylight"
        session.sourceAppName = "Apple Watch"
        session.confidence = plan.confidence
        session.note = plan.note
    }
}

private extension HKBiologicalSex {
    nonisolated var bigDoseSex: BiologicalSex? {
        switch self {
        case .male:
            .male
        case .female:
            .female
        default:
            nil
        }
    }
}

private extension HKFitzpatrickSkinType {
    nonisolated var bigDoseSkinType: FitzpatrickSkinType? {
        switch self {
        case .I:
            .typeI
        case .II:
            .typeII
        case .III:
            .typeIII
        case .IV:
            .typeIV
        case .V:
            .typeV
        case .VI:
            .typeVI
        default:
            nil
        }
    }
}

private extension HKWorkoutActivityType {
    nonisolated var isOutdoorCandidate: Bool {
        switch self {
        case .walking, .running, .hiking, .cycling, .traditionalStrengthTraining, .other:
            true
        default:
            false
        }
    }

    nonisolated var bigDoseTitle: String {
        switch self {
        case .walking:
            "Walking"
        case .running:
            "Running"
        case .hiking:
            "Hiking"
        case .cycling:
            "Cycling"
        default:
            "Workout"
        }
    }
}

import Foundation
@preconcurrency import HealthKit
import SwiftData

struct HealthWorkoutImportCandidate: Identifiable, Sendable {
    var id: String
    var startedAt: Date
    var endedAt: Date
    var activityName: String
    var durationSeconds: TimeInterval
    var confidence: Double
    var shouldImport: Bool
    var note: String
}

struct HealthImportResult: Sendable {
    var workoutCount: Int
    var acceptedCount: Int
    var skippedCount: Int
}

struct HealthProfileAutofill: Sendable {
    var dateOfBirth: Date?
    var biologicalSex: BiologicalSex?
    var heightCentimeters: Double?
    var weightKilograms: Double?

    var filledFields: [String] {
        var fields: [String] = []
        if dateOfBirth != nil { fields.append("date of birth") }
        if biologicalSex != nil { fields.append("biological sex") }
        if heightCentimeters != nil { fields.append("height") }
        if weightKilograms != nil { fields.append("weight") }
        return fields
    }

    var missingFields: [String] {
        var fields: [String] = []
        if dateOfBirth == nil { fields.append("date of birth") }
        if biologicalSex == nil { fields.append("biological sex") }
        if heightCentimeters == nil { fields.append("height") }
        if weightKilograms == nil { fields.append("weight") }
        return fields
    }
}

enum HealthKitImportError: LocalizedError {
    case unavailable
    case authorizationDenied

    var errorDescription: String? {
        switch self {
        case .unavailable:
            "Health data is not available on this device."
        case .authorizationDenied:
            "Apple Health permission was not granted."
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
        guard isAvailable else { throw HealthKitImportError.unavailable }

        let readTypes: Set<HKObjectType> = [
            HKObjectType.workoutType()
        ]

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.requestAuthorization(toShare: Set<HKSampleType>(), read: readTypes) { success, error in
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

    func requestProfileAuthorization() async throws {
        guard isAvailable else { throw HealthKitImportError.unavailable }

        var readTypes = Set<HKObjectType>()
        if let biologicalSex = HKObjectType.characteristicType(forIdentifier: .biologicalSex) {
            readTypes.insert(biologicalSex)
        }
        if let dateOfBirth = HKObjectType.characteristicType(forIdentifier: .dateOfBirth) {
            readTypes.insert(dateOfBirth)
        }
        if let height = HKObjectType.quantityType(forIdentifier: .height) {
            readTypes.insert(height)
        }
        if let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            readTypes.insert(bodyMass)
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.requestAuthorization(toShare: Set<HKSampleType>(), read: readTypes) { success, error in
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
        try await requestProfileAuthorization()

        let dateOfBirthComponents = try? healthStore.dateOfBirthComponents()
        let dateOfBirth = dateOfBirthComponents.flatMap { Calendar.current.date(from: $0) }
        let biologicalSex = try? healthStore.biologicalSex().biologicalSex.bigDoseSex
        let height = try await latestQuantity(.height, unit: .meter()).map { $0 * 100 }
        let weight = try await latestQuantity(.bodyMass, unit: .gramUnit(with: .kilo))

        return HealthProfileAutofill(
            dateOfBirth: dateOfBirth,
            biologicalSex: biologicalSex,
            heightCentimeters: height,
            weightKilograms: weight
        )
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

    func commit(
        candidates: [HealthWorkoutImportCandidate],
        profile: UserProfile,
        modelContext: ModelContext
    ) -> HealthImportResult {
        let now = Date()
        let accepted = candidates.filter(\.shouldImport)
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
            modelContext.insert(
                HealthImportItem(
                    externalIdentifier: candidate.id,
                    batchImportedAt: now,
                    startedAt: candidate.startedAt,
                    endedAt: candidate.endedAt,
                    activityName: candidate.activityName,
                    durationSeconds: candidate.durationSeconds,
                    wasAcceptedForExposure: candidate.shouldImport,
                    confidence: candidate.confidence,
                    note: candidate.note
                )
            )

            guard candidate.shouldImport else { continue }

            let estimate = conservativeEstimate(profile: profile, durationSeconds: candidate.durationSeconds, confidence: candidate.confidence)
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
                    locationLabel: "Apple Health workout",
                    externalIdentifier: candidate.id,
                    importBatchImportedAt: now,
                    confidence: candidate.confidence,
                    note: candidate.note
                )
            )
        }

        profile.lastHealthKitImportAt = now
        profile.healthKitImportStatus = .imported
        try? modelContext.save()

        return HealthImportResult(workoutCount: candidates.count, acceptedCount: accepted.count, skippedCount: skipped)
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
            note = "Outdoor workout; BigDose uses conservative UV assumptions until weather/location review is available."
        }

        return HealthWorkoutImportCandidate(
            id: id,
            startedAt: workout.startDate,
            endedAt: workout.endDate,
            activityName: workout.workoutActivityType.bigDoseTitle,
            durationSeconds: workout.duration,
            confidence: confidence,
            shouldImport: shouldImport,
            note: note
        )
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

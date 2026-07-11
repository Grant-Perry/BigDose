import Foundation
import SwiftData

@MainActor
enum BigDoseLocalDataReset {
    static func eraseAllRecords(in modelContext: ModelContext) throws {
        try deleteAll(ExposureSession.self, in: modelContext)
        try deleteAll(SupplementDose.self, in: modelContext)
        try deleteAll(LabResult.self, in: modelContext)
        try deleteAll(FoodVitaminDEntry.self, in: modelContext)
        try deleteAll(DailySunPlan.self, in: modelContext)
        try deleteAll(HealthImportBatch.self, in: modelContext)
        try deleteAll(HealthImportItem.self, in: modelContext)
        try deleteAll(SkinAssessment.self, in: modelContext)
        try deleteAll(BadgeAward.self, in: modelContext)
        try deleteAll(DailyProgressSummary.self, in: modelContext)
    }

    @discardableResult
    static func nukeAndCreateFreshProfile(in modelContext: ModelContext) throws -> UserProfile {
        try eraseAllRecords(in: modelContext)
        try deleteAll(UserProfile.self, in: modelContext)

        SunSessionSessionCleanup.finishSession()

        let profile = UserProfile()
        modelContext.insert(profile)
        try modelContext.save()
        return profile
    }

    static func resetHealthKitMetadata(on profile: UserProfile) {
        profile.lastHealthKitImportAt = nil
        profile.lastHealthKitAutoSyncAt = nil
        profile.healthKitImportStatus = .neverImported
        profile.updatedAt = .now
    }

    private static func deleteAll<T: PersistentModel>(_ type: T.Type, in modelContext: ModelContext) throws {
        let descriptor = FetchDescriptor<T>()
        let items = try modelContext.fetch(descriptor)
        for item in items {
            modelContext.delete(item)
        }
    }
}

import Foundation
import SwiftData

enum OptimalDailyIUMigration {
    private static let didMigrateKey = "bigdose.didMigrateOptimalDailyIUTarget.v1"

    @MainActor
    static func applyIfNeeded(to profile: UserProfile, modelContext: ModelContext) {
        guard profile.isOnboardingComplete else { return }
        guard UserDefaults.standard.bool(forKey: didMigrateKey) == false else { return }

        profile.preferredDailyIU = OptimalDailyIUService.recommend(for: profile).sunSessionTargetIU
        profile.updatedAt = .now
        try? modelContext.save()
        UserDefaults.standard.set(true, forKey: didMigrateKey)
    }
}

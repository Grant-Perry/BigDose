import Foundation
import SwiftData

enum BigDoseNotificationCoordinator {
    @MainActor
    static func refreshManagedAlerts(profile: UserProfile, modelContext: ModelContext) async {
        let sessions = fetchAll(ExposureSession.self, modelContext: modelContext)
        let supplements = fetchAll(SupplementDose.self, modelContext: modelContext)
        let foods = fetchAll(FoodVitaminDEntry.self, modelContext: modelContext)
        let labs = fetchAll(LabResult.self, modelContext: modelContext)
        let dailyPlans = fetchAll(DailySunPlan.self, modelContext: modelContext)
        let todayPlan = dailyPlans.first { Calendar.current.isDateInToday($0.date) }

        let progress = ProgressAggregationService.snapshot(
            profile: profile,
            sessions: sessions,
            supplements: supplements,
            foods: foods,
            labs: labs
        )

        await BigDoseAlertScheduler.reschedule(
            profile: profile,
            dailyPlan: todayPlan,
            progress: progress
        )
    }

    @MainActor
    private static func fetchAll<T: PersistentModel>(_ type: T.Type, modelContext: ModelContext) -> [T] {
        (try? modelContext.fetch(FetchDescriptor<T>())) ?? []
    }
}

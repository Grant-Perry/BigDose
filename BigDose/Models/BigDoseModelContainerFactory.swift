import SwiftData

enum BigDoseModelContainerFactory {
    static func make(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([
            UserProfile.self,
            SkinAssessment.self,
            ExposureSession.self,
            DailySunPlan.self,
            SupplementDose.self,
            FoodVitaminDEntry.self,
            LabResult.self,
            BadgeAward.self,
            DailyProgressSummary.self
        ])

        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    @MainActor
    static var preview: ModelContainer = {
        do {
            let container = try make(inMemory: true)
            container.mainContext.insert(UserProfile.preview)
            return container
        } catch {
            fatalError("Failed to create preview model container: \(error)")
        }
    }()
}

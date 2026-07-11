import Foundation
import SwiftData

enum DailySupplementAutoApplyService {
    static let autoAppliedNote = "Auto-applied daily supplement"

    @MainActor
    static func applyIfNeeded(
        profile: UserProfile,
        supplements: [SupplementDose],
        modelContext: ModelContext
    ) {
        guard profile.autoApplyDailySupplementIU, profile.defaultSupplementIU > 0 else { return }

        let calendar = Calendar.current
        // Prefer a live fetch so overlapping refreshHome calls share one source of truth.
        let existingToday = (try? modelContext.fetch(FetchDescriptor<SupplementDose>())) ?? supplements
        let alreadyLoggedToday = existingToday.contains { calendar.isDateInToday($0.takenAt) }
        guard !alreadyLoggedToday else { return }

        let dose = SupplementDose(
            takenAt: calendar.startOfDay(for: .now),
            internationalUnits: profile.defaultSupplementIU,
            note: autoAppliedNote,
            source: .generated
        )
        modelContext.insert(dose)
        try? modelContext.save()
    }
}

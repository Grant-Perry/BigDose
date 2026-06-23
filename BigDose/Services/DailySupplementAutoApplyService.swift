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
        let alreadyAppliedToday = supplements.contains {
            calendar.isDateInToday($0.takenAt) && $0.note == autoAppliedNote
        }
        guard !alreadyAppliedToday else { return }

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

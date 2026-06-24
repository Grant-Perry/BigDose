import Foundation

/// Handles sun sessions that outlive app contact — force quit, crash or long background gaps.
enum ActiveSessionRecoveryService {
    /// Matches `ActiveSessionReminderService.gracePeriodSeconds` — after this gap we
    /// no longer extrapolate elapsed time and require explicit user confirmation.
    static let inactivityThresholdSeconds: TimeInterval = 15 * 60

    static func inactivityGap(for record: ActiveSunSessionRecord, now: Date = .now) -> TimeInterval {
        guard !record.isPaused else { return 0 }
        return max(0, now.timeIntervalSince(record.updatedAt))
    }

    static func needsRecovery(for record: ActiveSunSessionRecord, now: Date = .now) -> Bool {
        inactivityGap(for: record, now: now) >= inactivityThresholdSeconds
    }

    /// Elapsed time credited on restore — frozen at last persist, not wall-clock extrapolated.
    static func restoredElapsedSeconds(for record: ActiveSunSessionRecord) -> TimeInterval {
        record.elapsedSeconds
    }

    static func recoveryMessage(
        for record: ActiveSunSessionRecord,
        plan: SunSessionPlan,
        now: Date = .now
    ) -> String {
        let away = SunSessionDurationFormatting.compact(inactivityGap(for: record, now: now))
        let tracked = SunSessionDurationFormatting.compact(record.elapsedSeconds)
        let iu = Int(plan.estimatedIU(at: record.elapsedSeconds).rounded())
        return "BigDose lost contact for about \(away). Your session was at \(tracked) (\(iu) IU) when it was last active. Away time was not added. Still outside, or stop and save?"
    }
}

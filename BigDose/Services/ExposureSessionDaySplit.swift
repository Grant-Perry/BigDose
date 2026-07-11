import Foundation

enum ExposureSessionDaySplit {
    /// Wall-clock overlap of a session with a calendar day, in seconds.
    static func overlapSeconds(
        startedAt: Date,
        endedAt: Date,
        on day: Date,
        calendar: Calendar = .current
    ) -> TimeInterval {
        let dayStart = calendar.startOfDay(for: day)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return 0 }

        let overlapStart = max(startedAt, dayStart)
        let overlapEnd = min(endedAt, dayEnd)
        return max(0, overlapEnd.timeIntervalSince(overlapStart))
    }

    static func attributedIU(
        for session: ExposureSession,
        on day: Date,
        calendar: Calendar = .current
    ) -> Double {
        let duration = max(session.durationSeconds, session.endedAt.timeIntervalSince(session.startedAt))
        guard duration > 0 else { return 0 }

        let overlap = overlapSeconds(
            startedAt: session.startedAt,
            endedAt: session.endedAt,
            on: day,
            calendar: calendar
        )
        guard overlap > 0 else { return 0 }
        return session.estimatedIU * (overlap / duration)
    }

    /// Splits a session that crosses midnight into one segment per calendar day.
    static func segments(
        startedAt: Date,
        endedAt: Date,
        durationSeconds: TimeInterval,
        estimatedIU: Double,
        peakMedUsedPercent: Int,
        medOverLimitPercent: Int,
        calendar: Calendar = .current
    ) -> [(startedAt: Date, endedAt: Date, durationSeconds: TimeInterval, estimatedIU: Double, peakMedUsedPercent: Int, medOverLimitPercent: Int)] {
        let totalDuration = max(durationSeconds, endedAt.timeIntervalSince(startedAt), 1)
        guard !calendar.isDate(startedAt, inSameDayAs: endedAt) else {
            return [(startedAt, endedAt, totalDuration, estimatedIU, peakMedUsedPercent, medOverLimitPercent)]
        }

        var result: [(Date, Date, TimeInterval, Double, Int, Int)] = []
        var cursor = startedAt

        while cursor < endedAt {
            let dayStart = calendar.startOfDay(for: cursor)
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: dayStart) else { break }
            let segmentEnd = min(endedAt, nextDay)
            let segmentDuration = segmentEnd.timeIntervalSince(cursor)
            guard segmentDuration > 0 else { break }

            let fraction = segmentDuration / totalDuration
            result.append((
                cursor,
                segmentEnd,
                segmentDuration,
                estimatedIU * fraction,
                peakMedUsedPercent,
                medOverLimitPercent
            ))
            cursor = segmentEnd
        }

        return result.isEmpty
            ? [(startedAt, endedAt, totalDuration, estimatedIU, peakMedUsedPercent, medOverLimitPercent)]
            : result
    }
}

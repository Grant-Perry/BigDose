import Foundation

struct DaylightDayImportPlan: Identifiable, Sendable {
    var id: String { externalIdentifier }
    var day: Date
    var externalIdentifier: String
    var totalDaylightMinutes: Double
    var creditedSessionMinutes: Double
    var netMinutes: Double
    var estimatedIU: Double
    var confidence: Double
    var note: String
}

struct DaylightImportPreview: Sendable {
    var lookbackDays: Int
    var daysWithDaylight: Int
    var totalNetMinutes: Double
    var totalEstimatedIU: Double
    var plans: [DaylightDayImportPlan]
}

enum DaylightIncidentalImportService {
    nonisolated static let nominalUVIndex = 2.0
    nonisolated static let confidence = 0.45
    nonisolated static let incidentalExposedAreaFactor = 0.5
    nonisolated static let minimumNetMinutes = 1.0
    nonisolated static let externalIdentifierPrefix = "healthkit-daylight-"

    nonisolated static func externalIdentifier(for day: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: day)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let dayValue = components.day ?? 0
        return "\(externalIdentifierPrefix)\(year)-\(month)-\(dayValue)"
    }

    nonisolated static func incidentalExposedArea(typicalExposedBodySurfaceArea: Double) -> Double {
        min(max(typicalExposedBodySurfaceArea * incidentalExposedAreaFactor, 0.10), 0.35)
    }

    nonisolated static func holickEstimate(
        profile: UserProfile,
        netMinutes: Double
    ) -> VitaminDExposureEstimate {
        let uvIndex = nominalUVIndex * confidence
        return VitaminDCalculator.estimate(
            input: VitaminDExposureInput(
                uvIndex: uvIndex,
                durationSeconds: netMinutes * 60,
                exposedBodySurfaceArea: incidentalExposedArea(typicalExposedBodySurfaceArea: profile.typicalExposedBodySurfaceArea),
                skinType: profile.skinType,
                sunscreenTransmission: profile.usuallyUsesSunscreen ? 0.35 : 1
            ),
            targetIU: Double(profile.preferredDailyIU)
        )
    }

    nonisolated static func buildPlans(
        daylightMinutesByDay: [Date: Double],
        existingSessions: [ExposureSession],
        profile: UserProfile,
        calendar: Calendar = .current
    ) -> [DaylightDayImportPlan] {
        daylightMinutesByDay
            .map { day, totalMinutes in
                let creditedMinutes = creditedSessionMinutes(
                    on: day,
                    sessions: existingSessions,
                    calendar: calendar
                )
                let netMinutes = max(0, totalMinutes - creditedMinutes)
                let estimate = holickEstimate(profile: profile, netMinutes: netMinutes)

                let note: String
                if netMinutes < minimumNetMinutes {
                    note = netMinutes <= 0
                        ? "No incidental daylight left after tracked sessions and workouts."
                        : "Less than one minute of incidental daylight remained."
                } else if creditedMinutes > 0 {
                    note = "Holick estimate from \(Int(netMinutes.rounded())) min incidental daylight after subtracting \(Int(creditedMinutes.rounded())) min already credited from other sun sessions."
                } else {
                    note = "Holick estimate from \(Int(netMinutes.rounded())) min Apple Watch Time in Daylight."
                }

                return DaylightDayImportPlan(
                    day: day,
                    externalIdentifier: externalIdentifier(for: day, calendar: calendar),
                    totalDaylightMinutes: totalMinutes,
                    creditedSessionMinutes: creditedMinutes,
                    netMinutes: netMinutes,
                    estimatedIU: estimate.estimatedIU,
                    confidence: confidence,
                    note: note
                )
            }
            .sorted { $0.day > $1.day }
    }

    nonisolated static func preview(
        daylightMinutesByDay: [Date: Double],
        existingSessions: [ExposureSession],
        profile: UserProfile,
        lookbackDays: Int,
        calendar: Calendar = .current
    ) -> DaylightImportPreview {
        let importablePlans = buildPlans(
            daylightMinutesByDay: daylightMinutesByDay,
            existingSessions: existingSessions,
            profile: profile,
            calendar: calendar
        )
        .filter { $0.netMinutes >= minimumNetMinutes }

        return DaylightImportPreview(
            lookbackDays: lookbackDays,
            daysWithDaylight: importablePlans.count,
            totalNetMinutes: importablePlans.reduce(0) { $0 + $1.netMinutes },
            totalEstimatedIU: importablePlans.reduce(0) { $0 + $1.estimatedIU },
            plans: importablePlans
        )
    }

    nonisolated static func creditedSessionMinutes(
        on day: Date,
        sessions: [ExposureSession],
        calendar: Calendar = .current
    ) -> Double {
        sessions
            .filter { session in
                session.source != .healthKitDaylight
                    && calendar.isDate(session.startedAt, inSameDayAs: day)
            }
            .reduce(0) { $0 + $1.durationSeconds } / 60
    }

    nonisolated static func representativeTimestamp(for day: Date, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .hour, value: 12, to: calendar.startOfDay(for: day)) ?? day
    }
}

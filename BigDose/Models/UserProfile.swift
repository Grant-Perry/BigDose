import Foundation
import SwiftData

@Model
final class UserProfile {
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now
    var isOnboardingComplete: Bool = false
    var displayName: String = ""
    var avatarImageData: Data?
    var skinType: FitzpatrickSkinType = FitzpatrickSkinType.typeII
    var biologicalSex: BiologicalSex = BiologicalSex.notSpecified
    var dateOfBirth: Date?
    var heightCentimeters: Double?
    var weightKilograms: Double?
    var goalNanogramsPerMilliliter: Double = 50
    var baselineNanogramsPerMilliliter: Double?
    var preferredDailyIU: Int = 1_000
    var typicalExposedBodySurfaceArea: Double = 0.25
    var usuallyUsesSunscreen: Bool = false
    var wantsWindowReminders: Bool = true
    var wantsRiskAlerts: Bool = true
    var wantsNannyMode: Bool = true
    var levelKnowledge: VitaminDLevelKnowledge = VitaminDLevelKnowledge.willAddLater
    var incidentalSunMinutesPerWeek: Int = 30
    var defaultSupplementIU: Int = 1_000
    var autoApplyDailySupplementIU: Bool = true
    var wantsSolarWindowAlerts: Bool = true
    var wantsDWindowOpeningAlerts: Bool = true
    var wantsDWindowClosingAlerts: Bool = true
    var wantsSolarNoonAlerts: Bool = true
    var wantsSunriseSunsetAlerts: Bool = true
    var wantsAMLightWindowAlerts: Bool = true
    var wantsNextDOpportunityAlerts: Bool = true
    var wantsSupplementReminders: Bool = false
    var wantsLabReminders: Bool = true
    var wantsWeeklyProgressAlerts: Bool = true
    var wantsLevelTrendAlerts: Bool = true
    var wantsMilestoneAlerts: Bool = true
    var wantsWeatherBreakAlerts: Bool = false
    var quietHoursEnabled: Bool = false
    var quietHoursStartHour: Int = 22
    var quietHoursEndHour: Int = 7
    var supplementReminderHour: Int = 9
    var supplementReminderMinute: Int = 0
    var labReminderIntervalDays: Int = 90
    var lastHealthKitImportAt: Date?
    var healthKitImportStatus: HealthImportStatus = HealthImportStatus.neverImported
    var wantsHealthKitSupplementExport: Bool = false
    var hasAcceptedWellnessDisclaimer: Bool = false
    var prepareExitLeadPercent: Int = 20

    init(
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isOnboardingComplete: Bool = false,
        displayName: String = "",
        avatarImageData: Data? = nil,
        skinType: FitzpatrickSkinType = .typeII,
        biologicalSex: BiologicalSex = .notSpecified,
        dateOfBirth: Date? = nil,
        heightCentimeters: Double? = nil,
        weightKilograms: Double? = nil,
        goalNanogramsPerMilliliter: Double = 50,
        baselineNanogramsPerMilliliter: Double? = nil,
        preferredDailyIU: Int = 1_000,
        typicalExposedBodySurfaceArea: Double = 0.25,
        usuallyUsesSunscreen: Bool = false,
        wantsWindowReminders: Bool = true,
        wantsRiskAlerts: Bool = true,
        wantsNannyMode: Bool = true,
        levelKnowledge: VitaminDLevelKnowledge = .willAddLater,
        incidentalSunMinutesPerWeek: Int = 30,
        defaultSupplementIU: Int = 1_000,
        autoApplyDailySupplementIU: Bool = true,
        wantsSolarWindowAlerts: Bool = true,
        wantsDWindowOpeningAlerts: Bool = true,
        wantsDWindowClosingAlerts: Bool = true,
        wantsSolarNoonAlerts: Bool = true,
        wantsSunriseSunsetAlerts: Bool = true,
        wantsAMLightWindowAlerts: Bool = true,
        wantsNextDOpportunityAlerts: Bool = true,
        wantsSupplementReminders: Bool = false,
        wantsLabReminders: Bool = true,
        wantsWeeklyProgressAlerts: Bool = true,
        wantsLevelTrendAlerts: Bool = true,
        wantsMilestoneAlerts: Bool = true,
        wantsWeatherBreakAlerts: Bool = false,
        quietHoursEnabled: Bool = false,
        quietHoursStartHour: Int = 22,
        quietHoursEndHour: Int = 7,
        supplementReminderHour: Int = 9,
        supplementReminderMinute: Int = 0,
        labReminderIntervalDays: Int = 90,
        lastHealthKitImportAt: Date? = nil,
        healthKitImportStatus: HealthImportStatus = .neverImported,
        wantsHealthKitSupplementExport: Bool = false,
        hasAcceptedWellnessDisclaimer: Bool = false,
        prepareExitLeadPercent: Int = 20
    ) {
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isOnboardingComplete = isOnboardingComplete
        self.displayName = displayName
        self.avatarImageData = avatarImageData
        self.skinType = skinType
        self.biologicalSex = biologicalSex
        self.dateOfBirth = dateOfBirth
        self.heightCentimeters = heightCentimeters
        self.weightKilograms = weightKilograms
        self.goalNanogramsPerMilliliter = goalNanogramsPerMilliliter
        self.baselineNanogramsPerMilliliter = baselineNanogramsPerMilliliter
        self.preferredDailyIU = preferredDailyIU
        self.typicalExposedBodySurfaceArea = typicalExposedBodySurfaceArea
        self.usuallyUsesSunscreen = usuallyUsesSunscreen
        self.wantsWindowReminders = wantsWindowReminders
        self.wantsRiskAlerts = wantsRiskAlerts
        self.wantsNannyMode = wantsNannyMode
        self.levelKnowledge = levelKnowledge
        self.incidentalSunMinutesPerWeek = incidentalSunMinutesPerWeek
        self.defaultSupplementIU = defaultSupplementIU
        self.autoApplyDailySupplementIU = autoApplyDailySupplementIU
        self.wantsSolarWindowAlerts = wantsSolarWindowAlerts
        self.wantsDWindowOpeningAlerts = wantsDWindowOpeningAlerts
        self.wantsDWindowClosingAlerts = wantsDWindowClosingAlerts
        self.wantsSolarNoonAlerts = wantsSolarNoonAlerts
        self.wantsSunriseSunsetAlerts = wantsSunriseSunsetAlerts
        self.wantsAMLightWindowAlerts = wantsAMLightWindowAlerts
        self.wantsNextDOpportunityAlerts = wantsNextDOpportunityAlerts
        self.wantsSupplementReminders = wantsSupplementReminders
        self.wantsLabReminders = wantsLabReminders
        self.wantsWeeklyProgressAlerts = wantsWeeklyProgressAlerts
        self.wantsLevelTrendAlerts = wantsLevelTrendAlerts
        self.wantsMilestoneAlerts = wantsMilestoneAlerts
        self.wantsWeatherBreakAlerts = wantsWeatherBreakAlerts
        self.quietHoursEnabled = quietHoursEnabled
        self.quietHoursStartHour = quietHoursStartHour
        self.quietHoursEndHour = quietHoursEndHour
        self.supplementReminderHour = supplementReminderHour
        self.supplementReminderMinute = supplementReminderMinute
        self.labReminderIntervalDays = labReminderIntervalDays
        self.lastHealthKitImportAt = lastHealthKitImportAt
        self.healthKitImportStatus = healthKitImportStatus
        self.wantsHealthKitSupplementExport = wantsHealthKitSupplementExport
        self.hasAcceptedWellnessDisclaimer = hasAcceptedWellnessDisclaimer
        self.prepareExitLeadPercent = Self.clampedPrepareExitLeadPercent(prepareExitLeadPercent)
    }
}

extension UserProfile {
    static let prepareExitLeadPercentRange = 5...50

    static func clampedPrepareExitLeadPercent(_ value: Int) -> Int {
        min(max(value, prepareExitLeadPercentRange.lowerBound), prepareExitLeadPercentRange.upperBound)
    }

    var prepareExitLeadFraction: Double {
        Double(Self.clampedPrepareExitLeadPercent(prepareExitLeadPercent)) / 100
    }

    var hasAnySolarEventAlertsEnabled: Bool {
        wantsDWindowOpeningAlerts
            || wantsDWindowClosingAlerts
            || wantsSolarNoonAlerts
            || wantsSunriseSunsetAlerts
            || wantsAMLightWindowAlerts
            || wantsNextDOpportunityAlerts
    }

    func syncLegacySolarAlertPreferences() {
        wantsWindowReminders = hasAnySolarEventAlertsEnabled
        wantsSolarWindowAlerts = hasAnySolarEventAlertsEnabled
    }
}

extension UserProfile {
    var doseDNABiologicalSexSummary: String {
        var parts = [biologicalSex.title]

        if let dateOfBirth {
            let age = Calendar.current.dateComponents([.year], from: dateOfBirth, to: .now).year ?? 0
            if age > 0 {
                parts.append("\(age) yrs. old")
            }
        }

        if let weightKilograms {
            let pounds = Int((weightKilograms * 2.20462).rounded())
            parts.append("\(pounds) lbs.")
        }

        return parts.joined(separator: " - ")
    }

    static var preview: UserProfile {
        UserProfile(
            isOnboardingComplete: true,
            displayName: "Grant",
            skinType: .typeII,
            biologicalSex: .male,
            dateOfBirth: Calendar.current.date(from: DateComponents(year: 1964, month: 6, day: 14)),
            heightCentimeters: 178,
            weightKilograms: 84,
            baselineNanogramsPerMilliliter: 25,
            hasAcceptedWellnessDisclaimer: true
        )
    }
}

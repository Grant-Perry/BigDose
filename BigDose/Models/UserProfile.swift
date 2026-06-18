import Foundation
import SwiftData

@Model
final class UserProfile {
    var createdAt: Date
    var updatedAt: Date
    var isOnboardingComplete: Bool
    var displayName: String
    var skinType: FitzpatrickSkinType
    var biologicalSex: BiologicalSex
    var dateOfBirth: Date?
    var heightCentimeters: Double?
    var weightKilograms: Double?
    var goalNanogramsPerMilliliter: Double
    var baselineNanogramsPerMilliliter: Double?
    var preferredDailyIU: Int
    var typicalExposedBodySurfaceArea: Double
    var usuallyUsesSunscreen: Bool
    var wantsWindowReminders: Bool
    var wantsRiskAlerts: Bool
    var levelKnowledge: VitaminDLevelKnowledge
    var incidentalSunMinutesPerWeek: Int
    var defaultSupplementIU: Int
    var wantsSolarWindowAlerts: Bool
    var wantsSupplementReminders: Bool
    var wantsLabReminders: Bool
    var wantsWeeklyProgressAlerts: Bool
    var wantsLevelTrendAlerts: Bool
    var wantsMilestoneAlerts: Bool
    var wantsWeatherBreakAlerts: Bool
    var quietHoursEnabled: Bool
    var quietHoursStartHour: Int
    var quietHoursEndHour: Int
    var supplementReminderHour: Int
    var supplementReminderMinute: Int
    var labReminderIntervalDays: Int
    var lastHealthKitImportAt: Date?
    var healthKitImportStatus: HealthImportStatus
    var hasAcceptedWellnessDisclaimer: Bool

    init(
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isOnboardingComplete: Bool = false,
        displayName: String = "",
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
        levelKnowledge: VitaminDLevelKnowledge = .willAddLater,
        incidentalSunMinutesPerWeek: Int = 30,
        defaultSupplementIU: Int = 1_000,
        wantsSolarWindowAlerts: Bool = true,
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
        hasAcceptedWellnessDisclaimer: Bool = false
    ) {
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isOnboardingComplete = isOnboardingComplete
        self.displayName = displayName
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
        self.levelKnowledge = levelKnowledge
        self.incidentalSunMinutesPerWeek = incidentalSunMinutesPerWeek
        self.defaultSupplementIU = defaultSupplementIU
        self.wantsSolarWindowAlerts = wantsSolarWindowAlerts
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
        self.hasAcceptedWellnessDisclaimer = hasAcceptedWellnessDisclaimer
    }
}

extension UserProfile {
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

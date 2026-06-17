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

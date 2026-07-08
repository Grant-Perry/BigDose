import Foundation

enum BigDoseMedicalSourceID: String, CaseIterable, Sendable {
    case nihVitaminDFactSheet
    case iomDRIs
    case endocrineSocietyGuideline
    case holickVitaminDReview
    case holickSunExposureGuidance
    case fitzpatrickSkinTypes
    case whoUVIndex
    case webbUVBAndSolarElevation
    case cdcSkinCancerPrevention
    case aadSunProtection
    case labTestsOnline25OHD
}

struct BigDoseMedicalSource: Identifiable, Hashable, Sendable {
    var id: BigDoseMedicalSourceID
    var title: String
    var summary: String
    var url: URL
}

enum BigDoseMedicalSourceCatalog {
    static func source(for id: BigDoseMedicalSourceID) -> BigDoseMedicalSource {
        allSources[id] ?? allSources[.nihVitaminDFactSheet]!
    }

    static var allSourcesList: [BigDoseMedicalSource] {
        BigDoseMedicalSourceID.allCases.map { source(for: $0) }
    }

    static let groupedSections: [(title: String, sourceIDs: [BigDoseMedicalSourceID])] = [
        (
            "Vitamin D Intake and Blood Levels",
            [.nihVitaminDFactSheet, .iomDRIs, .endocrineSocietyGuideline, .labTestsOnline25OHD]
        ),
        (
            "Sun Exposure and UV",
            [.holickVitaminDReview, .holickSunExposureGuidance, .webbUVBAndSolarElevation, .whoUVIndex]
        ),
        (
            "Skin Type and Burn Risk",
            [.fitzpatrickSkinTypes, .aadSunProtection, .cdcSkinCancerPrevention]
        )
    ]

    private static let allSources: [BigDoseMedicalSourceID: BigDoseMedicalSource] = [
        .nihVitaminDFactSheet: BigDoseMedicalSource(
            id: .nihVitaminDFactSheet,
            title: "NIH Office of Dietary Supplements — Vitamin D",
            summary: "Reference ranges, intake guidance and 25(OH)D testing overview.",
            url: URL(string: "https://ods.od.nih.gov/factsheets/VitaminD-HealthProfessional/")!
        ),
        .iomDRIs: BigDoseMedicalSource(
            id: .iomDRIs,
            title: "National Academies — Dietary Reference Intakes for Vitamin D",
            summary: "Evidence review behind daily intake recommendations by age.",
            url: URL(string: "https://www.ncbi.nlm.nih.gov/books/NBK56068/")!
        ),
        .endocrineSocietyGuideline: BigDoseMedicalSource(
            id: .endocrineSocietyGuideline,
            title: "Endocrine Society — Vitamin D Clinical Practice Guideline",
            summary: "Clinical guidance on vitamin D thresholds and supplementation.",
            url: URL(string: "https://www.endocrine.org/clinical-practice-guidelines/vitamin-d")!
        ),
        .holickVitaminDReview: BigDoseMedicalSource(
            id: .holickVitaminDReview,
            title: "Holick MF — Vitamin D: The Sunshine Vitamin (Review)",
            summary: "Cutaneous vitamin D synthesis and UV-based production models.",
            url: URL(string: "https://pubmed.ncbi.nlm.nih.gov/21527855/")!
        ),
        .holickSunExposureGuidance: BigDoseMedicalSource(
            id: .holickSunExposureGuidance,
            title: "Holick MF — Sunlight and Vitamin D for Bone Health",
            summary: "Safe sun exposure guidance and estimated cutaneous vitamin D production.",
            url: URL(string: "https://pubmed.ncbi.nlm.nih.gov/15585788/")!
        ),
        .fitzpatrickSkinTypes: BigDoseMedicalSource(
            id: .fitzpatrickSkinTypes,
            title: "Fitzpatrick TB — Sun-Reactive Skin Types",
            summary: "Original Fitzpatrick scale used for burn-sensitivity baselines.",
            url: URL(string: "https://pubmed.ncbi.nlm.nih.gov/7248069/")!
        ),
        .whoUVIndex: BigDoseMedicalSource(
            id: .whoUVIndex,
            title: "WHO — Ultraviolet (UV) Index",
            summary: "Global UV index scale and exposure risk categories.",
            url: URL(string: "https://www.who.int/news-room/questions-and-answers/item/radiation-the-ultraviolet-(uv)-index")!
        ),
        .webbUVBAndSolarElevation: BigDoseMedicalSource(
            id: .webbUVBAndSolarElevation,
            title: "Webb AR & Engelsen O — UVB and Solar Elevation",
            summary: "Solar altitude thresholds for biologically effective UVB.",
            url: URL(string: "https://pubmed.ncbi.nlm.nih.gov/15703197/")!
        ),
        .cdcSkinCancerPrevention: BigDoseMedicalSource(
            id: .cdcSkinCancerPrevention,
            title: "CDC — Skin Cancer Prevention",
            summary: "UV overexposure risks and sun safety recommendations.",
            url: URL(string: "https://www.cdc.gov/skin-cancer/prevention/")!
        ),
        .aadSunProtection: BigDoseMedicalSource(
            id: .aadSunProtection,
            title: "American Academy of Dermatology — Sun Protection",
            summary: "Sunscreen, shade and skin cancer prevention guidance.",
            url: URL(string: "https://www.aad.org/public/everyday-care/sun-protection")!
        ),
        .labTestsOnline25OHD: BigDoseMedicalSource(
            id: .labTestsOnline25OHD,
            title: "Testing.com — Vitamin D (25-OH) Test",
            summary: "Overview of 25-hydroxyvitamin D blood testing and ng/mL units.",
            url: URL(string: "https://www.testing.com/tests/vitamin-d-test/")!
        )
    ]
}

extension BigDoseInfoTopic {
    var sources: [BigDoseMedicalSource] {
        sourceIDs.map { BigDoseMedicalSourceCatalog.source(for: $0) }
    }

    private var sourceIDs: [BigDoseMedicalSourceID] {
        switch self {
        case .uvIndex:
            [.whoUVIndex, .cdcSkinCancerPrevention]
        case .riskUsed, .med, .minToMED, .minToRollOver, .medUsed, .safeMax, .sessionSafetyAlerts, .sunSafetyOverview:
            [.fitzpatrickSkinTypes, .cdcSkinCancerPrevention, .aadSunProtection]
        case .sessionGoal, .estimatedIU, .toReachGoal, .plannedTime, .incidentalDaylight, .importedSun:
            [.holickVitaminDReview, .holickSunExposureGuidance, .nihVitaminDFactSheet]
        case .skinType:
            [.fitzpatrickSkinTypes, .aadSunProtection]
        case .goal, .estimatedBloodLevel, .bloodLevelGoalProgress, .bloodLevelBand, .labResult25OHD:
            [.nihVitaminDFactSheet, .endocrineSocietyGuideline, .labTestsOnline25OHD]
        case .peakUV, .window, .vitaminDWindowToday, .dForDuration, .dWindowOpen:
            [.webbUVBAndSolarElevation, .whoUVIndex, .holickVitaminDReview]
        case .last7DaysIntake, .supplementBaseline, .dailyIUTarget:
            [.nihVitaminDFactSheet, .iomDRIs, .endocrineSocietyGuideline]
        case .sunHabitOverview, .typicalSkinExposure, .usualSunscreen, .casualOutdoorTime:
            [.aadSunProtection, .cdcSkinCancerPrevention]
        }
    }
}

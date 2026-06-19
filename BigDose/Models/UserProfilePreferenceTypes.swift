import Foundation

enum VitaminDLevelKnowledge: String, Codable, CaseIterable, Identifiable {
    case knowsRecentResult
    case wantsEstimate
    case willAddLater

    var id: String { rawValue }

    var title: String {
        switch self {
        case .knowsRecentResult:
            "I know my recent result"
        case .wantsEstimate:
            "Start with an estimate"
        case .willAddLater:
            "I will add a lab later"
        }
    }

    var detail: String {
        switch self {
        case .knowsRecentResult:
            "Enter your 25(OH)D blood test result in ng/mL."
        case .wantsEstimate:
            "Use profile and lifestyle answers until a lab is added."
        case .willAddLater:
            "Start conservatively and update when you have a result."
        }
    }
}

enum DataRecordSource: String, Codable, CaseIterable, Identifiable {
    case manual
    case liveTracked
    case healthKit
    case rescueFile
    case generated

    var id: String { rawValue }

    var title: String {
        switch self {
        case .manual:
            "Manual"
        case .liveTracked:
            "Tracked"
        case .healthKit:
            "Apple Health"
        case .rescueFile:
            "Rescue File"
        case .generated:
            "BigDose"
        }
    }
}

enum HealthImportStatus: String, Codable, CaseIterable, Identifiable {
    case neverImported
    case authorized
    case denied
    case imported
    case failed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .neverImported:
            "Not imported"
        case .authorized:
            "Authorized"
        case .denied:
            "Permission denied"
        case .imported:
            "Imported"
        case .failed:
            "Import failed"
        }
    }
}

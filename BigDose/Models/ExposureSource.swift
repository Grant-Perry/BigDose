import Foundation

enum ExposureSource: String, Codable, CaseIterable, Identifiable {
    case planned
    case manual
    case liveTracked
    case healthKit
    case rescueFile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .planned:
            "Planned"
        case .manual:
            "Manual"
        case .liveTracked:
            "Tracked"
        case .healthKit:
            "Apple Health"
        case .rescueFile:
            "Rescue File"
        }
    }
}

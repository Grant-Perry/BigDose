import Foundation

enum BiologicalSex: String, Codable, CaseIterable, Identifiable {
    case notSpecified
    case male
    case female

    var id: String { rawValue }

    var title: String {
        switch self {
        case .notSpecified:
            "Not specified"
        case .male:
            "Male"
        case .female:
            "Female"
        }
    }
}

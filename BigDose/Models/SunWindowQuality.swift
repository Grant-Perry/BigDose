import Foundation

enum SunWindowQuality: String, Codable, CaseIterable, Identifiable {
    case noD
    case low
    case prime
    case strong
    case risk

    var id: String { rawValue }

    var title: String {
        switch self {
        case .noD:
            "No D"
        case .low:
            "Low"
        case .prime:
            "Prime"
        case .strong:
            "Strong"
        case .risk:
            "Risk"
        }
    }
}

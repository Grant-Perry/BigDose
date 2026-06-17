import Foundation

enum FitzpatrickSkinType: String, Codable, CaseIterable, Identifiable {
    case typeI
    case typeII
    case typeIII
    case typeIV
    case typeV
    case typeVI

    var id: String { rawValue }

    var title: String {
        switch self {
        case .typeI:
            "Type I"
        case .typeII:
            "Type II"
        case .typeIII:
            "Type III"
        case .typeIV:
            "Type IV"
        case .typeV:
            "Type V"
        case .typeVI:
            "Type VI"
        }
    }

    var subtitle: String {
        switch self {
        case .typeI:
            "Very fair, burns easily"
        case .typeII:
            "Fair, usually burns"
        case .typeIII:
            "Medium, sometimes burns"
        case .typeIV:
            "Olive, rarely burns"
        case .typeV:
            "Brown, very rarely burns"
        case .typeVI:
            "Deep brown, least likely to burn"
        }
    }

    var minimalErythemaDoseJoulesPerSquareMeter: Double {
        switch self {
        case .typeI:
            200
        case .typeII:
            250
        case .typeIII:
            300
        case .typeIV:
            450
        case .typeV:
            600
        case .typeVI:
            900
        }
    }
}

import Foundation

enum SessionRoute: Identifiable {
    case sunPlanner
    case activeSunSession(SunSessionPlan)
    case completion(SunSessionResult)

    var id: String {
        switch self {
        case .sunPlanner:
            "sunPlanner"
        case .activeSunSession:
            "activeSunSession"
        case .completion:
            "completion"
        }
    }
}

import Foundation

enum SessionRoute: Identifiable {
    case typePicker
    case sunPlanner
    case supplementDose
    case activeSunSession(SunSessionPlan)
    case completion(SunSessionResult)

    var id: String {
        switch self {
        case .typePicker:
            "typePicker"
        case .sunPlanner:
            "sunPlanner"
        case .supplementDose:
            "supplementDose"
        case .activeSunSession:
            "activeSunSession"
        case .completion:
            "completion"
        }
    }
}

enum BigDoseSessionType: CaseIterable, Identifiable {
    case sun
    case lamp
    case supplement
    case scheduled

    var id: String { title }

    var title: String {
        switch self {
        case .sun:
            "Sun Session"
        case .lamp:
            "Lamp Session"
        case .supplement:
            "Supplement Dose"
        case .scheduled:
            "Schedule a Session"
        }
    }

    var systemImage: String {
        switch self {
        case .sun:
            "sun.max.fill"
        case .lamp:
            "sunrise.fill"
        case .supplement:
            "pills.fill"
        case .scheduled:
            "calendar.badge.clock"
        }
    }

    var detail: String {
        switch self {
        case .sun:
            "Use current UV, weather, skin exposure and time."
        case .lamp:
            "Track non-sun exposure later."
        case .supplement:
            "Log vitamin D IU from supplements."
        case .scheduled:
            "Plan a future best-window reminder."
        }
    }

    var shortTitle: String {
        switch self {
        case .sun:
            "Sun Session"
        case .lamp:
            "Lamp"
        case .supplement:
            "Supplement Dose"
        case .scheduled:
            "Schedule"
        }
    }
}

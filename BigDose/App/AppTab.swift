import SwiftUI

enum AppTab: Hashable {
    case home
    case history
    case progress
    case profile
    case settings

    var title: String {
        switch self {
        case .home:
            "Dashboard"
        case .history:
            "History"
        case .progress:
            "Progress"
        case .profile:
            "Profile"
        case .settings:
            "Settings"
        }
    }

    var symbolName: String {
        switch self {
        case .home:
            "sun.max.fill"
        case .history:
            "clock.arrow.circlepath"
        case .progress:
            "chart.bar.fill"
        case .profile:
            "person.crop.circle.fill"
        case .settings:
            "gearshape.fill"
        }
    }
}

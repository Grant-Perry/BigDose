import SwiftUI

enum AppAppearancePreference: String {
    case system
    case light
    case dark

    static let storageKey = "bigDose.appAppearance"

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}

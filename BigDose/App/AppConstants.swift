import Foundation

enum AppConstants {
    static var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version)[\(build)]"
    }

    static var copyrightString: String {
        let year = Calendar.current.component(.year, from: .now)
        return "Copyright © \(year) - Cre8vPlanet Studios, LLC. - All rights reserved."
    }

    static var legalFooter: String {
        "\(versionString)\n\(copyrightString)"
    }
}

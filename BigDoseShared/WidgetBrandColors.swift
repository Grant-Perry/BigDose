import SwiftUI

enum WidgetBrandColors {
    static let solarGold = Color(red: 1.0, green: 0.72, blue: 0.18)
    static let solarOrange = Color(red: 1.0, green: 0.40, blue: 0.12)
    static let deepSpace = Color(red: 0.03, green: 0.05, blue: 0.10)
    static let midnightBlue = Color(red: 0.05, green: 0.13, blue: 0.26)
    static let btnOn = Color(red: 0.620, green: 0.651, blue: 0.478)
    static let btnOnL = Color(red: 0.911, green: 1.0, blue: 0.807)
    static let btnOff = Color(red: 1.0, green: 0.186, blue: 0.325)
    static let btnOffL = Color(red: 1.0, green: 0.497, blue: 0.682)

    static var usefulUVGradient: LinearGradient {
        LinearGradient(
            colors: [btnOn, btnOnL],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var noUsefulUVGradient: LinearGradient {
        LinearGradient(
            colors: [btnOff, btnOffL],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

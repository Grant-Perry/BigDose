import SwiftUI

extension Color {
    static let solarGold = Color(red: 1.0, green: 0.72, blue: 0.18)
    /// Matches marketing site `--gold-bright` (#ffc857).
    static let solarGoldBright = Color(red: 1.0, green: 0.784, blue: 0.341)
    static let solarOrange = Color(red: 1.0, green: 0.40, blue: 0.12)
    static let ultraviolet = Color(red: 0.42, green: 0.30, blue: 1.0)
    static let deepSpace = Color(red: 0.03, green: 0.05, blue: 0.10)
    static let midnightBlue = Color(red: 0.05, green: 0.13, blue: 0.26)
    static let glassStroke = Color.white.opacity(0.18)
}

enum BigDoseBrandGradients {
    /// Web hero accent line: `linear-gradient(118deg, gold-bright, #ffe08a, orange)`.
    static var heroAccent: LinearGradient {
        LinearGradient(
            colors: [.solarGoldBright, Color(red: 1.0, green: 0.878, blue: 0.541), .solarOrange],
            startPoint: UnitPoint(x: 0.08, y: 0.2),
            endPoint: UnitPoint(x: 0.92, y: 0.8)
        )
    }
}

extension ShapeStyle where Self == Color {
    static var solarGold: Color { Color.solarGold }
    static var solarGoldBright: Color { Color.solarGoldBright }
    static var solarOrange: Color { Color.solarOrange }
    static var ultraviolet: Color { Color.ultraviolet }
    static var deepSpace: Color { Color.deepSpace }
    static var midnightBlue: Color { Color.midnightBlue }
    static var glassStroke: Color { Color.glassStroke }
}

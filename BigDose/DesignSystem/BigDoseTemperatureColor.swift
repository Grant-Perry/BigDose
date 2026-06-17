import SwiftUI

enum BigDoseTemperatureColor {
    static func color(for temperature: Double) -> Color {
        switch temperature {
        case ..<(-4):
            Color(red: 0.6, green: 0.0, blue: 0.6)
        case -4..<14:
            Color(red: 0.25, green: 0.25, blue: 0.6)
        case 14..<32:
            Color(red: 0.25, green: 0.6, blue: 0.8)
        case 32..<45:
            Color(red: 0.6, green: 0.8, blue: 0.95)
        case 45..<68:
            Color(red: 0.8, green: 0.95, blue: 0.8)
        case 68..<74:
            Color(red: 0.0, green: 1.0, blue: 0.0)
        case 74..<85:
            Color(red: 1.0, green: 0.7, blue: 0.4)
        case 85..<95:
            Color(red: 1.0, green: 0.2, blue: 0.2)
        case 95..<101:
            Color(red: 1.0, green: 0.41, blue: 0.71)
        default:
            Color(red: 0.6, green: 0.0, blue: 0.6)
        }
    }
}

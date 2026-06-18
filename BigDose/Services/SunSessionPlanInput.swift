import Foundation

struct SunSessionPlanInput: Equatable {
    var startDate: Date
    var durationSeconds: TimeInterval
    var exposedBodySurfaceArea: Double
    var cloudTransmission: Double
    var sunscreenTransmission: Double
    var uvIndex: Double
    var skinType: FitzpatrickSkinType

    var effectiveUVIndex: Double {
        max(0, uvIndex) * cloudTransmission * sunscreenTransmission
    }

    func exposureInput() -> VitaminDExposureInput {
        VitaminDExposureInput(
            uvIndex: effectiveUVIndex,
            durationSeconds: durationSeconds,
            exposedBodySurfaceArea: exposedBodySurfaceArea,
            skinType: skinType,
            sunscreenTransmission: 1
        )
    }
}

enum SkinExposurePreset: String, CaseIterable, Identifiable {
    case faceAndHands
    case tshirtAndShorts
    case tankTopAndShorts
    case bathingSuit
    case fullBody

    var id: String { rawValue }

    var title: String {
        switch self {
        case .faceAndHands:
            "Face & Hands"
        case .tshirtAndShorts:
            "T-Shirt & Shorts"
        case .tankTopAndShorts:
            "Tank Top & Shorts"
        case .bathingSuit:
            "Bathing Suit"
        case .fullBody:
            "Full Body"
        }
    }

    var detail: String {
        switch self {
        case .faceAndHands:
            "Winter clothing"
        case .tshirtAndShorts:
            "Casual summer wear"
        case .tankTopAndShorts:
            "More skin exposed"
        case .bathingSuit:
            "Beach or pool wear"
        case .fullBody:
            "Maximum exposure"
        }
    }

    var exposedBodySurfaceArea: Double {
        switch self {
        case .faceAndHands:
            0.10
        case .tshirtAndShorts:
            0.30
        case .tankTopAndShorts:
            0.50
        case .bathingSuit:
            0.70
        case .fullBody:
            0.85
        }
    }

    static func closest(to exposedBodySurfaceArea: Double) -> SkinExposurePreset {
        allCases.min {
            abs($0.exposedBodySurfaceArea - exposedBodySurfaceArea) < abs($1.exposedBodySurfaceArea - exposedBodySurfaceArea)
        } ?? .tshirtAndShorts
    }

    static func coverageLabel(for exposedBodySurfaceArea: Double) -> String {
        let preset = closest(to: exposedBodySurfaceArea)
        let percent = Int((exposedBodySurfaceArea * 100).rounded())
        return "\(preset.title) · \(percent)%"
    }
}

enum CloudCoverPreset: String, CaseIterable, Identifiable {
    case clear
    case partlyCloudy
    case overcast
    case shade

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clear:
            "Clear"
        case .partlyCloudy:
            "Partly Cloudy"
        case .overcast:
            "Overcast"
        case .shade:
            "Shade"
        }
    }

    var transmission: Double {
        switch self {
        case .clear:
            1.0
        case .partlyCloudy:
            0.75
        case .overcast:
            0.45
        case .shade:
            0.25
        }
    }
}

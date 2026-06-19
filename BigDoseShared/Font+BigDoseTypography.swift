import SwiftUI

enum BigDoseFontFamily {
    static let bebasNeue = "BebasNeue-Regular"
}

extension Font {
    /// Primary display/header face (Bebas Neue).
    static func bigDoseHeader(_ style: Font.TextStyle) -> Font {
        .custom(BigDoseFontFamily.bebasNeue, size: basePointSize(for: style), relativeTo: style)
    }

    /// Large metrics, hero numbers, and other display sizes.
    static func bigDoseDisplay(_ size: CGFloat, relativeTo style: Font.TextStyle = .largeTitle) -> Font {
        .custom(BigDoseFontFamily.bebasNeue, size: size, relativeTo: style)
    }

    /// App name wordmark (Bebas Neue).
    static func bigDoseWordmark(_ size: CGFloat, relativeTo style: Font.TextStyle = .title) -> Font {
        bigDoseDisplay(size, relativeTo: style)
    }

    private static func basePointSize(for style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline: 17
        case .subheadline: 15
        default: 17
        }
    }
}

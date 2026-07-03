import SwiftUI

enum BigDoseFontFamily {
    static let bebasNeue = "BebasNeue-Regular"
    /// Plus Jakarta Sans variable font (body, lede, UI prose). Matches bigdose.web.app marketing site.
    static let plusJakartaSans = "Plus Jakarta Sans"
    /// Marketing hero accent — matches web `--font-accent`.
    static let instrumentSerifItalic = "InstrumentSerif-Italic"

    /// Single switch for every display/header/wordmark face in the app.
    /// Change this one value to swap Bebas Neue ↔ Plus Jakarta Sans globally.
    static var display: String { bebasNeue }
}

extension Font {
    /// Primary display/header face — routed through `BigDoseFontFamily.display`.
    static func bigDoseHeader(_ style: Font.TextStyle) -> Font {
        .custom(BigDoseFontFamily.display, size: basePointSize(for: style), relativeTo: style)
    }

    /// Large metrics, hero numbers, and other display sizes.
    static func bigDoseDisplay(_ size: CGFloat, relativeTo style: Font.TextStyle = .largeTitle) -> Font {
        .custom(BigDoseFontFamily.display, size: size, relativeTo: style)
    }

    /// App name wordmark.
    static func bigDoseWordmark(_ size: CGFloat, relativeTo style: Font.TextStyle = .title) -> Font {
        bigDoseDisplay(size, relativeTo: style)
    }

    /// Marketing hero primary line — Bebas-style display uppercase (web `.hero__title-line--primary`).
    static func bigDoseHeroPrimary(_ size: CGFloat = 40, relativeTo style: Font.TextStyle = .largeTitle) -> Font {
        .custom(BigDoseFontFamily.display, size: size, relativeTo: style)
    }

    /// Marketing hero accent line — Instrument Serif italic + gold gradient (web `.hero__title-line--accent`).
    static func bigDoseHeroAccent(_ size: CGFloat = 32, relativeTo style: Font.TextStyle = .title) -> Font {
        .custom(BigDoseFontFamily.instrumentSerifItalic, size: size, relativeTo: style)
    }

    /// Body copy and UI prose (Plus Jakarta Sans). Default matches marketing site body weight.
    static func bigDoseBody(_ style: Font.TextStyle = .body, weight: Font.Weight = .regular) -> Font {
        .custom(BigDoseFontFamily.plusJakartaSans, size: bodyPointSize(for: style), relativeTo: style)
            .weight(weight)
    }

    /// Marketing-style lede — light Plus Jakarta Sans, slightly open line height in views.
    static func bigDoseLede(_ style: Font.TextStyle = .body) -> Font {
        bigDoseBody(style, weight: .light)
    }

    private static func bodyPointSize(for style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline: 17
        case .body: 17
        case .subheadline: 15
        case .callout: 16
        case .footnote: 13
        case .caption: 12
        case .caption2: 11
        @unknown default: 17
        }
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

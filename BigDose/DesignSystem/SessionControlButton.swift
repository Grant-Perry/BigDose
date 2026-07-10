import SwiftUI

struct SessionControlButton: View {
    enum Style {
        case pause(isPaused: Bool)
        case stop

        var icon: String {
            switch self {
            case .pause(let isPaused):
                isPaused ? "play.fill" : "pause.fill"
            case .stop:
                "stop.fill"
            }
        }

        var title: String {
            switch self {
            case .pause(let isPaused):
                isPaused ? "Resume" : "Pause"
            case .stop:
                "Stop"
            }
        }

        var tint: Color {
            switch self {
            case .pause(let isPaused):
                isPaused ? .gpHiGreen : .solarGoldBright
            case .stop:
                .gpRedPink
            }
        }

        var accessibilityHint: String {
            switch self {
            case .pause(let isPaused):
                isPaused
                    ? "Continues adding sunlight exposure time and estimated vitamin D"
                    : "Freezes sunlight exposure time until you resume"
            case .stop:
                "Stops the timer and lets you save this session"
            }
        }
    }

    @Environment(\.colorScheme) private var colorScheme

    var style: Style
    var action: () -> Void

    var body: some View {
        Button(style.title, systemImage: style.icon, action: action)
            .font(.title3)
            .bold()
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity, minHeight: 70)
            .background(backgroundColor, in: .rect(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(borderColor, lineWidth: colorScheme == .dark ? 1.25 : 1)
            }
            .shadow(color: shadowColor, radius: 12, y: 6)
            .buttonStyle(.plain)
            .accessibilityHint(style.accessibilityHint)
    }

    private var foregroundColor: Color {
        switch style {
        case .pause(let isPaused):
            if colorScheme == .dark {
                return isPaused ? .gpHiGreen : .solarGoldBright
            }
            return .black
        case .stop:
            return colorScheme == .dark ? .white : .gpRedPink
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .pause:
            return colorScheme == .dark
                ? .black.opacity(0.2)
                : .solarGold.opacity(0.74)
        case .stop:
            return colorScheme == .dark
                ? .gpRedPink.opacity(0.58)
                : .gpRedPink.opacity(0.1)
        }
    }

    private var borderColor: Color {
        switch style {
        case .pause(let isPaused):
            return isPaused ? .gpHiGreen : .solarGoldBright
        case .stop:
            return colorScheme == .dark ? .gpRedPink : .gpRedPink.opacity(0.32)
        }
    }

    private var shadowColor: Color {
        switch style {
        case .pause:
            return .solarGold.opacity(colorScheme == .dark ? 0.24 : 0.16)
        case .stop:
            return .gpRedPink.opacity(colorScheme == .dark ? 0.24 : 0.1)
        }
    }
}

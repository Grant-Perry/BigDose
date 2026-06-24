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

        var tint: Color {
            switch self {
            case .pause(let isPaused):
                isPaused ? .gpHiGreen : .blue
            case .stop:
                .gpRedPink
            }
        }

        var accessibilityLabel: String {
            switch self {
            case .pause(let isPaused):
                isPaused ? "Resume session" : "Pause session"
            case .stop:
                "Stop and save session"
            }
        }
    }

    var style: Style
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial.opacity(0.55))
                    .frame(width: 64, height: 64)
                    .overlay {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [style.tint.opacity(0.72), style.tint.opacity(0.38)],
                                    center: .center,
                                    startRadius: 4,
                                    endRadius: 36
                                )
                            )
                    }
                    .overlay {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.32), .white.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: style.tint.opacity(0.38), radius: 16, y: 6)

                Image(systemName: style.icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(style.accessibilityLabel)
    }
}

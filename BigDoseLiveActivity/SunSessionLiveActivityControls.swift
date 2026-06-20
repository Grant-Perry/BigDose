import AppIntents
import SwiftUI

enum SunSessionLiveActivityControlStyle {
    case lockScreen
    case dynamicIsland
}

struct SunSessionLiveActivityControls: View {
    let sessionID: String
    let isPaused: Bool
    let pendingControl: SunSessionPendingControl
    let style: SunSessionLiveActivityControlStyle

    var body: some View {
        HStack(spacing: style == .lockScreen ? 8 : 10) {
            if isPaused {
                resumeButton
            } else {
                pauseButton
            }

            endButton
        }
        .controlSize(style == .lockScreen ? .small : .regular)
    }

    private var pauseButton: some View {
        let isArmed = pendingControl == .pause

        return Group {
            if isArmed {
                Button(intent: PauseSunSessionLiveActivityIntent(sessionID: sessionID)) {
                    pauseButtonLabel(isArmed: true)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            } else {
                Button(intent: PauseSunSessionLiveActivityIntent(sessionID: sessionID)) {
                    pauseButtonLabel(isArmed: false)
                }
                .buttonStyle(.bordered)
                .tint(.white)
            }
        }
        .accessibilityLabel(isArmed ? "Tap again to pause sun session" : "Pause sun session")
    }

    @ViewBuilder
    private func pauseButtonLabel(isArmed: Bool) -> some View {
        switch style {
        case .lockScreen:
            Label(
                isArmed ? "Tap again" : "Pause",
                systemImage: "pause.fill"
            )
            .font(.caption.weight(.bold))
            .frame(maxWidth: .infinity)
        case .dynamicIsland:
            Image(systemName: "pause.fill")
        }
    }

    private var resumeButton: some View {
        Button(intent: ResumeSunSessionLiveActivityIntent(sessionID: sessionID)) {
            switch style {
            case .lockScreen:
                Label("Resume", systemImage: "play.fill")
                    .font(.caption.weight(.bold))
                    .frame(maxWidth: .infinity)
            case .dynamicIsland:
                Image(systemName: "play.fill")
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
        .accessibilityLabel("Resume sun session")
    }

    private var endButton: some View {
        let isArmed = pendingControl == .end

        return Button(intent: EndSunSessionLiveActivityIntent(sessionID: sessionID)) {
            endButtonLabel(isArmed: isArmed)
        }
        .buttonStyle(.borderedProminent)
        .tint(isArmed ? .orange : .red)
        .accessibilityLabel(isArmed ? "Tap again to end sun session" : "End sun session")
    }

    @ViewBuilder
    private func endButtonLabel(isArmed: Bool) -> some View {
        switch style {
        case .lockScreen:
            Label(
                isArmed ? "Tap again" : "End",
                systemImage: "stop.fill"
            )
            .font(.caption.weight(.bold))
            .frame(maxWidth: .infinity)
        case .dynamicIsland:
            Image(systemName: "stop.fill")
        }
    }
}

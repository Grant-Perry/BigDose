import Combine
import SwiftUI

struct ActiveSunSessionView: View {
    var plan: SunSessionPlan
    var onCancel: () -> Void
    var onComplete: (SunSessionResult) -> Void

    @State private var elapsedSeconds: TimeInterval = 0
    @State private var isPaused = false
    @State private var activeAlert: SunSessionSafetyAlert?
    @State private var didShowTurnOverAlert = false
    @State private var didShowMedWarningAlert = false
    @State private var didShowStopAlert = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var estimatedIU: Double {
        min(elapsedSeconds * plan.iuPerMinute / 60, plan.estimate.estimatedIU)
    }

    private var progress: Double {
        guard plan.durationSeconds > 0 else { return 0 }
        return min(elapsedSeconds / plan.durationSeconds, 1)
    }

    var body: some View {
        ZStack {
            BigDoseGradientBackground()

            VStack(spacing: 22) {
                header
                timerDial
                controls
                modifiersCard
                Spacer()
            }
            .padding(18)
        }
        .onReceive(timer) { _ in
            guard !isPaused else { return }
            elapsedSeconds += 1
            evaluateSafetyAlerts()
            if elapsedSeconds >= plan.durationSeconds {
                complete()
            }
        }
        .task {
            await SessionSafetyNotificationService.schedule(for: plan)
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .turnOver:
                Alert(
                    title: Text("Turn over"),
                    message: Text("You have reached the turn-over point for this session. Flip sides, rotate, or change exposure."),
                    dismissButton: .default(Text("Got it"))
                )
            case .medWarning:
                Alert(
                    title: Text("Approaching exposure limit"),
                    message: Text("You are around 75% of the estimated MED window for your skin type and current UV. Consider wrapping up soon."),
                    dismissButton: .default(Text("OK"))
                )
            case .stop:
                Alert(
                    title: Text("Stop or cover up"),
                    message: Text("You are near the conservative exposure limit for this skin type and UV level. BigDose paused the timer."),
                    primaryButton: .destructive(Text("End Session")) {
                        complete()
                    },
                    secondaryButton: .default(Text("Resume")) {
                        isPaused = false
                    }
                )
            }
        }
        .onDisappear {
            SessionSafetyNotificationService.cancelSessionNotifications()
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(plan.locationName)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                Text("\(Int(plan.currentTemperatureFahrenheit.rounded()))° · UV \(plan.uvIndex.formatted(.number.precision(.fractionLength(1)))) · \(plan.cloudCover.title)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
            }

            Spacer()

            Button("End") {
                complete()
            }
            .font(.headline.weight(.semibold))
            .foregroundStyle(.solarGold)
        }
    }

    private var timerDial: some View {
        GlassCard {
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.12), lineWidth: 18)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(colors: [.solarOrange, .solarGold], startPoint: .bottomLeading, endPoint: .topTrailing),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: .solarGold.opacity(0.35), radius: 16)

                VStack(spacing: 8) {
                    Text(durationText(elapsedSeconds))
                        .font(.system(size: 40, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white)

                    Text("\(Int(estimatedIU.rounded())) IU")
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("\(Int(plan.iuPerMinute.rounded())) IU/min")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.green)

                    Text("\(Int(progress * 100))%")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.solarGold)
                }
            }
            .frame(height: 330)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Sun session timer, \(Int(estimatedIU.rounded())) IU, \(Int(progress * 100)) percent complete")
        }
    }

    private var controls: some View {
        HStack {
            VStack(spacing: 2) {
                Text("\(max(0, Int((plan.medTimeSeconds - elapsedSeconds) / 60)))")
                    .font(.title.weight(.semibold))
                    .foregroundStyle(.green)
                Text("min to MED")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
            }

            Spacer()

            Button {
                withAnimation(.smooth) {
                    isPaused.toggle()
                }
            } label: {
                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 72, height: 72)
                    .background(isPaused ? Color.green : Color.red, in: .circle)
            }
            .accessibilityLabel(isPaused ? "Resume session" : "Pause session")

            Spacer()

            VStack(spacing: 2) {
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .font(.title.weight(.semibold))
                    .foregroundStyle(Color.gpHiLtBlue)
                Text("Turn over")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 12)
    }

    private var modifiersCard: some View {
        GlassCard(cornerRadius: 24) {
            VStack(spacing: 12) {
                sessionRow("Skin", "\(Int(plan.exposedBodySurfaceArea * 100))%", "person.fill")
                Divider().overlay(.white.opacity(0.12))
                sessionRow("Clouds", plan.cloudCover.title, "cloud.sun.fill")
                Divider().overlay(.white.opacity(0.12))
                sessionRow("Goal", "\(Int(plan.targetIU)) IU", "target")
            }
        }
    }

    private func sessionRow(_ title: String, _ value: String, _ icon: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
            Spacer()
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
        }
    }

    private func complete() {
        SessionSafetyNotificationService.cancelSessionNotifications()
        let result = SunSessionResult(
            plan: plan,
            endedAt: .now,
            elapsedSeconds: max(elapsedSeconds, 1),
            estimatedIU: estimatedIU
        )
        onComplete(result)
    }

    private func evaluateSafetyAlerts() {
        if !didShowTurnOverAlert, elapsedSeconds >= plan.turnOverAlertSeconds {
            didShowTurnOverAlert = true
            activeAlert = .turnOver
        }

        if !didShowMedWarningAlert, elapsedSeconds >= plan.medWarningSeconds {
            didShowMedWarningAlert = true
            activeAlert = .medWarning
        }

        if !didShowStopAlert, elapsedSeconds >= plan.stopAlertSeconds {
            didShowStopAlert = true
            isPaused = true
            activeAlert = .stop
        }
    }

    private func durationText(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

private enum SunSessionSafetyAlert: Identifiable {
    case turnOver
    case medWarning
    case stop

    var id: String {
        switch self {
        case .turnOver:
            "turnOver"
        case .medWarning:
            "medWarning"
        case .stop:
            "stop"
        }
    }
}

#Preview {
    ActiveSunSessionView(plan: SunSessionPlan(
        startedAt: .now,
        durationSeconds: 15 * 60,
        exposedBodySurfaceArea: 0.25,
        cloudCover: .clear,
        sunscreenTransmission: 1,
        uvIndex: 6.4,
        currentTemperatureFahrenheit: 82,
        skinType: .typeII,
        locationName: "Newport News",
        targetIU: 1_000
    ), onCancel: { }, onComplete: { _ in })
}

import Combine
import SwiftUI
import UIKit

struct ActiveSunSessionView: View {
    var wantsSessionSafetyAlerts: Bool
    var onCancel: () -> Void
    var onComplete: (SunSessionResult) -> Void

    @Environment(\.scenePhase) private var scenePhase
    @State private var plan: SunSessionPlan
    @State private var elapsedSeconds: TimeInterval = 0
    @State private var isPaused = false
    @State private var activeAlert: SunSessionSafetyAlert?
    @State private var didShowTurnOverAlert = false
    @State private var didShowMedWarningAlert = false
    @State private var didShowPrepareExitAlert = false
    @State private var didShowStopAlert = false
    @State private var isShowingSkinCoverage = false
    @State private var isShowingGoalPicker = false
    @State private var isShowingCancelConfirmation = false
    @State private var backgroundLiveActivitySyncTask: Task<Void, Never>?
    @State private var sessionEnded = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(
        plan: SunSessionPlan,
        wantsSessionSafetyAlerts: Bool,
        onCancel: @escaping () -> Void,
        onComplete: @escaping (SunSessionResult) -> Void
    ) {
        _plan = State(initialValue: plan)
        self.wantsSessionSafetyAlerts = wantsSessionSafetyAlerts
        self.onCancel = onCancel
        self.onComplete = onComplete
    }

    private var estimatedIU: Double {
        plan.estimatedIU(at: elapsedSeconds)
    }

    private var goalProgress: Double {
        plan.goalProgress(at: elapsedSeconds)
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
            consumeLiveActivityCommands()

            if Int(elapsedSeconds) % 5 == 0 {
                persistSessionState()
            }

            guard !isPaused, !sessionEnded else { return }
            elapsedSeconds += 1
            syncLiveActivity()
            BigDoseWidgetReloader.reloadHomeWidget()
            evaluateSafetyAlerts()
            if plan.hasReachedGoal(at: elapsedSeconds) || elapsedSeconds >= plan.durationSeconds {
                complete()
            }
        }
        .task {
            await refreshSessionSafetyNotifications()
            restoreSessionStateIfNeeded()
            consumeLiveActivityCommands()
            guard !sessionEnded else { return }
            persistSessionState()
            syncLiveActivity()
        }
        .onChange(of: isPaused) { _, _ in
            persistSessionState()
            syncLiveActivity()
        }
        .onChange(of: plan.exposedBodySurfaceArea) { _, _ in
            syncLiveActivity()
            Task { await refreshSessionSafetyNotifications() }
        }
        .onChange(of: plan.cloudCover) { _, _ in
            syncLiveActivity()
            Task { await refreshSessionSafetyNotifications() }
        }
        .onChange(of: plan.targetIU) { _, _ in
            syncLiveActivity()
            Task { await refreshSessionSafetyNotifications() }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                backgroundLiveActivitySyncTask?.cancel()
                backgroundLiveActivitySyncTask = nil
                consumeLiveActivityCommands()
                syncLiveActivity()
            case .inactive, .background:
                syncLiveActivity()
                startBackgroundLiveActivitySyncIfNeeded()
            @unknown default:
                break
            }
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
            case .prepareExit(let countdown):
                Alert(
                    title: Text("Get ready to exit sun"),
                    message: Text("Start getting ready to head inside. You're approaching your exit in \(countdown)."),
                    dismissButton: .default(Text("Got it"))
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
        .onChange(of: activeAlert) { _, alert in
            guard let alert else { return }
            BigDoseAlertFeedback.present(kind: alert.feedbackKind)
        }
        .onDisappear {
            SessionSafetyNotificationService.cancelSessionNotifications()
        }
        .sheet(isPresented: $isShowingSkinCoverage) {
            SkinExposurePickerView(exposedBodySurfaceArea: $plan.exposedBodySurfaceArea)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $isShowingGoalPicker) {
            SessionGoalPickerView(targetIU: $plan.targetIU)
                .presentationDetents([.medium])
        }
        .confirmationDialog(
            "Cancel sun session?",
            isPresented: $isShowingCancelConfirmation,
            titleVisibility: .visible
        ) {
            Button("Cancel Session", role: .destructive) {
                cancel()
            }
            Button("Keep Going", role: .cancel) { }
        } message: {
            Text("Are you certain? This won't record this sun session if you cancel.")
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(plan.locationName)
                    .font(.bigDoseHeader(.title2).weight(.semibold))
                    .foregroundStyle(.white)
                Text("\(Int(plan.currentTemperatureFahrenheit.rounded()))° · UV \(plan.uvIndex.formatted(.number.precision(.fractionLength(1)))) · \(plan.cloudCover.title)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
            }

            Spacer()

            HStack(spacing: 16) {
                Button("Cancel") {
                    isShowingCancelConfirmation = true
                }
                .font(.bigDoseHeader(.headline).weight(.semibold))
                .foregroundStyle(.white.opacity(0.62))

                Button("End") {
                    complete()
                }
                .font(.bigDoseHeader(.headline).weight(.semibold))
                .foregroundStyle(.solarGold)
            }
        }
    }

    private var timerDial: some View {
        GlassCard {
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.12), lineWidth: 18)

                Circle()
                    .trim(from: 0, to: goalProgress)
                    .stroke(
                        LinearGradient(colors: [.solarOrange, .solarGold], startPoint: .bottomLeading, endPoint: .topTrailing),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: .solarGold.opacity(0.35), radius: 16)
                    .animation(.smooth, value: goalProgress)

                VStack(spacing: 8) {
                    Text(durationText(elapsedSeconds))
                        .font(.system(size: 40, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white)

                    Text("\(Int(estimatedIU.rounded())) IU")
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("\(Int(plan.liveIUProductionRatePerMinute.rounded())) IU/min")
                        .font(.bigDoseHeader(.headline).weight(.semibold))
                        .foregroundStyle(.green)

                    if let minutesToGoal = plan.minutesToGoal(at: elapsedSeconds) {
                        Text("~\(minutesToGoal) min to goal")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.62))
                    } else if goalProgress >= 1 {
                        Text("Goal reached")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.solarGold)
                    }

                    Text("\(Int(goalProgress * 100))% of goal")
                        .font(.bigDoseHeader(.title2).weight(.semibold))
                        .foregroundStyle(.solarGold)
                }
            }
            .frame(height: 330)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Sun session timer, \(Int(estimatedIU.rounded())) of \(Int(plan.targetIU.rounded())) IU, \(Int(goalProgress * 100)) percent of goal")
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
                Button {
                    isShowingSkinCoverage = true
                } label: {
                    sessionRow(
                        "Skin Coverage",
                        SkinExposurePreset.coverageLabel(for: plan.exposedBodySurfaceArea),
                        "person.fill"
                    )
                }
                .buttonStyle(.plain)

                Divider().overlay(.white.opacity(0.12))

                Menu {
                    ForEach(CloudCoverPreset.allCases) { preset in
                        Button(preset.title) {
                            plan.cloudCover = preset
                        }
                    }
                } label: {
                    sessionRow("Clouds", plan.cloudCover.title, "cloud.sun.fill")
                }

                Divider().overlay(.white.opacity(0.12))

                Button {
                    isShowingGoalPicker = true
                } label: {
                    sessionRow("Goal", "\(Int(plan.targetIU.rounded())) IU", "target")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func sessionRow(_ title: String, _ value: String, _ icon: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.bigDoseHeader(.headline).weight(.semibold))
                .foregroundStyle(.white)
            Spacer()
            Text(value)
                .font(.bigDoseHeader(.headline).weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
                .multilineTextAlignment(.trailing)
            Image(systemName: "chevron.down")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.42))
        }
    }

    private func restoreSessionStateIfNeeded() {
        guard let record = ActiveSunSessionStore.load(),
              record.sessionID == plan.liveActivitySessionID else {
            return
        }

        elapsedSeconds = max(elapsedSeconds, record.currentElapsed())
        isPaused = record.isPaused
    }

    private func persistSessionState() {
        ActiveSunSessionPersistence.persist(
            plan: plan,
            elapsedSeconds: elapsedSeconds,
            isPaused: isPaused
        )
        BigDoseWidgetActiveSessionUpdater.publish(
            plan: plan,
            elapsedSeconds: elapsedSeconds,
            isPaused: isPaused
        )
    }

    private func syncLiveActivity() {
        guard !sessionEnded else { return }
        guard !SunSessionLiveActivityCommandStore.hasPendingEnd(for: plan.liveActivitySessionID) else { return }

        SunSessionLiveActivityCoordinator.shared.sync(
            plan: plan,
            elapsedSeconds: elapsedSeconds,
            isPaused: isPaused,
            optedIn: SunSessionLiveActivityCoordinator.isOptedIn
        )
    }

    private func startBackgroundLiveActivitySyncIfNeeded() {
        guard !isPaused, !sessionEnded else { return }

        backgroundLiveActivitySyncTask?.cancel()
        backgroundLiveActivitySyncTask = Task { @MainActor in
            await SunSessionLiveActivityBackgroundPusher.run(
                shouldContinue: {
                    !sessionEnded && !isPaused && UIApplication.shared.applicationState != .active
                },
                tick: {
                    syncLiveActivity()
                }
            )
            backgroundLiveActivitySyncTask = nil
        }
    }

    private func consumeLiveActivityCommands() {
        guard let command = SunSessionLiveActivityCommandStore.consume(for: plan.liveActivitySessionID) else {
            return
        }

        switch command {
        case .pause:
            if !isPaused {
                isPaused = true
                persistSessionState()
                syncLiveActivity()
            }
        case .resume:
            if isPaused {
                isPaused = false
                persistSessionState()
                syncLiveActivity()
            }
        case .end:
            complete()
        }
    }

    private func complete() {
        guard !sessionEnded else { return }
        sessionEnded = true

        backgroundLiveActivitySyncTask?.cancel()
        backgroundLiveActivitySyncTask = nil
        SessionSafetyNotificationService.cancelSessionNotifications()

        let result = SunSessionResult(
            plan: plan,
            endedAt: .now,
            elapsedSeconds: max(elapsedSeconds, 1),
            estimatedIU: estimatedIU
        )

        SunSessionSessionCleanup.finishSession(clearPendingCommandFor: plan.liveActivitySessionID)
        onComplete(result)
    }

    private func cancel() {
        guard !sessionEnded else { return }
        sessionEnded = true

        backgroundLiveActivitySyncTask?.cancel()
        backgroundLiveActivitySyncTask = nil
        SessionSafetyNotificationService.cancelSessionNotifications()
        SunSessionSessionCleanup.finishSession(clearPendingCommandFor: plan.liveActivitySessionID)
        onCancel()
    }

    private func refreshSessionSafetyNotifications() async {
        await SessionSafetyNotificationService.schedule(for: plan, enabled: wantsSessionSafetyAlerts)
    }

    private func evaluateSafetyAlerts() {
        guard wantsSessionSafetyAlerts else { return }
        if !didShowTurnOverAlert, elapsedSeconds >= plan.turnOverAlertSeconds {
            didShowTurnOverAlert = true
            activeAlert = .turnOver
            SessionSafetyNotificationService.cancelTurnOverNotification()
        }

        if !didShowMedWarningAlert, elapsedSeconds >= plan.medWarningSeconds {
            didShowMedWarningAlert = true
            activeAlert = .medWarning
            SessionSafetyNotificationService.cancelMedWarningNotification()
        }

        if !didShowPrepareExitAlert, elapsedSeconds >= plan.prepareExitAlertSeconds {
            didShowPrepareExitAlert = true
            activeAlert = .prepareExit(countdown: plan.prepareExitCountdownText)
            SessionSafetyNotificationService.cancelPrepareExitNotification()
        }

        if !didShowStopAlert, elapsedSeconds >= plan.stopAlertSeconds {
            didShowStopAlert = true
            isPaused = true
            activeAlert = .stop
            SessionSafetyNotificationService.cancelStopNotification()
        }
    }

    private func durationText(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

private enum SunSessionSafetyAlert: Identifiable, Equatable {
    case turnOver
    case medWarning
    case prepareExit(countdown: String)
    case stop

    var id: String {
        switch self {
        case .turnOver:
            "turnOver"
        case .medWarning:
            "medWarning"
        case .prepareExit:
            "prepareExit"
        case .stop:
            "stop"
        }
    }

    var feedbackKind: BigDoseAlertFeedback.Kind {
        switch self {
        case .turnOver, .medWarning, .prepareExit:
            .warning
        case .stop:
            .critical
        }
    }
}

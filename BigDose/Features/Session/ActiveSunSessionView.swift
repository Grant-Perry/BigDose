import Combine
import SwiftUI
import UIKit

struct ActiveSunSessionView: View {
    var wantsSessionSafetyAlerts: Bool
    var wantsNannyMode: Bool
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
    @State private var didShowGuidanceLimitAlert = false
    @State private var didShowNannyReminderAlert = false
    @State private var isShowingSkinCoverage = false
    @State private var isShowingGoalPicker = false
    @State private var isShowingCancelConfirmation = false
    @State private var isShowingStopConfirmation = false
    @State private var isShowingFirstSessionGuide = false
    @State private var backgroundLiveActivitySyncTask: Task<Void, Never>?
    @State private var sessionEnded = false

    @AppStorage("hasSeenFirstSunSessionGuide") private var hasSeenFirstSunSessionGuide = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(
        plan: SunSessionPlan,
        wantsSessionSafetyAlerts: Bool,
        wantsNannyMode: Bool = true,
        onCancel: @escaping () -> Void,
        onComplete: @escaping (SunSessionResult) -> Void
    ) {
        _plan = State(initialValue: plan)
        self.wantsSessionSafetyAlerts = wantsSessionSafetyAlerts
        self.wantsNannyMode = wantsNannyMode
        self.onCancel = onCancel
        self.onComplete = onComplete
    }

    private var estimatedIU: Double {
        plan.estimatedIU(at: elapsedSeconds)
    }

    private var goalProgress: Double {
        plan.goalProgress(at: elapsedSeconds)
    }

    private var medUsedPercent: Int {
        plan.medUsedPercent(at: elapsedSeconds)
    }

    private var iuRateColor: Color {
        plan.isTraceVitaminDConditions ? .white.opacity(0.45) : .green
    }

    var body: some View {
        ZStack {
            BigDoseGradientBackground()

            VStack(spacing: 22) {
                header
                if plan.isOutsideVitaminDWindow {
                    outsideWindowBanner
                }
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
        }
        .task {
            restoreSessionStateIfNeeded()
            persistSessionState()
            await refreshSessionSafetyNotifications()
            consumeLiveActivityCommands()
            guard !sessionEnded else { return }
            syncLiveActivity()

            if !hasSeenFirstSunSessionGuide {
                isShowingFirstSessionGuide = true
            }
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
        .bigDoseAlert(item: $activeAlert) { alert in
            switch alert {
            case .turnOver:
                BigDoseAlertContent(
                    title: "Turn over",
                    message: plan.safetyAlertMessage(for: .turnOver, elapsedSeconds: elapsedSeconds),
                    actions: [.default("Got it")]
                )
            case .medWarning:
                BigDoseAlertContent(
                    title: "Approaching exposure limit",
                    message: plan.safetyAlertMessage(for: .medWarning, elapsedSeconds: elapsedSeconds),
                    actions: [.default("OK")]
                )
            case .prepareExit(let countdown):
                BigDoseAlertContent(
                    title: "Get ready to exit sun",
                    message: plan.safetyAlertMessage(for: .prepareExit(countdown: countdown), elapsedSeconds: elapsedSeconds),
                    actions: [.default("Got it")]
                )
            case .overLimit(let percent):
                BigDoseAlertContent(
                    title: overLimitAlertTitle(for: percent),
                    message: plan.safetyAlertMessage(for: .overLimit(percent: percent), elapsedSeconds: elapsedSeconds),
                    actions: [.default("I'm Still Out Here")]
                )
            }
        }
        .onChange(of: activeAlert) { _, alert in
            guard let alert else { return }
            BigDoseAlertFeedback.present(kind: alert.feedbackKind)
        }
        .sheet(isPresented: $isShowingFirstSessionGuide) {
            FirstSunSessionGuideView {
                hasSeenFirstSunSessionGuide = true
                isShowingFirstSessionGuide = false
            }
            .interactiveDismissDisabled()
        }
        .sheet(isPresented: $isShowingSkinCoverage) {
            SkinExposurePickerView(exposedBodySurfaceArea: $plan.exposedBodySurfaceArea)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $isShowingGoalPicker) {
            SessionGoalPickerView(targetIU: $plan.targetIU)
                .presentationDetents([.medium])
        }
        .bigDoseAlert(
            "Cancel sun session?",
            isPresented: $isShowingCancelConfirmation,
            message: "Are you certain? This won't record this sun session if you cancel.",
            actions: [
                .destructive("Cancel Session") { cancel() },
                .cancel("Keep Going")
            ]
        )
        .bigDoseAlert(
            "Stop sun session?",
            isPresented: $isShowingStopConfirmation,
            message: "Save this session with \(Int(estimatedIU.rounded())) IU estimated so far?",
            actions: [
                .destructive("Stop & Save") { complete() },
                .cancel("Keep Going")
            ]
        )
    }

    private var outsideWindowBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "moon.stars.fill")
                .foregroundStyle(.solarGold)
            Text(plan.isTraceVitaminDConditions ? "Outside D window — trace vitamin D only" : "Outside D window")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.78))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.white.opacity(0.08), in: .rect(cornerRadius: 14))
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

                    if plan.medTimeSeconds > 0 {
                        Text("\(Int(plan.durationSeconds / 60)) min planned · guidance limit ~\(Int(plan.stopAlertSeconds / 60)) min")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.solarOrange)
                            .multilineTextAlignment(.center)
                    }

                    Text("\(Int(estimatedIU.rounded())) IU")
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("\(Int(plan.liveIUProductionRatePerMinute.rounded())) IU/min")
                        .font(.bigDoseHeader(.headline).weight(.semibold))
                        .foregroundStyle(iuRateColor)

                    if plan.isTraceVitaminDConditions {
                        Text("trace D — scaled for low sun angle")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.48))
                    }

                    if let minutesToGoal = plan.minutesToGoal(at: elapsedSeconds) {
                        Text("~\(minutesToGoal) min to goal")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.62))
                    } else if goalProgress >= 1 {
                        Text("Goal reached")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.solarGold)
                    }

                    HStack(spacing: 4) {
                        Text("\(Int(goalProgress * 100))% of goal")
                            .font(.bigDoseHeader(.title2).weight(.semibold))
                            .foregroundStyle(.solarGold)
                        InfoCircleButton(topic: .sessionGoal, compact: true)
                    }

                    HStack(spacing: 4) {
                        Text("MED used (burn risk): \(medUsedPercent)%")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(medUsedColor)
                        if medUsedPercent >= SunSessionSafetyThresholds.guidanceLimitPercent {
                            Text("OVER")
                                .font(.caption2.weight(.black))
                                .foregroundStyle(.red)
                        }
                        InfoCircleButton(topic: .medUsed, compact: true)
                    }
                }
            }
            .frame(height: 330)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Sun session timer, \(Int(estimatedIU.rounded())) of \(Int(plan.targetIU.rounded())) IU, \(Int(goalProgress * 100)) percent of goal")
        }
    }

    private var medUsedColor: Color {
        switch medUsedPercent {
        case 95...:
            .red
        case 75...:
            .solarOrange
        default:
            .white.opacity(0.62)
        }
    }

    private var controls: some View {
        HStack(alignment: .center, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text("\(plan.medRemainingMinutes(at: elapsedSeconds))")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.green)
                    InfoCircleButton(topic: .minToMED, compact: true)
                }

                Text("min to MED (burn risk)")
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
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background {
                        Circle()
                            .fill(isPaused ? AnyShapeStyle(Color.green) : AnyShapeStyle(.blue.gradient))
                    }
            }
            .accessibilityLabel(isPaused ? "Resume session" : "Pause session")

            Button {
                isShowingStopConfirmation = true
            } label: {
                Image(systemName: "stop.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(Color.red, in: .circle)
            }
            .accessibilityLabel("Stop and save session")
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
        await SessionSafetyNotificationService.schedule(
            for: plan,
            enabled: wantsSessionSafetyAlerts,
            wantsNannyMode: wantsNannyMode
        )
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

        let currentMedPercent = medUsedPercent
        guard activeAlert == nil else { return }

        if !didShowGuidanceLimitAlert, currentMedPercent >= SunSessionSafetyThresholds.guidanceLimitPercent {
            didShowGuidanceLimitAlert = true
            activeAlert = .overLimit(percent: SunSessionSafetyThresholds.guidanceLimitPercent)
            SessionSafetyNotificationService.cancelOverLimitNotification(
                for: SunSessionSafetyThresholds.guidanceLimitPercent
            )
            return
        }

        guard wantsNannyMode else { return }
        guard !didShowNannyReminderAlert, currentMedPercent >= SunSessionSafetyThresholds.nannyReminderPercent else { return }

        didShowNannyReminderAlert = true
        activeAlert = .overLimit(percent: SunSessionSafetyThresholds.nannyReminderPercent)
        SessionSafetyNotificationService.cancelOverLimitNotification(
            for: SunSessionSafetyThresholds.nannyReminderPercent
        )
    }

    private func overLimitAlertTitle(for percent: Int) -> String {
        if percent == SunSessionSafetyThresholds.guidanceLimitPercent {
            "Past guidance limit"
        } else if percent == SunSessionSafetyThresholds.nannyReminderPercent {
            "Still in the sun — 98% MED (burn risk)"
        } else {
            "Still in the sun — \(percent)% MED (burn risk)"
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
    case overLimit(percent: Int)

    var id: String {
        switch self {
        case .turnOver:
            "turnOver"
        case .medWarning:
            "medWarning"
        case .prepareExit:
            "prepareExit"
        case .overLimit(let percent):
            "overLimit.\(percent)"
        }
    }

    var feedbackKind: BigDoseAlertFeedback.Kind {
        switch self {
        case .turnOver, .medWarning, .prepareExit:
            .warning
        case .overLimit:
            .critical
        }
    }
}

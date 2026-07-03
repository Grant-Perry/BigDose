import Combine
import SwiftUI

struct ActiveSunSessionView: View {
    var wantsSessionSafetyAlerts: Bool
    var wantsActiveSessionReminders: Bool
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
    @State private var didShowGuidanceLimitAlert = false
    @State private var didShowNannyReminderAlert = false
    @State private var didShowFullMEDAlert = false
    @State private var didShowGoalReachedAlert = false
    @State private var isShowingSkinCoverage = false
    @State private var isShowingGoalPicker = false
    @State private var isShowingCancelConfirmation = false
    @State private var isShowingStopConfirmation = false
    @State private var isShowingStaleSessionAlert = false
    @State private var isShowingInactivityRecoveryAlert = false
    @State private var isShowingFirstSessionGuide = false
    @State private var sessionEnded = false

    @AppStorage("hasSeenFirstSunSessionGuide") private var hasSeenFirstSunSessionGuide = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(
        plan: SunSessionPlan,
        wantsSessionSafetyAlerts: Bool,
        wantsActiveSessionReminders: Bool = true,
        wantsNannyMode: Bool = true,
        onCancel: @escaping () -> Void,
        onComplete: @escaping (SunSessionResult) -> Void
    ) {
        _plan = State(initialValue: plan)
        self.wantsSessionSafetyAlerts = wantsSessionSafetyAlerts
        self.wantsActiveSessionReminders = wantsActiveSessionReminders
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

    private var goalProgressUncapped: Double {
        plan.goalProgressUncapped(at: elapsedSeconds)
    }

    private var goalRingProgress: Double {
        min(goalProgressUncapped, 1)
    }

    private var overGoalRingProgress: Double {
        max(0, goalProgressUncapped - 1)
    }

    private var medUsedPercentText: String {
        String(format: "%.1f%%", plan.medUsedFraction(at: elapsedSeconds) * 100)
    }

    private var medUsedPercent: Int {
        plan.medUsedPercent(at: elapsedSeconds)
    }

    private var hasPassedTurnOver: Bool {
        elapsedSeconds >= plan.turnOverAlertSeconds
    }

    private var iuRateColor: Color {
        plan.isTraceVitaminDConditions ? .white.opacity(0.45) : .green
    }

    var body: some View {
        ZStack {
            BigDoseGradientBackground()

            ScrollView {
                VStack(spacing: 0) {
                    header
                        .padding(.bottom, 16)

                    if plan.isOutsideVitaminDWindow {
                        outsideWindowBanner
                            .padding(.bottom, 14)
                    }

                    heroDialSection
                        .padding(.bottom, 20)

                    sessionControls
                        .padding(.bottom, 22)

                    modifiersCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 2)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
        .onReceive(timer) { _ in
            consumeLiveActivityCommands()

            if Int(elapsedSeconds) % 5 == 0 {
                persistSessionState()
            }

            guard !isPaused, !sessionEnded else { return }
            elapsedSeconds += 1
            BigDoseWidgetReloader.reloadHomeWidget()
            evaluateSessionAlerts()
        }
        .task {
            restoreSessionStateIfNeeded()
            persistSessionState()
            await refreshSessionSafetyNotifications()
            await refreshActiveSessionReminder()
            consumeLiveActivityCommands()
            guard !sessionEnded else { return }
            syncLiveActivity()
            guard !isShowingInactivityRecoveryAlert else { return }
            evaluateSessionAlerts()
            evaluateStaleSessionAlert()

            if !hasSeenFirstSunSessionGuide {
                isShowingFirstSessionGuide = true
            }
        }
        .onChange(of: isPaused) { _, _ in
            persistSessionState()
            syncLiveActivity()
            Task { await refreshActiveSessionReminder() }
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
                consumeLiveActivityCommands()
                syncLiveActivity()
                evaluateStaleSessionAlert()
            case .inactive, .background:
                syncLiveActivity()
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
            case .overLimit(let percent):
                if percent == SunSessionSafetyThresholds.fullMEDPercent {
                    BigDoseAlertContent(
                        title: overLimitAlertTitle(for: percent),
                        message: plan.safetyAlertMessage(for: .overLimit(percent: percent), elapsedSeconds: elapsedSeconds),
                        actions: [
                            .destructive("Stop Session") { complete() },
                            .default("I'm Still Out Here")
                        ]
                    )
                } else {
                    BigDoseAlertContent(
                        title: overLimitAlertTitle(for: percent),
                        message: plan.safetyAlertMessage(for: .overLimit(percent: percent), elapsedSeconds: elapsedSeconds),
                        actions: [.default("I'm Still Out Here")]
                    )
                }
            case .goalReached:
                BigDoseAlertContent(
                    title: "Goal reached",
                    message: plan.safetyAlertMessage(for: .goalReached, elapsedSeconds: elapsedSeconds),
                    actions: [.default("Got it")]
                )
            }
        }
        .onChange(of: activeAlert) { oldValue, newValue in
            if let newValue {
                BigDoseAlertFeedback.present(kind: newValue.feedbackKind)
            }

            if newValue == nil, oldValue != nil {
                evaluateSessionAlerts()
            }
        }
        .sheet(isPresented: $isShowingFirstSessionGuide) {
            FirstSunSessionGuideView {
                hasSeenFirstSunSessionGuide = true
                isShowingFirstSessionGuide = false
                evaluateSessionAlerts()
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
        .bigDoseAlert(
            "Still tracking sun",
            isPresented: $isShowingStaleSessionAlert,
            message: ActiveSessionReminderService.staleSessionMessage(for: plan, elapsedSeconds: elapsedSeconds),
            actions: [
                .destructive("Stop & Save") { complete() },
                .default("Keep Going")
            ]
        )
        .bigDoseAlert(
            "Resume sun session?",
            isPresented: $isShowingInactivityRecoveryAlert,
            message: inactivityRecoveryMessage,
            actions: [
                .default("Still Outside") { resumeAfterInactivityRecovery() },
                .destructive("Stop & Save") { complete() },
                .cancel("Cancel Session") { cancel() }
            ]
        )
    }

    private var inactivityRecoveryMessage: String {
        guard let record = ActiveSunSessionStore.load() else {
            return "BigDose lost contact with this session. Away time was not added. Still outside, or stop and save?"
        }

        return ActiveSessionRecoveryService.recoveryMessage(for: record, plan: plan)
    }

    private var outsideWindowBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.solarGold)

            Text(plan.isTraceVitaminDConditions ? "Outside D window — trace vitamin D only" : "Outside D window")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .bigDoseGlass(cornerRadius: 16)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(plan.locationName.uppercased())
                    .font(.bigDoseHeader(.title2))
                    .tracking(1.4)
                    .foregroundStyle(.white)
                    .padding(.top, 2)

                HStack(spacing: 6) {
                    weatherChip("\(Int(plan.currentTemperatureFahrenheit.rounded()))°")
                    weatherChip("UV \(plan.uvIndex.formatted(.number.precision(.fractionLength(1))))")
                    weatherChip(plan.cloudCover.title)
                }
            }

            Spacer(minLength: 12)

            Button("Cancel") {
                isShowingCancelConfirmation = true
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(.white.opacity(0.48))
            .padding(.top, 6)
        }
    }

    private func weatherChip(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.55))
    }

    private var heroDialSection: some View {
        VStack(spacing: 14) {
            dialGoalCaption

            ZStack {
                SunSessionGlassDial(
                    goalProgress: goalRingProgress,
                    overGoalProgress: overGoalRingProgress,
                    goalProgressAtFullMED: plan.goalProgressAtFullMED,
                    medUsedFraction: plan.medUsedFraction(at: elapsedSeconds),
                    goalDurationMinutes: plan.goalDurationMinutes,
                    diameter: 278,
                    lineWidth: 16,
                    isPaused: isPaused
                )

                dialCenterContent

                if isPaused {
                    pausedOverlay
                }
            }

            dialGoalFooter
                .padding(.top, -2)

            safetyMetricsStrip
                .padding(.top, 6)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(dialAccessibilityLabel)
    }

    private var dialGoalCaption: some View {
        VStack(spacing: 3) {
            Text("\(Int(plan.targetIU.rounded())) IU GOAL")
                .font(.caption.weight(.black))
                .tracking(1.2)
                .foregroundStyle(.solarGold.opacity(0.88))

            Text("\(plan.goalDurationMinutes) MIN RING")
                .font(.caption2.weight(.semibold))
                .tracking(0.9)
                .foregroundStyle(.white.opacity(0.38))
        }
        .frame(maxWidth: .infinity)
    }

    private var dialGoalFooter: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text("0 min")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.42))

                goalTimeStatusLabel
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(plan.goalDurationMinutes) min")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.42))

                goalPercentBadge
            }
        }
        .padding(.horizontal, 28)
    }

    @ViewBuilder
    private var goalTimeStatusLabel: some View {
        if let minutesToGoal = plan.minutesToGoal(at: elapsedSeconds) {
            Text("~\(minutesToGoal) min to goal")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.55))
        } else if goalProgressUncapped >= 1 {
            Text("Goal reached")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(overGoalRingProgress > 0 ? Color.gpRedPink : Color.solarGold)
        }
    }

    private var goalPercentBadge: some View {
        HStack(spacing: 5) {
            Text("\(Int(goalProgressUncapped * 100))% OF GOAL")
                .font(.caption.weight(.black))
                .tracking(1.2)
                .foregroundStyle(overGoalRingProgress > 0 ? Color.gpRedPink : Color.solarGold)

            InfoCircleButton(topic: .sessionGoal, compact: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            (overGoalRingProgress > 0 ? Color.gpRedPink : Color.solarGold).opacity(0.12),
            in: .capsule
        )
    }

    private var dialCenterContent: some View {
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(Int(estimatedIU.rounded()))")
                    .font(.bigDoseDisplay(68))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                Text("IU")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white.opacity(0.42))
            }
            .lineLimit(1)
            .minimumScaleFactor(0.5)

            Text(durationText(elapsedSeconds))
                .font(.system(size: 34, weight: .light, design: .monospaced))
                .foregroundStyle(.white.opacity(0.78))
                .monospacedDigit()
                .contentTransition(.numericText())

            iuRateBadge

            if plan.isTraceVitaminDConditions {
                Text("trace D — scaled for low sun angle")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.38))
                    .multilineTextAlignment(.center)
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal, 24)
    }

    private var iuRateBadge: some View {
        HStack(spacing: 4) {
            Text("\(Int(plan.liveIUProductionRatePerMinute.rounded()))")
                .font(.bigDoseHeader(.headline))
            Text("IU/MIN")
                .font(.caption2.weight(.bold))
                .tracking(1.1)
        }
        .foregroundStyle(iuRateColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(iuRateColor.opacity(0.12), in: .capsule)
        .overlay {
            Capsule()
                .stroke(iuRateColor.opacity(0.22), lineWidth: 1)
        }
        .padding(.top, 4)
        .lineLimit(1)
        .minimumScaleFactor(0.5)
    }

    private var pausedOverlay: some View {
        Text("PAUSED")
            .font(.caption.weight(.black))
            .tracking(2.4)
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(.black.opacity(0.45), in: .capsule)
            .overlay {
                Capsule()
                    .stroke(.white.opacity(0.18), lineWidth: 1)
            }
            .offset(y: 122)
    }

    private var safetyMetricsStrip: some View {
        HStack(alignment: .top, spacing: 10) {
            safetyMetricCell(
                value: countdownText(plan.medRemainingSeconds(at: elapsedSeconds)),
                label: "min to MED",
                valueColor: .gpHiGreen,
                infoTopic: .minToMED,
                usesMonospacedValue: true
            )

            safetyMetricCell(
                value: medUsedPercentText,
                label: medUsedLabel,
                valueColor: medUsedColor,
                infoTopic: .medUsed,
                showsOverBadge: medUsedPercent >= SunSessionSafetyThresholds.guidanceLimitPercent,
                usesMonospacedValue: true
            )

            if hasPassedTurnOver {
                safetyMetricCell(
                    value: countdownText(plan.medRemainingSeconds(at: elapsedSeconds)),
                    label: "min to 100% MED",
                    valueColor: .gpHiGreen,
                    infoTopic: .minToMED,
                    usesMonospacedValue: true
                )
            } else {
                safetyMetricCell(
                    value: countdownText(plan.turnOverRemainingSeconds(at: elapsedSeconds)),
                    label: "min to roll-over",
                    valueColor: .gpHiGreen,
                    infoTopic: BigDoseInfoTopic.minToRollOver,
                    usesMonospacedValue: true
                )
            }
        }
    }

    private var medUsedLabel: String {
        "MED (burn risk)"
    }

    private func safetyMetricCell(
        value: String,
        label: String,
        valueColor: Color,
        infoTopic: BigDoseInfoTopic? = nil,
        showsOverBadge: Bool = false,
        usesMonospacedValue: Bool = false
    ) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Text(value)
                    .font(valueFont(monospaced: usesMonospacedValue))
                    .foregroundStyle(valueColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                if showsOverBadge {
                    Text("OVER")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(Color.gpRedPink)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.gpRedPink.opacity(0.18), in: .capsule)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(maxWidth: .infinity)
            .frame(height: 38)

            HStack(alignment: .top, spacing: 3) {
                Text(label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.42))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)

                if let infoTopic {
                    InfoCircleButton(topic: infoTopic, compact: true)
                        .padding(.top, 1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(height: 32, alignment: .top)
        }
        .frame(maxWidth: .infinity, minHeight: 108, maxHeight: 108)
        .padding(.horizontal, 6)
        .bigDoseGlass(cornerRadius: 18)
    }

    private func valueFont(monospaced: Bool) -> Font {
        if monospaced {
            .system(size: 30, weight: .semibold, design: .monospaced)
        } else {
            .bigDoseDisplay(42)
        }
    }

    private func countdownText(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded(.down)))
        let minutes = total / 60
        let remainder = total % 60
        return "\(minutes):\(String(format: "%02d", remainder))"
    }

    private var dialAccessibilityLabel: String {
        "Sun session timer, \(Int(estimatedIU.rounded())) of \(Int(plan.targetIU.rounded())) IU, \(Int(goalProgressUncapped * 100)) percent of goal"
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

    private var sessionControls: some View {
        HStack(spacing: 28) {
            SessionControlButton(style: .pause(isPaused: isPaused)) {
                withAnimation(.smooth) {
                    isPaused.toggle()
                }
            }

            SessionControlButton(style: .stop) {
                isShowingStopConfirmation = true
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var modifiersCard: some View {
        VStack(spacing: 0) {
            Button {
                isShowingSkinCoverage = true
            } label: {
                sessionModifierRow(
                    title: "Skin Coverage",
                    value: SkinExposurePreset.coverageLabel(for: plan.exposedBodySurfaceArea),
                    icon: "person.fill"
                )
            }
            .buttonStyle(.plain)

            modifierDivider

            Menu {
                ForEach(CloudCoverPreset.allCases) { preset in
                    Button(preset.title) {
                        plan.cloudCover = preset
                    }
                }
            } label: {
                sessionModifierRow(
                    title: "Clouds",
                    value: plan.cloudCover.title,
                    icon: "cloud.sun.fill"
                )
            }

            modifierDivider

            Button {
                isShowingGoalPicker = true
            } label: {
                sessionModifierRow(
                    title: "Goal",
                    value: "\(Int(plan.targetIU.rounded())) IU",
                    icon: "target"
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
        .bigDoseGlass(cornerRadius: 24)
    }

    private var modifierDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.08))
            .frame(height: 1)
            .padding(.horizontal, 18)
    }

    private func sessionModifierRow(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.07))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.solarGold)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(1.3)
                    .foregroundStyle(.white.opacity(0.38))

                Text(value)
                    .font(.bigDoseHeader(.headline))
                    .foregroundStyle(.white.opacity(0.88))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.28))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .contentShape(.rect)
    }

    private func restoreSessionStateIfNeeded() {
        guard let record = ActiveSunSessionStore.load(),
              record.sessionID == plan.liveActivitySessionID else {
            return
        }

        if ActiveSessionRecoveryService.needsRecovery(for: record) {
            elapsedSeconds = ActiveSessionRecoveryService.restoredElapsedSeconds(for: record)
            isPaused = true
            isShowingInactivityRecoveryAlert = true
            restoreAcknowledgedSafetyAlerts(from: record)
            return
        }

        elapsedSeconds = max(elapsedSeconds, record.currentElapsed())
        isPaused = record.isPaused
        restoreAcknowledgedSafetyAlerts(from: record)
        syncHistoricalSafetyAcknowledgements()
    }

    private func resumeAfterInactivityRecovery() {
        withAnimation(.smooth) {
            isPaused = false
        }
        persistSessionState()
        syncLiveActivity()
        Task {
            await refreshSessionSafetyNotifications()
            await refreshActiveSessionReminder()
        }
        evaluateSessionAlerts()
        evaluateStaleSessionAlert()
    }

    private func persistSessionState() {
        ActiveSunSessionPersistence.persist(
            plan: plan,
            elapsedSeconds: elapsedSeconds,
            isPaused: isPaused,
            acknowledgedSafetyAlertIDs: currentAcknowledgedSafetyAlertIDs()
        )
        BigDoseWidgetActiveSessionUpdater.publish(
            plan: plan,
            elapsedSeconds: elapsedSeconds,
            isPaused: isPaused
        )
        Task { await refreshActiveSessionReminder() }
    }

    private func currentAcknowledgedSafetyAlertIDs() -> [String] {
        var ids: [String] = []
        if didShowGoalReachedAlert { ids.append(ActiveSunSessionSafetyAlertID.goalReached) }
        if didShowTurnOverAlert { ids.append(ActiveSunSessionSafetyAlertID.turnOver) }
        if didShowMedWarningAlert { ids.append(ActiveSunSessionSafetyAlertID.medWarning) }
        if didShowGuidanceLimitAlert {
            ids.append(ActiveSunSessionSafetyAlertID.overLimit(percent: SunSessionSafetyThresholds.guidanceLimitPercent))
        }
        if didShowNannyReminderAlert {
            ids.append(ActiveSunSessionSafetyAlertID.overLimit(percent: SunSessionSafetyThresholds.nannyReminderPercent))
        }
        if didShowFullMEDAlert {
            ids.append(ActiveSunSessionSafetyAlertID.overLimit(percent: SunSessionSafetyThresholds.fullMEDPercent))
        }
        return ids
    }

    private func restoreAcknowledgedSafetyAlerts(from record: ActiveSunSessionRecord) {
        applyAcknowledgedSafetyAlertIDs(Set(record.acknowledgedSafetyAlertIDs))
    }

    private func syncHistoricalSafetyAcknowledgements() {
        var ids = Set(currentAcknowledgedSafetyAlertIDs())

        if plan.hasReachedGoal(at: elapsedSeconds) {
            ids.insert(ActiveSunSessionSafetyAlertID.goalReached)
        }
        if elapsedSeconds >= plan.turnOverAlertSeconds {
            ids.insert(ActiveSunSessionSafetyAlertID.turnOver)
        }
        if wantsNannyMode, elapsedSeconds >= plan.medWarningSeconds {
            ids.insert(ActiveSunSessionSafetyAlertID.medWarning)
        }
        if wantsNannyMode {
            let currentMedPercent = medUsedPercent
            if currentMedPercent >= SunSessionSafetyThresholds.guidanceLimitPercent {
                ids.insert(ActiveSunSessionSafetyAlertID.overLimit(percent: SunSessionSafetyThresholds.guidanceLimitPercent))
            }
            if currentMedPercent >= SunSessionSafetyThresholds.nannyReminderPercent {
                ids.insert(ActiveSunSessionSafetyAlertID.overLimit(percent: SunSessionSafetyThresholds.nannyReminderPercent))
            }
        }
        if plan.hasReachedFullMED(at: elapsedSeconds) {
            ids.insert(ActiveSunSessionSafetyAlertID.overLimit(percent: SunSessionSafetyThresholds.fullMEDPercent))
        }

        let previousIDs = Set(currentAcknowledgedSafetyAlertIDs())
        guard ids != previousIDs else { return }

        applyAcknowledgedSafetyAlertIDs(ids)
        persistSessionState()
    }

    private func applyAcknowledgedSafetyAlertIDs(_ ids: Set<String>) {
        didShowGoalReachedAlert = ids.contains(ActiveSunSessionSafetyAlertID.goalReached)
        didShowTurnOverAlert = ids.contains(ActiveSunSessionSafetyAlertID.turnOver)
        didShowMedWarningAlert = ids.contains(ActiveSunSessionSafetyAlertID.medWarning)
        didShowGuidanceLimitAlert = ids.contains(
            ActiveSunSessionSafetyAlertID.overLimit(percent: SunSessionSafetyThresholds.guidanceLimitPercent)
        )
        didShowNannyReminderAlert = ids.contains(
            ActiveSunSessionSafetyAlertID.overLimit(percent: SunSessionSafetyThresholds.nannyReminderPercent)
        )
        didShowFullMEDAlert = ids.contains(
            ActiveSunSessionSafetyAlertID.overLimit(percent: SunSessionSafetyThresholds.fullMEDPercent)
        )
    }

    private func markSafetyAlertShown(_ alertID: String) {
        applyAcknowledgedSafetyAlertIDs(Set(currentAcknowledgedSafetyAlertIDs() + [alertID]))
        persistSessionState()
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

        SessionSafetyNotificationService.cancelSessionNotifications()
        ActiveSessionReminderService.cancel()

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

        SessionSafetyNotificationService.cancelSessionNotifications()
        ActiveSessionReminderService.cancel()
        SunSessionSessionCleanup.finishSession(clearPendingCommandFor: plan.liveActivitySessionID)
        onCancel()
    }

    private func refreshSessionSafetyNotifications() async {
        await SessionSafetyNotificationService.schedule(
            for: plan,
            enabled: wantsSessionSafetyAlerts,
            wantsNannyMode: wantsNannyMode,
            elapsedSeconds: elapsedSeconds
        )
    }

    private func refreshActiveSessionReminder() async {
        await ActiveSessionReminderService.schedule(
            for: plan,
            elapsedSeconds: elapsedSeconds,
            isPaused: isPaused,
            enabled: wantsActiveSessionReminders
        )
    }

    private func evaluateStaleSessionAlert() {
        guard !sessionEnded, !isShowingFirstSessionGuide, !isShowingInactivityRecoveryAlert else { return }
        guard activeAlert == nil, !isShowingStopConfirmation else { return }
        guard ActiveSessionReminderService.isStale(
            for: plan,
            elapsedSeconds: elapsedSeconds,
            isPaused: isPaused
        ) else { return }

        isShowingStaleSessionAlert = true
    }

    private func evaluateSessionAlerts() {
        guard !isShowingFirstSessionGuide, !isShowingInactivityRecoveryAlert else { return }
        guard activeAlert == nil else { return }
        evaluateGoalAlert()
        guard activeAlert == nil else { return }
        evaluateSafetyAlerts()
    }

    private func evaluateGoalAlert() {
        guard !didShowGoalReachedAlert else { return }
        guard plan.hasReachedGoal(at: elapsedSeconds) else { return }

        markSafetyAlertShown(ActiveSunSessionSafetyAlertID.goalReached)
        activeAlert = .goalReached
    }

    private func evaluateSafetyAlerts() {
        guard wantsSessionSafetyAlerts else { return }

        if !didShowTurnOverAlert, elapsedSeconds >= plan.turnOverAlertSeconds {
            markSafetyAlertShown(ActiveSunSessionSafetyAlertID.turnOver)
            activeAlert = .turnOver
            SessionSafetyNotificationService.cancelTurnOverNotification()
            return
        }

        if wantsNannyMode {
            if !didShowMedWarningAlert, elapsedSeconds >= plan.medWarningSeconds {
                markSafetyAlertShown(ActiveSunSessionSafetyAlertID.medWarning)
                activeAlert = .medWarning
                SessionSafetyNotificationService.cancelMedWarningNotification()
                return
            }

            let currentMedPercent = medUsedPercent

            if !didShowGuidanceLimitAlert, currentMedPercent >= SunSessionSafetyThresholds.guidanceLimitPercent {
                markSafetyAlertShown(
                    ActiveSunSessionSafetyAlertID.overLimit(percent: SunSessionSafetyThresholds.guidanceLimitPercent)
                )
                activeAlert = .overLimit(percent: SunSessionSafetyThresholds.guidanceLimitPercent)
                SessionSafetyNotificationService.cancelOverLimitNotification(
                    for: SunSessionSafetyThresholds.guidanceLimitPercent
                )
                return
            }

            if !didShowNannyReminderAlert, currentMedPercent >= SunSessionSafetyThresholds.nannyReminderPercent {
                markSafetyAlertShown(
                    ActiveSunSessionSafetyAlertID.overLimit(percent: SunSessionSafetyThresholds.nannyReminderPercent)
                )
                activeAlert = .overLimit(percent: SunSessionSafetyThresholds.nannyReminderPercent)
                SessionSafetyNotificationService.cancelOverLimitNotification(
                    for: SunSessionSafetyThresholds.nannyReminderPercent
                )
                return
            }
        }

        evaluateFullMEDAlert()
    }

    private func evaluateFullMEDAlert() {
        guard !didShowFullMEDAlert, plan.hasReachedFullMED(at: elapsedSeconds) else { return }

        markSafetyAlertShown(
            ActiveSunSessionSafetyAlertID.overLimit(percent: SunSessionSafetyThresholds.fullMEDPercent)
        )
        activeAlert = .overLimit(percent: SunSessionSafetyThresholds.fullMEDPercent)
        SessionSafetyNotificationService.cancelOverLimitNotification(
            for: SunSessionSafetyThresholds.fullMEDPercent
        )
    }

    private func overLimitAlertTitle(for percent: Int) -> String {
        if percent == SunSessionSafetyThresholds.guidanceLimitPercent {
            "Past guidance limit"
        } else if percent == SunSessionSafetyThresholds.nannyReminderPercent {
            "Still in the sun — 98% MED (burn risk)"
        } else if percent == SunSessionSafetyThresholds.fullMEDPercent {
            "100% MED (burn risk) — stop now"
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
    case overLimit(percent: Int)
    case goalReached

    var id: String {
        switch self {
        case .turnOver:
            "turnOver"
        case .medWarning:
            "medWarning"
        case .overLimit(let percent):
            "overLimit.\(percent)"
        case .goalReached:
            "goalReached"
        }
    }

    var feedbackKind: BigDoseAlertFeedback.Kind {
        switch self {
        case .turnOver, .medWarning, .goalReached:
            .warning
        case .overLimit:
            .critical
        }
    }
}

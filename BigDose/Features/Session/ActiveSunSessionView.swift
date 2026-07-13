import Combine
import SwiftUI

struct ActiveSunSessionView: View {
    var wantsSessionSafetyAlerts: Bool
    var wantsActiveSessionReminders: Bool
    var wantsNannyMode: Bool
    var weatherAttribution: BigDoseWeatherAttribution = .standard
    var onCancel: () -> Void
    var onComplete: (SunSessionResult) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppAppearancePreference.storageKey)
    private var appAppearanceRawValue = AppAppearancePreference.system.rawValue
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
    @State private var isShowingCloudCover = false
    @State private var presentedSheet: ActiveSunSessionSheet?
    @State private var isShowingCancelConfirmation = false
    @State private var isShowingStopConfirmation = false
    @State private var isShowingStaleSessionAlert = false
    @State private var isShowingInactivityRecoveryAlert = false
    @State private var sessionEnded = false

    @AppStorage("hasSeenFirstSunSessionGuide") private var hasSeenFirstSunSessionGuide = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(
        plan: SunSessionPlan,
        weatherAttribution: BigDoseWeatherAttribution? = nil,
        wantsSessionSafetyAlerts: Bool,
        wantsActiveSessionReminders: Bool = true,
        wantsNannyMode: Bool = true,
        onCancel: @escaping () -> Void,
        onComplete: @escaping (SunSessionResult) -> Void
    ) {
        _plan = State(initialValue: plan)
        self.weatherAttribution = weatherAttribution ?? .standard
        self.wantsSessionSafetyAlerts = wantsSessionSafetyAlerts
        self.wantsActiveSessionReminders = wantsActiveSessionReminders
        self.wantsNannyMode = wantsNannyMode
        self.onCancel = onCancel
        self.onComplete = onComplete
    }

    private var estimatedIU: Double {
        plan.estimatedIU(at: elapsedSeconds)
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
            ActiveSunSessionBackground()

            ScrollView {
                VStack(spacing: 12) {
                    header

                    if plan.isOutsideVitaminDWindow {
                        outsideWindowBanner
                    }

                    ActiveSunSessionHeroCard(
                        elapsedText: durationText(elapsedSeconds),
                        estimatedIU: Int(estimatedIU.rounded()),
                        targetIU: Int(plan.targetIU.rounded()),
                        iuPerMinute: Int(plan.liveIUProductionRatePerMinute.rounded()),
                        goalProgress: goalProgressUncapped,
                        minutesToGoal: plan.minutesToGoal(at: elapsedSeconds),
                        isTraceVitaminDConditions: plan.isTraceVitaminDConditions,
                        isPaused: isPaused,
                        onGoalTap: presentGoalPicker
                    )

                    ActiveSunSessionMetricsGrid(
                        medRemainingText: countdownText(plan.medRemainingSeconds(at: elapsedSeconds)),
                        medUsedText: medUsedPercentText,
                        medUsedColor: medUsedColor,
                        showsOverBadge: medUsedPercent >= SunSessionSafetyThresholds.guidanceLimitPercent,
                        turnOverText: hasPassedTurnOver
                            ? countdownText(plan.medRemainingSeconds(at: elapsedSeconds))
                            : countdownText(plan.turnOverRemainingSeconds(at: elapsedSeconds)),
                        hasPassedTurnOver: hasPassedTurnOver
                    )

                    modifiersCard
                        .zIndex(1)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 36)
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            sessionControls
        }
        .preferredColorScheme(appAppearance.colorScheme)
        .onReceive(timer) { _ in
            consumeLiveActivityCommands()

            guard !isPaused, !sessionEnded else { return }
            elapsedSeconds += 1

            // App Group checkpoint only — widget ticks from runningSince / .timer
            // and Live Activity owns its own timeline. Avoid WidgetCenter reloads.
            if Int(elapsedSeconds) % 5 == 0 {
                checkpointSessionState()
            }

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
                presentedSheet = .firstSessionGuide
            }
        }
        .onChange(of: isPaused) { _, _ in
            persistSessionState()
            syncLiveActivity()
            Task {
                await refreshSessionSafetyNotifications()
                await refreshActiveSessionReminder()
            }
        }
        .onChange(of: plan.exposedBodySurfaceArea) { _, _ in
            persistSessionState()
            syncLiveActivity()
            Task { await refreshSessionSafetyNotifications() }
        }
        .onChange(of: plan.cloudCover) { _, _ in
            persistSessionState()
            syncLiveActivity()
            Task { await refreshSessionSafetyNotifications() }
        }
        .onChange(of: plan.targetIU) { _, _ in
            clearGoalReachedAlertIfNeeded()
            persistSessionState()
            syncLiveActivity()
            Task { await refreshSessionSafetyNotifications() }
            evaluateGoalAlert()
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                // Commands first: LA pause/resume/end already froze App Group elapsed.
                consumeLiveActivityCommands()
                reconcileElapsedFromPersistedState()
                syncLiveActivity()
                evaluateStaleSessionAlert()
            case .inactive, .background:
                persistSessionState()
                syncLiveActivity()
            @unknown default:
                break
            }
        }
        .bigDoseAlert(item: $activeAlert, isOpaque: true) { alert in
            switch alert {
            case .turnOver:
                BigDoseAlertContent(
                    title: "Turn over",
                    message: plan.safetyAlertMessage(for: .turnOver, elapsedSeconds: elapsedSeconds),
                    actions: [.default("Got it", systemImage: "checkmark")]
                )
            case .medWarning:
                BigDoseAlertContent(
                    title: "Approaching exposure limit",
                    message: plan.safetyAlertMessage(for: .medWarning, elapsedSeconds: elapsedSeconds),
                    actions: [.default("OK", systemImage: "checkmark")]
                )
            case .overLimit(let percent):
                if percent == SunSessionSafetyThresholds.fullMEDPercent {
                    BigDoseAlertContent(
                        title: overLimitAlertTitle(for: percent),
                        message: plan.safetyAlertMessage(for: .overLimit(percent: percent), elapsedSeconds: elapsedSeconds),
                        actions: [
                            .destructive("Stop Session", systemImage: "stop.fill") { complete() },
                            .default("I'm Still Out Here", systemImage: "play.fill")
                        ]
                    )
                } else {
                    BigDoseAlertContent(
                        title: overLimitAlertTitle(for: percent),
                        message: plan.safetyAlertMessage(for: .overLimit(percent: percent), elapsedSeconds: elapsedSeconds),
                        actions: [.default("I'm Still Out Here", systemImage: "play.fill")]
                    )
                }
            case .goalReached:
                BigDoseAlertContent(
                    title: "Goal reached",
                    message: plan.safetyAlertMessage(for: .goalReached, elapsedSeconds: elapsedSeconds),
                    actions: [.default("Got it", systemImage: "checkmark")]
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
        .sheet(item: $presentedSheet) { sheet in
            switch sheet {
            case .firstSessionGuide:
                FirstSunSessionGuideView {
                    hasSeenFirstSunSessionGuide = true
                    presentedSheet = nil
                    evaluateSessionAlerts()
                }
                .interactiveDismissDisabled()
            case .skinCoverage:
                SkinExposurePickerView(exposedBodySurfaceArea: $plan.exposedBodySurfaceArea)
                    .presentationDetents([.medium, .large])
            case .goalPicker:
                SessionGoalPickerView(
                    targetIU: $plan.targetIU,
                    plan: plan,
                    elapsedSeconds: elapsedSeconds
                )
                .presentationDetents([.medium, .large])
            }
        }
        .confirmationDialog("Clouds", isPresented: $isShowingCloudCover, titleVisibility: .visible) {
            ForEach(CloudCoverPreset.allCases) { preset in
                Button(preset.title) {
                    plan.cloudCover = preset
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .bigDoseAlert(
            "Cancel sun session?",
            isPresented: $isShowingCancelConfirmation,
            message: "Are you certain? This won't record this sun session if you cancel.",
            actions: [
                .destructive("Cancel Session", systemImage: "xmark") { cancel() },
                .cancel("Keep Going", systemImage: "play.fill")
            ],
            isOpaque: true
        )
        .bigDoseAlert(
            "Stop sun session?",
            isPresented: $isShowingStopConfirmation,
            message: "Save session with \(Int(estimatedIU.rounded()).formatted()) IU estimated so far?",
            actions: [
                .destructive("Stop & Save", systemImage: "stop.fill") { complete() },
                .cancel("Keep Going", systemImage: "play.fill")
            ],
            isOpaque: true
        )
        .bigDoseAlert(
            "Still tracking sun",
            isPresented: $isShowingStaleSessionAlert,
            message: ActiveSessionReminderService.staleSessionMessage(for: plan, elapsedSeconds: elapsedSeconds),
            actions: [
                .destructive("Stop & Save", systemImage: "stop.fill") { complete() },
                .default("Keep Going", systemImage: "play.fill")
            ],
            isOpaque: true
        )
        .bigDoseAlert(
            "Resume sun session?",
            isPresented: $isShowingInactivityRecoveryAlert,
            message: inactivityRecoveryMessage,
            actions: [
                .default("Still Outside", systemImage: "sun.max.fill") { resumeAfterInactivityRecovery() },
                .destructive("Stop & Save", systemImage: "stop.fill") { complete() },
                .cancel("Cancel Session", systemImage: "xmark") { cancel() }
            ],
            isOpaque: true
        )
    }

    private var inactivityRecoveryMessage: String {
        guard let record = ActiveSunSessionStore.load() else {
            return "BigDose lost contact with this session. Away time was not added. Still outside, or stop and save?"
        }

        return ActiveSessionRecoveryService.recoveryMessage(for: record, plan: plan)
    }

    private var activePrimaryText: Color {
        colorScheme == .dark
            ? .white
            : Color(red: 0.22, green: 0.13, blue: 0.07)
    }

    private var appAppearance: AppAppearancePreference {
        AppAppearancePreference(rawValue: appAppearanceRawValue) ?? .system
    }

    private var activeAccent: Color {
        colorScheme == .dark ? .solarGoldBright : .solarOrange
    }

    private var activeSurface: Color {
        colorScheme == .dark
            ? .black.opacity(0.28)
            : .white.opacity(0.52)
    }

    private var outsideWindowBanner: some View {
        Label {
            Text(plan.isTraceVitaminDConditions ? "Outside D window — trace vitamin D only" : "Outside D window")
                .font(.subheadline)
                .bold()
                .foregroundStyle(activePrimaryText)
        } icon: {
            Image(systemName: "moon.stars.fill")
                .font(.headline)
                .foregroundStyle(activeAccent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(activeSurface, in: .rect(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(activeAccent.opacity(0.3), lineWidth: 1)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(plan.locationName.uppercased())
                    .font(.bigDoseHeader(.title2))
                    .tracking(1.4)
                    .foregroundStyle(activePrimaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Spacer(minLength: 12)

                HStack(spacing: 8) {
                    AppAppearanceToggleButton()
                        .font(.headline)
                        .foregroundStyle(activePrimaryText)
                        .frame(width: 44, height: 44)
                        .background(activeSurface, in: .circle)
                        .overlay {
                            Circle()
                                .stroke(activePrimaryText.opacity(0.2), lineWidth: 1)
                        }

                    Button("Cancel", systemImage: "xmark", action: requestCancel)
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(activePrimaryText)
                        .frame(minHeight: 44)
                        .padding(.horizontal, 12)
                        .background(activeSurface, in: .capsule)
                        .overlay {
                            Capsule()
                                .stroke(activePrimaryText.opacity(0.2), lineWidth: 1)
                        }
                        .buttonStyle(.plain)
                }
            }

            HStack(spacing: 10) {
                Image(systemName: "sun.max.fill")
                    .font(.title3)
                    .foregroundStyle(activeAccent)

                weatherChip("\(Int(plan.currentTemperatureFahrenheit.rounded()))°")

                Spacer(minLength: 4)
                weatherDivider
                Spacer(minLength: 4)

                weatherChip("UV \(plan.uvIndex.formatted(.number.precision(.fractionLength(1))))")

                Spacer(minLength: 4)
                weatherDivider
                Spacer(minLength: 4)

                weatherChip(plan.cloudCover.title)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            BigDoseWeatherAttributionView(
                attribution: weatherAttribution,
                foregroundColor: activePrimaryText
            )
        }
    }

    private func weatherChip(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .bold()
            .foregroundStyle(activePrimaryText.opacity(0.78))
            .lineLimit(1)
            .minimumScaleFactor(0.78)
    }

    private var weatherDivider: some View {
        Rectangle()
            .fill(activePrimaryText.opacity(0.16))
            .frame(width: 1, height: 18)
    }

    private func requestCancel() {
        isShowingCancelConfirmation = true
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
            activePrimaryText.opacity(0.72)
        }
    }

    private var sessionControls: some View {
        HStack(spacing: 12) {
            SessionControlButton(
                style: .pause(isPaused: isPaused),
                action: togglePause
            )

            SessionControlButton(
                style: .stop,
                action: requestStop
            )
        }
        .padding(12)
        .background(controlDockSurface, in: .rect(cornerRadius: 32))
        .overlay {
            RoundedRectangle(cornerRadius: 32)
                .stroke(activePrimaryText.opacity(0.14), lineWidth: 1)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(controlBarBackground)
    }

    private var controlDockSurface: Color {
        colorScheme == .dark
            ? .white.opacity(0.08)
            : .white.opacity(0.72)
    }

    private var controlBarBackground: Color {
        colorScheme == .dark
            ? .deepSpace.opacity(0.94)
            : Color(red: 0.98, green: 0.95, blue: 0.87).opacity(0.94)
    }

    private func presentGoalPicker() {
        clampTargetIUForGoalPicker()
        presentedSheet = .goalPicker
    }

    private func clampTargetIUForGoalPicker() {
        let minimum = SunSessionPlan.sessionGoalMinimumIU
        let maximum = max(
            plan.sessionGoalPickerMaximumIU,
            ceil(plan.targetIU / SunSessionPlan.sessionGoalSliderStep) * SunSessionPlan.sessionGoalSliderStep
        )
        plan.targetIU = min(max(plan.targetIU, minimum), maximum)
    }

    private func togglePause() {
        isPaused.toggle()
    }

    private func requestStop() {
        isShowingStopConfirmation = true
    }

    private var modifiersCard: some View {
        HStack(spacing: 0) {
            Button {
                presentedSheet = .skinCoverage
            } label: {
                sessionModifierTile(
                    title: "Skin",
                    value: SkinExposurePreset.coverageLabel(for: plan.exposedBodySurfaceArea),
                    icon: "person.fill"
                )
            }
            .buttonStyle(.borderless)
            .frame(maxWidth: .infinity)

            modifierDivider

            Button {
                isShowingCloudCover = true
            } label: {
                sessionModifierTile(
                    title: "Clouds",
                    value: plan.cloudCover.title,
                    icon: "cloud.sun.fill"
                )
            }
            .buttonStyle(.borderless)
            .frame(maxWidth: .infinity)

            modifierDivider

            Button {
                presentGoalPicker()
            } label: {
                sessionModifierTile(
                    title: "Goal",
                    value: "\(Int(plan.targetIU.rounded())) IU",
                    icon: "target"
                )
            }
            .buttonStyle(.borderless)
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(activeSurface, in: .rect(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(activePrimaryText.opacity(0.1), lineWidth: 1)
        }
    }

    private var modifierDivider: some View {
        Rectangle()
            .fill(activePrimaryText.opacity(0.1))
            .frame(width: 1, height: 48)
    }

    private func sessionModifierTile(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 5) {
            Label(title.uppercased(), systemImage: icon)
                .font(.caption)
                .bold()
                .tracking(0.8)
                .foregroundStyle(activeAccent)

            Text(value)
                .font(.subheadline)
                .bold()
                .foregroundStyle(activePrimaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .frame(maxWidth: .infinity, minHeight: 48)
        .padding(.horizontal, 5)
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

    private func reconcileElapsedFromPersistedState() {
        guard !sessionEnded, !isShowingInactivityRecoveryAlert else { return }
        guard let record = ActiveSunSessionStore.load(),
              record.sessionID == plan.liveActivitySessionID else {
            return
        }

        if ActiveSessionRecoveryService.needsRecovery(for: record) {
            evaluateStaleSessionAlert()
            return
        }

        let persistedElapsed = record.currentElapsed()
        guard persistedElapsed > elapsedSeconds else { return }

        elapsedSeconds = persistedElapsed
        isPaused = record.isPaused
        syncHistoricalSafetyAcknowledgements()
        persistSessionState()
        Task { await refreshSessionSafetyNotifications() }
        evaluateSessionAlerts()
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

    /// Crash-recovery write only. Does not wake WidgetKit.
    private func checkpointSessionState() {
        ActiveSunSessionPersistence.persist(
            plan: plan,
            elapsedSeconds: elapsedSeconds,
            isPaused: isPaused,
            acknowledgedSafetyAlertIDs: currentAcknowledgedSafetyAlertIDs()
        )
    }

    /// Full persist for meaningful session changes — App Group + home widget + reminder.
    private func persistSessionState() {
        checkpointSessionState()
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

    private func clearGoalReachedAlertIfNeeded() {
        guard didShowGoalReachedAlert else { return }
        guard !plan.hasReachedGoal(at: elapsedSeconds) else { return }

        var ids = Set(currentAcknowledgedSafetyAlertIDs())
        ids.remove(ActiveSunSessionSafetyAlertID.goalReached)
        applyAcknowledgedSafetyAlertIDs(ids)
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
            applyPersistedElapsedIfAvailable()
            if !isPaused {
                isPaused = true
                persistSessionState()
                syncLiveActivity()
            }
        case .resume:
            applyPersistedElapsedIfAvailable()
            if isPaused {
                isPaused = false
                persistSessionState()
                syncLiveActivity()
            }
        case .end:
            applyPersistedElapsedIfAvailable()
            complete()
        }
    }

    private func applyPersistedElapsedIfAvailable() {
        guard let record = ActiveSunSessionStore.load(),
              record.sessionID == plan.liveActivitySessionID else {
            return
        }
        // Prefer frozen store elapsed from LA controls; do not re-extrapolate.
        elapsedSeconds = record.isPaused ? record.elapsedSeconds : record.currentElapsed()
        isPaused = record.isPaused
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

        // Persist first via onComplete → save; cleanup only after SwiftData succeeds.
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
        guard !isPaused else {
            SessionSafetyNotificationService.cancelSessionNotifications()
            return
        }

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
        guard !sessionEnded, presentedSheet != .firstSessionGuide, !isShowingInactivityRecoveryAlert else { return }
        guard activeAlert == nil, !isShowingStopConfirmation else { return }
        guard ActiveSessionReminderService.isStale(
            for: plan,
            elapsedSeconds: elapsedSeconds,
            isPaused: isPaused
        ) else { return }

        isShowingStaleSessionAlert = true
    }

    private func evaluateSessionAlerts() {
        guard presentedSheet != .firstSessionGuide, !isShowingInactivityRecoveryAlert else { return }
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

private enum ActiveSunSessionSheet: String, Identifiable {
    case firstSessionGuide
    case skinCoverage
    case goalPicker

    var id: String { rawValue }
}

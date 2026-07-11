import SwiftUI

struct SunSessionPlannerView: View {
    var profile: UserProfile
    var weather: BigDoseWeatherSnapshot
    var latitude: Double
    var longitude: Double
    var todaySunIU: Double = 0
    var isFirstLiveSunSession: Bool = false
    var onCancel: () -> Void
    var onStart: (SunSessionPlan) -> Void

    @State private var exposedBodySurfaceArea: Double
    @State private var cloudCover: CloudCoverPreset = .clear
    @State private var durationSeconds: TimeInterval
    @State private var isShowingSkinExposure = false
    @State private var pendingOutsideWindowStart = false

    private var sessionTargetIU: Double {
        max(Double(profile.preferredDailyIU) - todaySunIU, 100)
    }

    init(
        profile: UserProfile,
        weather: BigDoseWeatherSnapshot,
        latitude: Double,
        longitude: Double,
        todaySunIU: Double = 0,
        isFirstLiveSunSession: Bool = false,
        onCancel: @escaping () -> Void,
        onStart: @escaping (SunSessionPlan) -> Void
    ) {
        self.profile = profile
        self.weather = weather
        self.latitude = latitude
        self.longitude = longitude
        self.todaySunIU = todaySunIU
        self.isFirstLiveSunSession = isFirstLiveSunSession
        self.onCancel = onCancel
        self.onStart = onStart
        _exposedBodySurfaceArea = State(initialValue: profile.typicalExposedBodySurfaceArea)

        let remainingTarget = max(Double(profile.preferredDailyIU) - todaySunIU, 100)
        let bootstrapPlan = SunSessionPlan(
            startedAt: .now,
            durationSeconds: 15 * 60,
            exposedBodySurfaceArea: profile.typicalExposedBodySurfaceArea,
            cloudCover: .clear,
            sunscreenTransmission: profile.usuallyUsesSunscreen ? 0.35 : 1,
            uvIndex: weather.uvIndex,
            currentTemperatureFahrenheit: weather.temperatureFahrenheit,
            skinType: profile.skinType,
            locationName: weather.locationName,
            targetIU: remainingTarget,
            exitLeadFraction: profile.prepareExitLeadFraction,
            latitude: latitude,
            longitude: longitude
        )
        _durationSeconds = State(initialValue: bootstrapPlan.recommendedDurationSeconds)
    }

    private var plan: SunSessionPlan {
        SunSessionPlan(
            startedAt: .now,
            durationSeconds: durationSeconds,
            exposedBodySurfaceArea: exposedBodySurfaceArea,
            cloudCover: cloudCover,
            sunscreenTransmission: profile.usuallyUsesSunscreen ? 0.35 : 1,
            uvIndex: weather.uvIndex,
            currentTemperatureFahrenheit: weather.temperatureFahrenheit,
            skinType: profile.skinType,
            locationName: weather.locationName,
            targetIU: sessionTargetIU,
            exitLeadFraction: profile.prepareExitLeadFraction,
            latitude: latitude,
            longitude: longitude
        )
    }

    private var estimate: VitaminDExposureEstimate {
        plan.estimate
    }

    private var startGate: SunSessionStartGate {
        SunSessionEligibilityService.startGate(
            latitude: latitude,
            longitude: longitude,
            uvIndex: weather.uvIndex
        )
    }

    private var goalMinutes: Int {
        Int((plan.goalDurationSeconds / 60).rounded())
    }

    private var safeExitMinutes: Int {
        Int((plan.safeMaxDurationSeconds / 60).rounded())
    }

    var body: some View {
        ZStack {
            BigDoseGradientBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    header
                    windowStatusCard
                    controls
                    sessionSummaryCard
                    BigDoseWeatherAttributionView(weather: weather)
                        .padding(.top, 2)
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 12)
            }
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                startButton
                    .padding(.horizontal, 18)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
                    .background {
                        LinearGradient(
                            colors: [.clear, Color.black.opacity(0.55)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    }
            }
        }
        .onChange(of: exposedBodySurfaceArea) { _, _ in
            durationSeconds = plan.clampedPlannedDuration(durationSeconds)
        }
        .onChange(of: cloudCover) { _, _ in
            durationSeconds = plan.clampedPlannedDuration(durationSeconds)
        }
        .sheet(isPresented: $isShowingSkinExposure) {
            SkinExposurePickerView(exposedBodySurfaceArea: $exposedBodySurfaceArea)
                .presentationDetents([.medium, .large])
        }
        .bigDoseAlert(
            "Outside D window",
            isPresented: $pendingOutsideWindowStart,
            message: outsideWindowConfirmMessage,
            actions: [
                .default("Start Anyway") { onStart(plan) },
                .cancel("Not Now")
            ]
        )
    }

    private var outsideWindowConfirmMessage: String {
        if case .warn(_, let detail) = startGate {
            return detail
        }
        return "The sun is not high enough for efficient vitamin D. BigDose will scale IU estimates down."
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: onCancel) {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(.white.opacity(0.10), in: .circle)
            }

            Text("Plan Your Session")
                .font(.bigDoseHeader(.headline).weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)

            Color.clear.frame(width: 38, height: 38)
        }
    }

    @ViewBuilder
    private var windowStatusCard: some View {
        switch startGate {
        case .allowed:
            EmptyView()
        case .warn(let title, let detail):
            statusCard(title: title, detail: detail, tint: .solarGold, icon: "exclamationmark.triangle.fill")
        case .blocked(let title, let detail):
            statusCard(title: title, detail: detail, tint: .red, icon: "moon.stars.fill")
        }
    }

    private func statusCard(title: String, detail: String, tint: Color, icon: String) -> some View {
        GlassCard(cornerRadius: 20) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(tint)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.bigDoseHeader(.headline).weight(.semibold))
                        .foregroundStyle(.white)
                    Text(detail)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.68))
                }
            }
        }
    }

    private var controls: some View {
        GlassCard(cornerRadius: 20) {
            VStack(spacing: 0) {
                Button {
                    isShowingSkinExposure = true
                } label: {
                    compactPlannerRow(
                        icon: "person.fill",
                        title: "Exposed Skin",
                        value: "\(Int(exposedBodySurfaceArea * 100))%"
                    )
                }
                .buttonStyle(.plain)

                rowDivider

                Menu {
                    ForEach(CloudCoverPreset.allCases) { preset in
                        Button(preset.title) {
                            cloudCover = preset
                        }
                    }
                } label: {
                    compactPlannerRow(
                        icon: "cloud.sun.fill",
                        title: "Clouds / Shade",
                        value: cloudCover.title
                    )
                }

                rowDivider

                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        HStack(spacing: 4) {
                            Text("Planned Time")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            InfoCircleButton(topic: .plannedTime, iconSize: 11, compact: true)
                        }

                        Spacer(minLength: 8)

                        Text("\(Int(durationSeconds / 60)) min")
                            .font(.bigDoseHeader(.headline).weight(.black))
                            .foregroundStyle(.solarGold)
                    }

                    Slider(
                        value: $durationSeconds,
                        in: 60...plan.safeMaxDurationSeconds,
                        step: 60
                    )
                    .tint(.solarGold)

                    HStack(spacing: 8) {
                        ForEach(SunSessionDurationPreset.allCases, id: \.self) { preset in
                            let presetSeconds = preset.durationSeconds(for: plan)
                            Button(preset.title(for: plan)) {
                                withAnimation(.smooth) {
                                    durationSeconds = presetSeconds
                                }
                            }
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(durationSeconds == presetSeconds ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                durationSeconds == presetSeconds ? Color.solarGold : .white.opacity(0.08),
                                in: .rect(cornerRadius: 10)
                            )
                        }
                    }
                }
                .padding(.top, 12)
            }
        }
    }

    private var rowDivider: some View {
        Divider()
            .overlay(.white.opacity(0.10))
            .padding(.vertical, 10)
    }

    private var sessionSummaryCard: some View {
        GlassCard(cornerRadius: 20) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 4) {
                    Text("Your Limits Today")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    InfoCircleButton(topic: .minToMED, iconSize: 11, compact: true)
                    Spacer(minLength: 0)
                }

                Text("\(profile.skinType.title) skin · UV \(weather.uvIndex.formatted(.number.precision(.fractionLength(1)))) · \(Int(exposedBodySurfaceArea * 100))% exposed")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.52))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                if let timeline = plan.safetyTimelineMinutes {
                    HStack(spacing: 8) {
                        limitMetric(
                            icon: "arrow.triangle.2.circlepath",
                            label: "Turn",
                            value: "~\(timeline.turnOver)m"
                        )
                        limitMetric(
                            icon: "figure.walk",
                            label: "Head in",
                            value: "~\(timeline.wrapUp)m"
                        )
                        limitMetric(
                            icon: "hand.raised.fill",
                            label: "Exit",
                            value: "~\(timeline.safeExit)m",
                            tint: .solarOrange
                        )
                    }
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.solarOrange)
                        Text("No meaningful UV estimate right now.")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.solarOrange)
                    }
                }

                Divider().overlay(.white.opacity(0.10))

                HStack(alignment: .firstTextBaseline) {
                    HStack(spacing: 4) {
                        Text("Goal ~\(goalMinutes)m")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.solarGold)
                        InfoCircleButton(topic: .toReachGoal, iconSize: 10, compact: true)
                    }

                    Text("·")
                        .foregroundStyle(.white.opacity(0.28))

                    HStack(spacing: 4) {
                        Text("Safe max ~\(safeExitMinutes)m")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.solarOrange)
                        InfoCircleButton(topic: .safeMax, iconSize: 10, compact: true)
                    }

                    Spacer(minLength: 0)

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(Int(estimate.estimatedIU.rounded()))")
                            .font(.bigDoseHeader(.headline).weight(.black))
                            .foregroundStyle(plan.isTraceVitaminDConditions ? .white.opacity(0.55) : .white)
                        Text(plan.isTraceVitaminDConditions ? "IU trace" : "IU")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                        if plan.isTraceVitaminDConditions {
                            InfoCircleButton(topic: .estimatedIU, iconSize: 10, compact: true)
                        }
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                }
            }
        }
    }

    private func limitMetric(icon: String, label: String, value: String, tint: Color = .white) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.solarGold)

            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.52))
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text(value)
                .font(.subheadline.weight(.black))
                .foregroundStyle(tint == .white ? .white : tint)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.white.opacity(0.06), in: .rect(cornerRadius: 12))
    }

    private var startButton: some View {
        BigDosePrimaryButton(
            title: startButtonTitle,
            systemImage: isStartBlocked ? nil : "play.fill",
            style: startButtonStyle,
            isEnabled: !isStartBlocked,
            action: attemptStart
        )
    }

    private var startButtonStyle: BigDosePrimaryButton.Style {
        if case .warn = startGate { return .prominent }
        if case .blocked = startGate { return .prominent }
        return .success
    }

    private var isStartBlocked: Bool {
        if case .blocked = startGate { return true }
        return false
    }

    private var startButtonTitle: String {
        if case .blocked = startGate { return "Session Unavailable" }
        if case .warn = startGate { return "Start Anyway" }
        return "Start Session"
    }

    private func attemptStart() {
        switch startGate {
        case .allowed:
            onStart(plan)
        case .warn:
            pendingOutsideWindowStart = true
        case .blocked:
            break
        }
    }

    private func compactPlannerRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.solarGold)
                .frame(width: 20)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            Spacer(minLength: 8)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))

            Image(systemName: "chevron.down")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.32))
        }
        .contentShape(.rect)
    }
}

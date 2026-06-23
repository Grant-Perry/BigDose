import SwiftUI

struct SunSessionPlannerView: View {
    var profile: UserProfile
    var weather: BigDoseWeatherSnapshot
    var latitude: Double
    var longitude: Double
    var isFirstLiveSunSession: Bool = false
    var onCancel: () -> Void
    var onStart: (SunSessionPlan) -> Void

    @State private var exposedBodySurfaceArea: Double
    @State private var cloudCover: CloudCoverPreset = .clear
    @State private var durationSeconds: TimeInterval
    @State private var isShowingSkinExposure = false
    @State private var pendingOutsideWindowStart = false

    init(
        profile: UserProfile,
        weather: BigDoseWeatherSnapshot,
        latitude: Double,
        longitude: Double,
        isFirstLiveSunSession: Bool = false,
        onCancel: @escaping () -> Void,
        onStart: @escaping (SunSessionPlan) -> Void
    ) {
        self.profile = profile
        self.weather = weather
        self.latitude = latitude
        self.longitude = longitude
        self.isFirstLiveSunSession = isFirstLiveSunSession
        self.onCancel = onCancel
        self.onStart = onStart
        _exposedBodySurfaceArea = State(initialValue: profile.typicalExposedBodySurfaceArea)

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
            targetIU: Double(profile.preferredDailyIU),
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
            targetIU: Double(profile.preferredDailyIU),
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
                VStack(alignment: .leading, spacing: 14) {
                    header
                    windowStatusCard
                    if isFirstLiveSunSession {
                        SunSafetyIntroBanner(
                            goalMinutes: goalMinutes,
                            safeMaxMinutes: safeExitMinutes
                        )
                    }
                    controls
                    safetyTimelineCard
                    estimateCard
                    startButton
                }
                .padding(18)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
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
        HStack {
            Button(action: onCancel) {
                Image(systemName: "chevron.left")
                    .font(.bigDoseHeader(.title2).weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(.white.opacity(0.10), in: .circle)
            }

            Spacer()

            Text("Plan Your Session")
                .font(.bigDoseHeader(.title2).weight(.semibold))
                .foregroundStyle(.white)

            Spacer()

            Color.clear.frame(width: 46, height: 46)
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
        VStack(spacing: 10) {
            Button {
                isShowingSkinExposure = true
            } label: {
                plannerRow(
                    icon: "person.fill",
                    title: "Exposed Skin",
                    value: "\(Int(exposedBodySurfaceArea * 100))%"
                )
            }
            .buttonStyle(.plain)

            Menu {
                ForEach(CloudCoverPreset.allCases) { preset in
                    Button(preset.title) {
                        cloudCover = preset
                    }
                }
            } label: {
                plannerRow(icon: "cloud.sun.fill", title: "Clouds / Shade", value: cloudCover.title)
            }

            GlassCard(cornerRadius: 24) {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text("Planned Time")
                                .font(.bigDoseHeader(.headline).weight(.semibold))
                                .foregroundStyle(.white)
                            InfoCircleButton(topic: .plannedTime, compact: true)
                        }

                        Text("Recommended ~\(Int((plan.recommendedDurationSeconds / 60).rounded())) min · capped at safe max")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.55))
                    }

                    HStack {
                        Spacer()
                        Text("\(Int(durationSeconds / 60)) min")
                            .font(.bigDoseHeader(.headline).weight(.semibold))
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
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(durationSeconds == presetSeconds ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                durationSeconds == presetSeconds ? Color.solarGold : .white.opacity(0.08),
                                in: .rect(cornerRadius: 12)
                            )
                        }
                    }
                }
            }
        }
    }

    private var safetyTimelineCard: some View {
        GlassCard(cornerRadius: 20) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Your Limits Today")
                        .font(.bigDoseHeader(.headline).weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    InfoCircleButton(topic: .minToMED, compact: true)
                }

                if isFirstLiveSunSession {
                    Text("BigDose alerts you at each milestone during your session.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.55))
                }

                if let timeline = plan.safetyTimelineMinutes {
                    Text("\(profile.skinType.title) skin · UV \(weather.uvIndex.formatted(.number.precision(.fractionLength(1)))) · \(Int(exposedBodySurfaceArea * 100))% exposed")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.55))

                    safetyTimelineRow(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Turn over by",
                        detail: "~\(timeline.turnOver) min"
                    )
                    safetyTimelineRow(
                        icon: "figure.walk",
                        title: "Start heading in by",
                        detail: "~\(timeline.wrapUp) min"
                    )
                    safetyTimelineRow(
                        icon: "hand.raised.fill",
                        title: "Safe exit by",
                        detail: "~\(timeline.safeExit) min",
                        tint: .solarOrange
                    )
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.solarOrange)
                        Text("No meaningful UV estimate right now.")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.solarOrange)
                    }
                }
            }
        }
    }

    private func safetyTimelineRow(icon: String, title: String, detail: String, tint: Color = .white) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.solarGold)
                .frame(width: 22)

            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(tint.opacity(0.78))

            Spacer()

            Text(detail)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
        }
    }

    private var estimateCard: some View {
        GlassCard {
            VStack(spacing: 16) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("~\(goalMinutes) min")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(.solarGold)
                        HStack(spacing: 4) {
                            Text("to reach goal")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.6))
                            InfoCircleButton(topic: .toReachGoal, compact: true)
                        }
                    }

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.35))

                    Spacer()

                    VStack(alignment: .trailing, spacing: 6) {
                        Text("~\(safeExitMinutes) min")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(.solarOrange)
                        HStack(spacing: 4) {
                            Text("safe max")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.6))
                            InfoCircleButton(topic: .safeMax, compact: true)
                        }
                    }
                }

                Divider().overlay(.white.opacity(0.12))

                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(Int(durationSeconds / 60)) min")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("planned time")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 6) {
                        Text("\(Int(estimate.estimatedIU.rounded()))")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(plan.isTraceVitaminDConditions ? .white.opacity(0.55) : .white)
                        HStack(spacing: 4) {
                            Text(plan.isTraceVitaminDConditions ? "IU trace est." : "IU estimated")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.6))
                            if plan.isTraceVitaminDConditions {
                                InfoCircleButton(topic: .estimatedIU, compact: true)
                            }
                        }
                    }
                }
            }
        }
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

    private func plannerRow(icon: String, title: String, value: String) -> some View {
        GlassCard(cornerRadius: 22) {
            HStack {
                Image(systemName: icon)
                    .font(.bigDoseHeader(.title3).weight(.semibold))
                    .foregroundStyle(.solarGold)

                Text(title)
                    .font(.bigDoseHeader(.headline).weight(.semibold))
                    .foregroundStyle(.white)

                Spacer()

                Text(value)
                    .font(.bigDoseHeader(.headline).weight(.semibold))
                    .foregroundStyle(.white.opacity(0.68))

                Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.42))
            }
        }
    }
}

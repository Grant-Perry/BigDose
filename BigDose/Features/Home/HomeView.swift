import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailySunPlan.generatedAt, order: .reverse) private var dailyPlans: [DailySunPlan]
    @Query(sort: \ExposureSession.startedAt, order: .reverse) private var sessions: [ExposureSession]
    @Query(sort: \SupplementDose.takenAt, order: .reverse) private var supplements: [SupplementDose]
    @Query(sort: \FoodVitaminDEntry.loggedAt, order: .reverse) private var foods: [FoodVitaminDEntry]
    var profile: UserProfile?
    @State private var homeViewModel = HomeViewModel()
    @State private var isShowingMoreWeather = false
    @State private var sessionRoute: SessionRoute?
    @State private var undoSupplementDose: SupplementDose?
    @State private var healthKitImportService = HealthKitImportService()

    private var activeProfile: UserProfile {
        profile ?? UserProfile.preview
    }

    private var estimate: VitaminDExposureEstimate {
        let plan = currentPlan
        return homeViewModel.estimate(
            for: activeProfile,
            latitude: plan?.latitude ?? 0,
            longitude: plan?.longitude ?? 0
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BigDoseGradientBackground()

                TimelineView(.periodic(from: .now, by: 60)) { timeline in
                    dashboardScrollContent(now: timeline.date)
                }
            }
            .navigationTitle("BigDose")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    BigDoseNavigationWordmark()
                }
            }
            .task {
                await refreshHome()
                restoreActiveSessionIfNeeded()
            }
            .refreshable {
                await refreshHome()
            }
            .onReceive(NotificationCenter.default.publisher(for: .bigDoseOpenSessionFromLiveActivity)) { notification in
                restoreActiveSessionIfNeeded(expectedSessionID: notification.object as? String)
            }
            .fullScreenCover(item: $sessionRoute) { route in
                sessionView(for: route)
            }
        }
    }

    @ViewBuilder
    private func dashboardScrollContent(now: Date) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dashboard")
                        .font(.bigDoseHeader(.title2).weight(.black))
                        .foregroundStyle(.white)
                        .accessibilityAddTraits(.isHeader)

                    header(now: now)
                }

                weatherCard
                solarGuidanceCard(now: now)
                goalCard(now: now)
                sunRiskCard
                recommendationCard(now: now)
                metricGrid
                scienceNudge
                legalFooter
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 110)
        }
        .scrollIndicators(.hidden)
    }

    private func header(now: Date) -> some View {
        HomeHeroHeader(
            profile: profile ?? activeProfile,
            todayGoalProgress: todaySunGoalProgress,
            todaySunIU: todayIUIntake.sunIU,
            targetIU: activeProfile.preferredDailyIU,
            vitaminDWindowDisplay: currentPlan.flatMap { vitaminDWindowDisplay(for: $0, now: now) },
            now: now,
            isSunSessionStartEnabled: homeViewModel.weather != nil,
            showsNoUsefulUV: showsNoUsefulUV(now: now),
            onStartSunSession: { sessionRoute = .typePicker }
        )
    }

    private func showsNoUsefulUV(now: Date) -> Bool {
        guard let plan = currentPlan,
              plan.latitude != 0 || plan.longitude != 0,
              Calendar.current.isDateInToday(now) else {
            return false
        }

        let todaySnapshot = SolarGeometryService.vitaminDWindow(
            latitude: plan.latitude,
            longitude: plan.longitude,
            date: Calendar.current.startOfDay(for: now)
        )

        guard let windowEnd = todaySnapshot.windowEnd else {
            return !todaySnapshot.hasWindow
        }

        return now > windowEnd
    }

    @ViewBuilder
    private var weatherCard: some View {
        if let weather = homeViewModel.weather {
            GlassCard {
                VStack(alignment: .leading, spacing: 16) {
                    weatherSummaryHeader(weather)

                    LazyVGrid(columns: weatherColumns, spacing: 9) {
                        WeatherTemperatureCard(
                            current: weather.temperatureFahrenheit,
                            feelsLike: weather.feelsLikeFahrenheit,
                            low: weather.lowTemperatureFahrenheit,
                            high: weather.highTemperatureFahrenheit
                        )

                        WeatherRingMetricCard(
                            icon: "humidity.fill",
                            title: "Humidity",
                            value: "\(Int(weather.humidityPercent.rounded()))%",
                            subtitle: "moisture",
                            progress: weather.humidityPercent / 100,
                            accent: .gpHiLtBlue
                        )

                        WeatherRingMetricCard(
                            icon: "sun.max.fill",
                            title: "UV Index",
                            value: weather.uvIndex.formatted(.number.precision(.fractionLength(1))),
                            subtitle: "right now",
                            progress: min(max(weather.uvIndex / 11, 0), 1),
                            accent: .gpGatePill
                        )
                    }

                    Button {
                        isShowingMoreWeather.toggle()
                    } label: {
                        HStack {
                            Text(isShowingMoreWeather ? "Hide Weather Details" : "More Weather")
                                .font(.caption.weight(.semibold))
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.caption.weight(.bold))
                                .rotationEffect(.degrees(isShowingMoreWeather ? 180 : 0))
                        }
                        .foregroundStyle(.white.opacity(0.72))
                        .padding(.horizontal, 4)
                    }
                    .buttonStyle(.plain)

                    if isShowingMoreWeather {
                        weatherExpandedDetails(weather)
                    }

                    BigDoseWeatherAttributionView(
                        weather: weather,
                        statusMessage: homeViewModel.statusMessage
                    )
                }
                .animation(.smooth(duration: 0.32), value: isShowingMoreWeather)
                .clipped()
            }
        } else if homeViewModel.isLoading {
            weatherLoadingCard
        } else {
            unavailableCard(
                title: "Weather unavailable",
                detail: homeViewModel.statusMessage,
                systemImage: "cloud",
                showsUnavailableSlash: true
            )
            .task {
                if homeViewModel.weather == nil && !homeViewModel.isLoading {
                    await refreshHome()
                }
            }
        }
    }

    private var weatherLoadingCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center) {
                    Text("Weather")
                        .font(.bigDoseHeader(.title2).weight(.semibold))
                        .foregroundStyle(.white.opacity(0.72))

                    Spacer()

                    ProgressView()
                        .controlSize(.regular)
                        .tint(.solarGold)
                }

                LazyVGrid(columns: weatherColumns, spacing: 9) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.white.opacity(0.06))
                            .frame(height: 118)
                            .overlay {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(.solarGold.opacity(0.72))
                            }
                    }
                }

                Text(homeViewModel.statusMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.52))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading weather")
        .accessibilityValue(homeViewModel.statusMessage)
    }

    private var weatherColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 9), count: 3)
    }

    private var weatherTwoColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 9), count: 2)
    }

    private func weatherSummaryHeader(_ weather: BigDoseWeatherSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center) {
                Text(weather.locationName)
                    .font(.bigDoseHeader(.title2).weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                WeatherUVIBadge(uvIndex: weather.uvIndex)

                Image(systemName: weather.symbolName)
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(.solarGold)
                    .symbolEffect(.pulse, options: .repeating, value: homeViewModel.isLoading)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            Text(weather.displayConditionSummary)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.62))
        }
    }

    @ViewBuilder
    private func weatherExpandedDetails(_ weather: BigDoseWeatherSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: weatherTwoColumns, spacing: 9) {
                WeatherRingMetricCard(
                    icon: "barometer",
                    title: "Pressure",
                    value: weather.pressureInchesMercury.formatted(.number.precision(.fractionLength(2))),
                    subtitle: "inHg",
                    progress: min(max((weather.pressureInchesMercury - 28.5) / 2.5, 0), 1),
                    accent: .gpSpineLavender
                )

                WeatherWindCard(speed: weather.windMilesPerHour)
            }

            if !weather.nextSixHourlyForecast.isEmpty {
                WeatherNextSixHoursPrecipPanel(
                    hourlyForecast: weather.nextSixHourlyForecast,
                    totalRainInches: weather.totalRainNextSixHoursInches
                )
            }

            if !weather.hourlyForecast.isEmpty {
                BigDoseHourlyForecastStrip(forecast: weather.hourlyForecast)
            }

            if !weather.dailyForecast.isEmpty {
                BigDoseThreeDayForecastRow(
                    forecast: weather.dailyForecast,
                    hourlyForecast: weather.hourlyForecast,
                    hourlyUV: weather.hourlyUV,
                    latitude: currentPlan?.latitude ?? 0,
                    longitude: currentPlan?.longitude ?? 0,
                    profile: activeProfile
                )
            }
        }
        .transition(.opacity)
    }

    @ViewBuilder
    private func solarGuidanceCard(now: Date) -> some View {
        if let plan = currentPlan, let display = vitaminDWindowDisplay(for: plan, now: now) {
            GlassCard {
                VStack(alignment: .leading, spacing: 18) {
                    solarGuidanceHeader(plan: plan, display: display, now: now)

                    VitaminDSunPathDiagram(
                        display: display,
                        now: now,
                        currentSunAltitude: currentSunAltitude(for: plan, at: now)
                    )

                    HStack(spacing: 12) {
                        solarPeakChip(plan: plan)
                        solarStatusChip(plan: plan)
                    }

                    StartSunSessionActionButton(
                        isEnabled: homeViewModel.weather != nil,
                        showsNoUsefulUV: showsNoUsefulUV(now: now),
                        size: .compact
                    ) {
                        sessionRoute = .typePicker
                    }

                    if let weather = homeViewModel.weather {
                        BigDoseWeatherAttributionView(weather: weather)
                    }
                }
            }
        } else {
            unavailableCard(
                title: "Solar guidance unavailable",
                detail: "BigDose has not calculated today’s sunlight window yet. Pull to refresh after location and WeatherKit are available.",
                systemImage: "sun.max.trianglebadge.exclamationmark.fill"
            )
        }
    }

    private func solarGuidanceHeader(plan: DailySunPlan, display: VitaminDWindowDisplay, now: Date) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(display.cardTitle)
                        .font(.bigDoseHeader(.title3).weight(.black))
                        .foregroundStyle(.white)

                    InfoCircleButton(topic: .vitaminDWindowToday, iconSize: 16)
                }

                Text(plan.locationLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(currentSunAltitude(for: plan, at: now).rounded()))°")
                    .font(.system(size: 34, weight: .black))
                    .foregroundStyle(.solarGold)
                    .contentTransition(.numericText())

                Text("sun now")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white.opacity(0.62))
            }
        }
    }

    private func currentSunAltitude(for plan: DailySunPlan, at now: Date) -> Double {
        SolarGeometryService.solarPosition(
            latitude: plan.latitude,
            longitude: plan.longitude,
            date: now
        ).altitudeDegrees
    }

    private func solarPeakChip(plan: DailySunPlan) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 2) {
                Text("Peak UV")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.white.opacity(0.58))
                    .textCase(.uppercase)

                InfoCircleButton(topic: .peakUV, iconSize: 11, compact: true)
            }

            Text(plan.peakUVIndex.formatted(.number.precision(.fractionLength(1))))
                .font(.bigDoseHeader(.title2).weight(.black))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.white.opacity(0.06), in: .rect(cornerRadius: 18, style: .continuous))
    }

    private func solarStatusChip(plan: DailySunPlan) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 2) {
                Text("Window")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.white.opacity(0.58))
                    .textCase(.uppercase)

                InfoCircleButton(topic: .window, iconSize: 11, compact: true)
            }

            Text(formattedRange(start: plan.vitaminDWindowStart, end: plan.vitaminDWindowEnd))
                .font(.subheadline.weight(.black))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.white.opacity(0.06), in: .rect(cornerRadius: 18, style: .continuous))
    }

    private func goalCard(now: Date) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "target")
                        .font(.bigDoseHeader(.title3).weight(.black))
                        .foregroundStyle(.solarGold)

                    Text("Goal")
                        .font(.bigDoseHeader(.title3).weight(.black))
                        .foregroundStyle(.white)

                    InfoCircleButton(topic: .goal, iconSize: 16)
                }

                SunArcMeter(
                    progress: todaySunGoalProgress,
                    quality: todaySunGoalProgress >= 1 ? .prime : estimate.quality,
                    title: goalMeterTitle,
                    durationTitle: goalMeterDurationTitle,
                    subtitle: goalMeterSubtitle,
                    showsQualityBadge: false
                )

                StartSunSessionActionButton(
                    isEnabled: homeViewModel.weather != nil,
                    showsNoUsefulUV: showsNoUsefulUV(now: now),
                    size: .compact
                ) {
                    sessionRoute = .typePicker
                }
            }
        }
    }

    private func recommendationCard(now: Date) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                estimatedIUHeader

                Text(recommendationSummary)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))

                VStack(spacing: 12) {
                    StartSunSessionActionButton(
                        isEnabled: homeViewModel.weather != nil,
                        showsNoUsefulUV: showsNoUsefulUV(now: now),
                        size: .regular
                    ) {
                        sessionRoute = .typePicker
                    }

                    SupplementLogActionButton(iu: activeProfile.defaultSupplementIU) {
                        logDefaultSupplement()
                    }

                    if let undoSupplementDose {
                        undoSupplementRow(undoSupplementDose)
                    }
                }

                HStack(spacing: 2) {
                    Text("*")
                        .foregroundStyle(.solarGold)
                    Text(" Estimated")
                        .foregroundStyle(.white.opacity(0.48))

                    InfoCircleButton(topic: .estimatedIU, iconSize: 11, compact: true)
                }
                .font(.caption2.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private var estimatedIUHeader: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            estimatedIUHeaderLabel
                .lineLimit(2)
                .minimumScaleFactor(0.78)
                .contentTransition(.numericText())
            InfoCircleButton(topic: .estimatedIU, iconSize: 14, compact: true)
            Spacer(minLength: 0)
        }
    }

    private var estimatedIUHeaderLabel: Text {
        Text("\(Int(estimate.estimatedIU.rounded()).formatted())")
            .font(.system(size: 46, weight: .black))
            .foregroundStyle(.solarGold)
        + Text(" IU")
            .font(.bigDoseHeader(.headline).weight(.black))
            .foregroundStyle(.white.opacity(0.72))
        + Text(" is what you'll get")
            .font(.bigDoseHeader(.headline).weight(.bold))
            .foregroundStyle(.white.opacity(0.72))
        + Text("*")
            .font(.caption.weight(.black))
            .baselineOffset(9)
            .foregroundStyle(.solarGold)
    }

    private var todaySunRiskSummary: TodaySunRiskSummary {
        SunExposureAggregation.todayLiveSessionRisk(from: sessions)
    }

    @ViewBuilder
    private var sunRiskCard: some View {
        let summary = todaySunRiskSummary
        if summary.liveSessionCount > 0 {
            GlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "shield.lefthalf.filled")
                            .foregroundStyle(summary.hasOverLimitExposure ? .red : .solarGold)

                        Text("Sun risk today")
                            .font(.bigDoseHeader(.headline).weight(.semibold))
                            .foregroundStyle(.white)

                        Spacer(minLength: 0)

                        InfoCircleButton(topic: .medUsed, compact: true)
                    }

                    Text(sunRiskSummaryText(summary))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func sunRiskSummaryText(_ summary: TodaySunRiskSummary) -> String {
        let sessionLabel = summary.liveSessionCount == 1 ? "1 session" : "\(summary.liveSessionCount) sessions"

        if summary.hasOverLimitExposure {
            return "MED exposure across \(sessionLabel) totals \(summary.totalMedUsedPercent)% today, including \(summary.totalMedOverLimitPercent)% past BigDose's 90% guidance limit."
        }

        return "MED exposure across \(sessionLabel) totals \(summary.totalMedUsedPercent)% of BigDose's guidance budget today."
    }

    private var metricGrid: some View {
        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
            MetricPill(title: "UV Index", value: homeViewModel.weather?.uvIndex.formatted(.number.precision(.fractionLength(1))) ?? "Unavailable", systemImage: "sun.max.fill", infoTopic: .uvIndex)
            MetricPill(title: "Risk Used", value: "\(estimate.riskPercent)%", systemImage: "shield.lefthalf.filled", infoTopic: .med)
            MetricPill(title: "Skin Type", value: activeProfile.skinType.title, systemImage: "person.crop.square", infoTopic: .skinType)
            MetricPill(title: "Goal", value: "\(Int(activeProfile.goalNanogramsPerMilliliter)) ng/mL", systemImage: "target", infoTopic: .goal)
        }
    }

    private var recommendationSummary: String {
        guard let weather = homeViewModel.weather else {
            return "BigDose needs current WeatherKit UV data before estimating today’s sunlight dose."
        }

        return "Based on your \(activeProfile.skinType.title) skin, about \(Int(activeProfile.typicalExposedBodySurfaceArea * 100))% skin exposed and a UV index of \(weather.uvIndex.formatted(.number.precision(.fractionLength(1))))."
    }

    private var todayIUIntake: DailyIUIntakeSummary {
        DailyIUIntakeAggregation.today(
            sessions: sessions,
            supplements: supplements,
            foods: foods
        )
    }

    private var todaySunGoalProgress: Double {
        todayIUIntake.sunGoalProgress(
            dailyTargetIU: Double(max(activeProfile.preferredDailyIU, 1))
        )
    }

    private var remainingSunIUForToday: Double {
        todayIUIntake.remainingSunIUForGoal(
            dailyTargetIU: Double(activeProfile.preferredDailyIU)
        )
    }

    private var remainingSunMinutesForToday: Int {
        guard remainingSunIUForToday > 0 else { return 0 }

        return Int(ceil(VitaminDCalculator.targetDurationSeconds(
            targetIU: remainingSunIUForToday,
            uvIndex: homeViewModel.weather?.uvIndex ?? 0,
            exposedBodySurfaceArea: activeProfile.typicalExposedBodySurfaceArea,
            skinType: activeProfile.skinType
        ) / 60))
    }

    private var goalMeterDurationTitle: BigDoseDurationComponents? {
        guard todaySunGoalProgress < 1, remainingSunMinutesForToday > 0 else { return nil }
        return BigDoseDurationComponents(minutes: remainingSunMinutesForToday)
    }

    private var goalMeterTitle: String {
        if todaySunGoalProgress >= 1 {
            return "Done"
        }

        if remainingSunMinutesForToday > 0 {
            return ""
        }

        return "\(Int(todayIUIntake.sunIU.rounded()))"
    }

    private var goalMeterSubtitle: String {
        if todaySunGoalProgress >= 1 {
            return "sun goal reached"
        }

        if remainingSunMinutesForToday > 0 {
            return "sun goal remaining"
        }

        return "IU from sun today"
    }

    private var legalFooter: some View {
        Text(AppConstants.legalFooter)
		  .font(.system(size: 10))
            .foregroundStyle(.white.opacity(0.45))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
    }

    private var scienceNudge: some View {
        NavigationLink {
            EducationView()
        } label: {
            GlassCard(cornerRadius: 24) {
                HStack(spacing: 14) {
                    Image(systemName: "sparkles")
                        .font(.bigDoseHeader(.title2).weight(.bold))
                        .foregroundStyle(.solarGold)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("How BigDose Works")
                            .font(.bigDoseHeader(.headline).weight(.black))
                            .foregroundStyle(.white)

                        Text("Freshman-level science. No medical cosplay.")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.62))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.bigDoseHeader(.headline).weight(.bold))
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func sessionView(for route: SessionRoute) -> some View {
        switch route {
        case .typePicker:
            SessionTypePickerView { type in
                switch type {
                case .sun:
                    sessionRoute = .sunPlanner
                case .supplement:
                    sessionRoute = .supplementDose
                case .lamp, .scheduled:
                    sessionRoute = .sunPlanner
                }
            } onCancel: {
                sessionRoute = nil
            }

        case .sunPlanner:
            if let weather = homeViewModel.weather, let plan = currentPlan {
                SunSessionPlannerView(
                    profile: activeProfile,
                    weather: weather,
                    latitude: plan.latitude,
                    longitude: plan.longitude,
                    isFirstLiveSunSession: isFirstLiveSunSession,
                    onCancel: { sessionRoute = .typePicker },
                    onStart: { plan in sessionRoute = .activeSunSession(plan) }
                )
            } else if homeViewModel.weather != nil {
                HomeUnavailableSheet(
                    title: "Solar Guidance Required",
                    message: "BigDose needs today's solar plan before starting a sun session. Pull to refresh on Home.",
                    onClose: { sessionRoute = nil }
                )
            } else {
                HomeUnavailableSheet(
                    title: "Weather Required",
                    message: "BigDose needs current Apple Weather UV data before starting a sun session.",
                    onClose: { sessionRoute = nil }
                )
            }

        case .supplementDose:
            AddSupplementDoseView(
                defaultIU: activeProfile.defaultSupplementIU,
                profile: profile
            )

        case .activeSunSession(let plan):
            ActiveSunSessionView(
                plan: plan,
                wantsSessionSafetyAlerts: activeProfile.wantsRiskAlerts,
                wantsNannyMode: activeProfile.wantsNannyMode,
                onCancel: { sessionRoute = nil },
                onComplete: { result in sessionRoute = .completion(result) }
            )

        case .completion(let result):
            SunSessionCompleteView(result: result) {
                save(result)
                sessionRoute = nil
                Task { await refreshHome() }
            }
        }
    }

    private func save(_ result: SunSessionResult) {
        let session = ExposureSession(
            startedAt: result.plan.startedAt,
            endedAt: result.endedAt,
            durationSeconds: result.elapsedSeconds,
            averageUVIndex: result.plan.input.effectiveUVIndex,
            maxUVIndex: result.plan.uvIndex,
            estimatedIU: result.estimatedIU,
            peakMedUsedPercent: result.medUsedPercent,
            medOverLimitPercent: result.medOverLimitPercent,
            exposedBodySurfaceArea: result.plan.exposedBodySurfaceArea,
            sunscreenFactor: result.plan.sunscreenTransmission,
            source: .liveTracked,
            quality: result.plan.estimate.quality,
            locationLabel: result.plan.locationName
        )
        modelContext.insert(session)
        try? modelContext.save()
        SunSessionSessionCleanup.finishSession(clearPendingCommandFor: result.plan.liveActivitySessionID)
    }

    private var isFirstLiveSunSession: Bool {
        !sessions.contains { $0.source == .liveTracked }
    }

    private var currentPlan: DailySunPlan? {
        homeViewModel.dailyPlan ?? dailyPlans.first { Calendar.current.isDateInToday($0.date) }
    }

    private func refreshHome() async {
        DailySupplementAutoApplyService.applyIfNeeded(
            profile: activeProfile,
            supplements: supplements,
            modelContext: modelContext
        )
        await homeViewModel.refresh(profile: activeProfile)
        persistDailyPlanIfNeeded()
        publishWidgetSnapshot()
        await BigDoseNotificationCoordinator.refreshManagedAlerts(
            profile: activeProfile,
            modelContext: modelContext
        )
    }

    private func publishWidgetSnapshot() {
        BigDoseWidgetPublisher.publishFromStores(
            profile: activeProfile,
            plan: currentPlan,
            weather: homeViewModel.weather,
            todaySunIU: todayIUIntake.sunIU
        )
    }

    private func restoreActiveSessionIfNeeded(expectedSessionID: String? = nil) {
        guard sessionRoute == nil else { return }
        guard let record = ActiveSunSessionStore.load() else { return }
        if let expectedSessionID, record.sessionID != expectedSessionID { return }
        guard let plan = ActiveSunSessionPersistence.plan(from: record) else { return }

        if SunSessionLiveActivityCommandStore.hasPendingEnd(for: record.sessionID) {
            _ = SunSessionLiveActivityCommandStore.consume(for: record.sessionID)
            let elapsed = record.currentElapsed()
            let result = SunSessionResult(
                plan: plan,
                endedAt: .now,
                elapsedSeconds: max(elapsed, 1),
                estimatedIU: plan.estimatedIU(at: elapsed)
            )
            SunSessionSessionCleanup.finishSession(clearPendingCommandFor: record.sessionID)
            sessionRoute = .completion(result)
            return
        }

        sessionRoute = .activeSunSession(plan)
    }

    private func persistDailyPlanIfNeeded() {
        guard let plan = homeViewModel.dailyPlan else { return }

        if let existing = dailyPlans.first(where: { Calendar.current.isDate($0.date, inSameDayAs: plan.date) }) {
            existing.generatedAt = plan.generatedAt
            existing.latitude = plan.latitude
            existing.longitude = plan.longitude
            existing.locationLabel = plan.locationLabel
            existing.sunrise = plan.sunrise
            existing.solarNoon = plan.solarNoon
            existing.sunset = plan.sunset
            existing.bestWindowStart = plan.bestWindowStart
            existing.bestWindowEnd = plan.bestWindowEnd
            existing.vitaminDWindowStart = plan.vitaminDWindowStart
            existing.vitaminDWindowEnd = plan.vitaminDWindowEnd
            existing.vitaminDWindowReferenceDay = plan.vitaminDWindowReferenceDay
            existing.solarNoonAltitudeDegrees = plan.solarNoonAltitudeDegrees
            existing.vitaminDThresholdDegrees = plan.vitaminDThresholdDegrees
            existing.nextUsefulStart = plan.nextUsefulStart
            existing.nextUsefulEnd = plan.nextUsefulEnd
            existing.targetIU = plan.targetIU
            existing.estimatedIU = plan.estimatedIU
            existing.peakUVIndex = plan.peakUVIndex
            existing.currentAltitudeDegrees = plan.currentAltitudeDegrees
            existing.quality = plan.quality
            existing.weatherAttribution = plan.weatherAttribution
        } else {
            modelContext.insert(plan)
        }

        try? modelContext.save()
    }

    private func formattedTime(_ date: Date?) -> String {
        date?.formatted(date: .omitted, time: .shortened) ?? "Unavailable"
    }

    private func formattedRange(start: Date?, end: Date?) -> String {
        guard let start, let end else { return "Unavailable" }
        return "\(formattedTime(start)) - \(formattedTime(end))"
    }

    private func vitaminDWindowDisplay(for plan: DailySunPlan, now: Date) -> VitaminDWindowDisplay? {
        guard plan.latitude != 0 || plan.longitude != 0 else { return nil }
        return DailySunPlanService.vitaminDWindowDisplay(for: plan, now: now)
    }

    private func logDefaultSupplement() {
        let dose = SupplementDose(
            takenAt: .now,
            internationalUnits: activeProfile.defaultSupplementIU,
            note: "Quick logged from Dashboard"
        )
        modelContext.insert(dose)
        undoSupplementDose = dose
        try? modelContext.save()
        publishWidgetSnapshot()

        if let profile {
            Task {
                await healthKitImportService.syncSupplementDoseToHealth(dose, profile: profile)
                try? modelContext.save()
            }
        }
    }

    private func undoSupplementLog(_ dose: SupplementDose) {
        Task {
            await healthKitImportService.removeSupplementDoseFromHealth(dose)
            modelContext.delete(dose)
            undoSupplementDose = nil
            try? modelContext.save()
            publishWidgetSnapshot()
        }
    }

    private func undoSupplementRow(_ dose: SupplementDose) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption.weight(.black))
                .foregroundStyle(Color.gpHiGreen)

            Text("Logged \(dose.internationalUnits) IU")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))

            Spacer()

            Button("Undo") {
                undoSupplementLog(dose)
            }
            .font(.caption.weight(.black))
            .foregroundStyle(.solarGold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.white.opacity(0.06), in: .rect(cornerRadius: 16))
    }

    private func unavailableCard(
        title: String,
        detail: String,
        systemImage: String,
        showsUnavailableSlash: Bool = false
    ) -> some View {
        GlassCard {
            HStack(alignment: .top, spacing: 14) {
                unavailableSymbol(systemImage, showsUnavailableSlash: showsUnavailableSlash)
                    .font(.bigDoseHeader(.title2).weight(.bold))
                    .foregroundStyle(.solarGold)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.bigDoseHeader(.headline).weight(.black))
                        .foregroundStyle(.white)

                    Text(detail)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.68))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func unavailableSymbol(_ systemImage: String, showsUnavailableSlash: Bool) -> some View {
        if showsUnavailableSlash {
            Image(systemName: systemImage)
                .symbolVariant(.slash)
        } else {
            Image(systemName: systemImage)
        }
    }
}

private struct HomeUnavailableSheet: View {
    var title: String
    var message: String
    var onClose: () -> Void

    var body: some View {
        ZStack {
            BigDoseGradientBackground()

            VStack(spacing: 18) {
                Image(systemName: "cloud")
                    .symbolVariant(.slash)
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundStyle(.solarGold)

                Text(title)
                    .font(.system(.largeTitle, weight: .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.bigDoseHeader(.headline).weight(.semibold))
                    .foregroundStyle(.white.opacity(0.68))
                    .multilineTextAlignment(.center)

                BigDosePrimaryButton(title: "Close", action: onClose)
                    .padding(.top, 8)
            }
            .padding(24)
        }
    }
}

private struct SupplementLogActionButton: View {
    var iu: Int
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "pills.fill")
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(.white.opacity(0.68))
                    .frame(width: 30, height: 30)
                    .background(.white.opacity(0.08), in: .circle)

                Text("Log \(iu) IU supplement")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.white.opacity(0.06), in: .rect(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Log \(iu) IU supplement")
    }
}

private struct BigDoseWeatherAttributionView: View {
    @Environment(\.colorScheme) private var colorScheme
    var weather: BigDoseWeatherSnapshot
    var statusMessage: String?

    private var markURL: URL? {
        colorScheme == .dark ? weather.combinedMarkDarkURL : weather.combinedMarkLightURL
    }

    var body: some View {
        HStack(spacing: 8) {
            if let statusMessage {
                Text(statusMessage)
                    .font(.caption2.weight(.semibold))
            }

            if let markURL {
                AsyncImage(url: markURL) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(height: 14)
                } placeholder: {
                    Text("Weather")
                        .font(.caption2.weight(.bold))
                }
            } else {
                Text("Weather")
                    .font(.caption2.weight(.bold))
            }

            if let url = weather.attributionURL {
                Link("Data Sources", destination: url)
                    .font(.caption2.weight(.semibold))
            }

            Spacer(minLength: 0)
        }
        .foregroundStyle(.white.opacity(0.58))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
    }

    private var accessibilityLabelText: String {
        if let statusMessage {
            "\(statusMessage). Weather data attribution and legal data sources."
        } else {
            "Weather data attribution and legal data sources"
        }
    }
}


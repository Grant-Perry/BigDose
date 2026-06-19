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
        homeViewModel.estimate(for: activeProfile)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BigDoseGradientBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        weatherCard
                        solarGuidanceCard
                        goalCard
                        recommendationCard
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
            .navigationTitle("BigDose")
            .toolbarTitleDisplayMode(.inline)
            .task {
                await refreshHome()
            }
            .refreshable {
                await refreshHome()
            }
            .fullScreenCover(item: $sessionRoute) { route in
                sessionView(for: route)
            }
        }
    }

    private var header: some View {
        HomeHeroHeader(
            profile: profile ?? activeProfile,
            vitaminDWindowDisplay: currentPlan.flatMap { vitaminDWindowDisplay(for: $0) },
            detail: headerDetail
        )
        .padding(.top, 4)
    }

    private var headerDetail: String {
        guard let display = currentPlan.flatMap({ vitaminDWindowDisplay(for: $0) }) else {
            return "BigDose needs your location and Apple Weather to calculate your vitamin D window."
        }

        if display.nextOpportunityStart == nil, display.isToday {
            return "The sun is above \(Int(display.snapshot.thresholdDegrees.rounded()))° right now. Short, clean exposure beats chasing a burn."
        }

        if let duration = display.snapshot.durationLabel {
            return "You'll have about \(duration) of useful sunlight \(display.dayLabel.lowercased())."
        }

        return "Short, clean exposure beats chasing a burn."
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

                    Text(homeViewModel.statusMessage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.58))

                    BigDoseWeatherAttributionView(weather: weather)
                }
                .animation(.smooth(duration: 0.32), value: isShowingMoreWeather)
                .clipped()
            }
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

    private var weatherColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 9), count: 3)
    }

    private var weatherTwoColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 9), count: 2)
    }

    private func weatherSummaryHeader(_ weather: BigDoseWeatherSnapshot) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(weather.locationName)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)

                Text(weather.displayConditionSummary)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
            }

            Spacer()

            Image(systemName: weather.symbolName)
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(.solarGold)
                .symbolEffect(.pulse, options: .repeating, value: homeViewModel.isLoading)
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
                    hourlyForecast: weather.hourlyForecast
                )
            }
        }
        .transition(.opacity)
    }

    @ViewBuilder
    private var solarGuidanceCard: some View {
        if let plan = currentPlan, let display = vitaminDWindowDisplay(for: plan) {
            GlassCard {
                VStack(alignment: .leading, spacing: 18) {
                    solarGuidanceHeader(plan: plan, display: display)

                    VitaminDSunPathDiagram(display: display)

                    HStack(spacing: 12) {
                        solarPeakChip(plan: plan)
                        solarStatusChip(plan: plan)
                    }

                    StartSunSessionActionButton(isEnabled: homeViewModel.weather != nil, size: .compact) {
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

    private func solarGuidanceHeader(plan: DailySunPlan, display: VitaminDWindowDisplay) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(display.cardTitle)
                    .font(.title3.weight(.black))
                    .foregroundStyle(.white)

                Text(plan.locationLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(plan.currentAltitudeDegrees.rounded()))°")
                    .font(.system(size: 34, weight: .black))
                    .foregroundStyle(.solarGold)

                Text("sun now")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white.opacity(0.62))
            }
        }
    }

    private func solarPeakChip(plan: DailySunPlan) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Peak UV")
                .font(.caption2.weight(.black))
                .foregroundStyle(.white.opacity(0.58))
                .textCase(.uppercase)

            Text(plan.peakUVIndex.formatted(.number.precision(.fractionLength(1))))
                .font(.title2.weight(.black))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.white.opacity(0.06), in: .rect(cornerRadius: 18, style: .continuous))
    }

    private func solarStatusChip(plan: DailySunPlan) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Window")
                .font(.caption2.weight(.black))
                .foregroundStyle(.white.opacity(0.58))
                .textCase(.uppercase)

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

    private var goalCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Label("Goal", systemImage: "target")
                    .font(.title3.weight(.black))
                    .foregroundStyle(.white)

                SunArcMeter(
                    progress: todayGoalProgress,
                    quality: todayGoalProgress >= 1 ? .prime : estimate.quality,
                    title: goalMeterTitle,
                    subtitle: goalMeterSubtitle,
                    showsQualityBadge: false
                )

                StartSunSessionActionButton(isEnabled: homeViewModel.weather != nil, size: .compact) {
                    sessionRoute = .typePicker
                }
            }
        }
    }

    private var recommendationCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                estimatedIUHeader

                Text(recommendationSummary)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))

                VStack(spacing: 12) {
                    StartSunSessionActionButton(isEnabled: homeViewModel.weather != nil, size: .regular) {
                        sessionRoute = .typePicker
                    }

                    SupplementLogActionButton(iu: activeProfile.defaultSupplementIU) {
                        logDefaultSupplement()
                    }

                    if let undoSupplementDose {
                        undoSupplementRow(undoSupplementDose)
                    }
                }

                HStack(spacing: 0) {
                    Text("*")
                        .foregroundStyle(.solarGold)
                    Text(" Estimated")
                        .foregroundStyle(.white.opacity(0.48))
                }
                .font(.caption2.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private var estimatedIUHeader: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("\(Int(estimate.estimatedIU.rounded()).formatted())")
                .font(.system(size: 46, weight: .black))
                .foregroundStyle(.solarGold)
                .contentTransition(.numericText())

            Text("IU")
                .font(.headline.weight(.black))
                .foregroundStyle(.white.opacity(0.72))

            Text("is what you'll get")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white.opacity(0.72))

            Text("*")
                .font(.caption.weight(.black))
                .baselineOffset(9)
                .foregroundStyle(.solarGold)

            Spacer(minLength: 0)
        }
        .lineLimit(2)
        .minimumScaleFactor(0.78)
    }

    private var metricGrid: some View {
        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
            MetricPill(title: "UV Index", value: homeViewModel.weather?.uvIndex.formatted(.number.precision(.fractionLength(1))) ?? "Unavailable", systemImage: "sun.max.fill")
            MetricPill(title: "Risk Used", value: "\(estimate.riskPercent)%", systemImage: "shield.lefthalf.filled")
            MetricPill(title: "Skin Type", value: activeProfile.skinType.title, systemImage: "person.crop.square")
            MetricPill(title: "Goal", value: "\(Int(activeProfile.goalNanogramsPerMilliliter)) ng/mL", systemImage: "target")
        }
    }

    private var recommendationSummary: String {
        guard let weather = homeViewModel.weather else {
            return "BigDose needs current WeatherKit UV data before estimating today’s sunlight dose."
        }

        return "Based on your \(activeProfile.skinType.title), about \(Int(activeProfile.typicalExposedBodySurfaceArea * 100))% skin exposed, and a UV index of \(weather.uvIndex.formatted(.number.precision(.fractionLength(1))))."
    }

    private var todayCollectedIU: Double {
        let calendar = Calendar.current
        let sunIU = sessions
            .filter { calendar.isDateInToday($0.startedAt) }
            .reduce(0) { $0 + $1.estimatedIU }
        let supplementIU = supplements
            .filter { calendar.isDateInToday($0.takenAt) }
            .reduce(0) { $0 + Double($1.internationalUnits) }
        let foodIU = foods
            .filter { calendar.isDateInToday($0.loggedAt) }
            .reduce(0) { $0 + Double($1.estimatedIU) }

        return sunIU + supplementIU + foodIU
    }

    private var todayGoalProgress: Double {
        let target = Double(max(activeProfile.preferredDailyIU, 1))
        return min(max(todayCollectedIU / target, 0), 1)
    }

    private var remainingIUForToday: Double {
        max(Double(activeProfile.preferredDailyIU) - todayCollectedIU, 0)
    }

    private var remainingSunMinutesForToday: Int {
        guard remainingIUForToday > 0 else { return 0 }

        return Int(ceil(VitaminDCalculator.targetDurationSeconds(
            targetIU: remainingIUForToday,
            uvIndex: homeViewModel.weather?.uvIndex ?? 0,
            exposedBodySurfaceArea: activeProfile.typicalExposedBodySurfaceArea,
            skinType: activeProfile.skinType
        ) / 60))
    }

    private var goalMeterTitle: String {
        if todayGoalProgress >= 1 {
            return "Done"
        }

        if remainingSunMinutesForToday > 0 {
            return "\(remainingSunMinutesForToday)m"
        }

        return "\(Int(todayCollectedIU.rounded()))"
    }

    private var goalMeterSubtitle: String {
        if todayGoalProgress >= 1 {
            return "goal reached"
        }

        if remainingSunMinutesForToday > 0 {
            return "sun time remaining"
        }

        return "IU collected today"
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
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.solarGold)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("How BigDose Works")
                            .font(.headline.weight(.black))
                            .foregroundStyle(.white)

                        Text("Freshman-level science. No medical cosplay.")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.62))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.headline.weight(.bold))
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
            if let weather = homeViewModel.weather {
                SunSessionPlannerView(
                    profile: activeProfile,
                    weather: weather,
                    onCancel: { sessionRoute = .typePicker },
                    onStart: { plan in sessionRoute = .activeSunSession(plan) }
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
                onCancel: { sessionRoute = .sunPlanner },
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
            exposedBodySurfaceArea: result.plan.exposedBodySurfaceArea,
            sunscreenFactor: result.plan.sunscreenTransmission,
            source: .liveTracked,
            quality: result.plan.estimate.quality,
            locationLabel: result.plan.locationName
        )
        modelContext.insert(session)
        try? modelContext.save()
    }

    private var currentPlan: DailySunPlan? {
        homeViewModel.dailyPlan ?? dailyPlans.first { Calendar.current.isDateInToday($0.date) }
    }

    private func refreshHome() async {
        await homeViewModel.refresh(profile: activeProfile)
        persistDailyPlanIfNeeded()
        await BigDoseNotificationCoordinator.refreshManagedAlerts(
            profile: activeProfile,
            modelContext: modelContext
        )
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

    private func vitaminDWindowDisplay(for plan: DailySunPlan) -> VitaminDWindowDisplay? {
        guard plan.latitude != 0 || plan.longitude != 0 else { return nil }
        return DailySunPlanService.vitaminDWindowDisplay(for: plan)
    }

    private func logDefaultSupplement() {
        let dose = SupplementDose(
            takenAt: .now,
            internationalUnits: activeProfile.defaultSupplementIU,
            note: "Quick logged from Home"
        )
        modelContext.insert(dose)
        undoSupplementDose = dose
        try? modelContext.save()

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
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.solarGold)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline.weight(.black))
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
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.68))
                    .multilineTextAlignment(.center)

                Button("Close", action: onClose)
                    .font(.headline.weight(.semibold))
                    .buttonStyle(.borderedProminent)
                    .tint(.solarOrange)
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

    private var markURL: URL? {
        colorScheme == .dark ? weather.combinedMarkDarkURL : weather.combinedMarkLightURL
    }

    var body: some View {
        HStack(spacing: 8) {
            if let markURL {
                AsyncImage(url: markURL) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(height: 14)
                } placeholder: {
                    Text("Weather")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.58))
                }
            } else {
                Text("Weather")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.58))
            }

            if let url = weather.attributionURL {
                Link("Data Sources", destination: url)
                    .font(.caption2.weight(.semibold))
            }
        }
        .foregroundStyle(.white.opacity(0.58))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Weather data attribution and legal data sources")
    }
}


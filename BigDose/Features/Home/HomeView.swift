import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    var profile: UserProfile?
    @State private var homeViewModel = HomeViewModel()
    @State private var isShowingMoreWeather = false
    @State private var sessionRoute: SessionRoute?

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

                        GlassCard {
                            SunArcMeter(
                                progress: min(estimate.estimatedIU / Double(activeProfile.preferredDailyIU), 1),
                                quality: estimate.quality,
                                title: "\(estimate.targetDurationMinutes)m",
                                subtitle: "to hit today"
                            )
                        }

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
                await homeViewModel.refresh()
            }
            .refreshable {
                await homeViewModel.refresh()
            }
            .fullScreenCover(item: $sessionRoute) { route in
                sessionView(for: route)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Prime D Window")
                .font(.system(.largeTitle, weight: .semibold))
                .foregroundStyle(.white)

            Text("Today looks strongest around solar noon. Short, clean exposure beats chasing a burn.")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
    }

    private var weatherCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(homeViewModel.weather.locationName)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white)

                        Text(homeViewModel.weather.conditionText)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.62))
                    }

                    Spacer()

                    Image(systemName: homeViewModel.weather.symbolName)
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundStyle(.solarGold)
                        .symbolEffect(.pulse, options: .repeating, value: homeViewModel.isLoading)
                }

                LazyVGrid(columns: weatherColumns, spacing: 9) {
                    WeatherTemperatureCard(
                        current: homeViewModel.weather.temperatureFahrenheit,
                        feelsLike: homeViewModel.weather.feelsLikeFahrenheit,
                        low: homeViewModel.weather.lowTemperatureFahrenheit,
                        high: homeViewModel.weather.highTemperatureFahrenheit
                    )

                    WeatherRingMetricCard(
                        icon: "humidity.fill",
                        title: "Humidity",
                        value: "\(Int(homeViewModel.weather.humidityPercent.rounded()))%",
                        subtitle: "moisture",
                        progress: homeViewModel.weather.humidityPercent / 100,
                        accent: .gpHiLtBlue
                    )

                    WeatherRingMetricCard(
                        icon: "sun.max.fill",
                        title: "UV Index",
                        value: homeViewModel.weather.uvIndex.formatted(.number.precision(.fractionLength(1))),
                        subtitle: "right now",
                        progress: min(max(homeViewModel.weather.uvIndex / 11, 0), 1),
                        accent: .gpGatePill
                    )
                }

                Button {
                    withAnimation(.smooth) {
                        isShowingMoreWeather.toggle()
                    }
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
                    LazyVGrid(columns: weatherColumns, spacing: 9) {
                        WeatherRingMetricCard(
                            icon: "barometer",
                            title: "Pressure",
                            value: homeViewModel.weather.pressureInchesMercury.formatted(.number.precision(.fractionLength(2))),
                            subtitle: "inHg",
                            progress: min(max((homeViewModel.weather.pressureInchesMercury - 28.5) / 2.5, 0), 1),
                            accent: .gpSpineLavender
                        )

                        WeatherWindCard(speed: homeViewModel.weather.windMilesPerHour)

                        WeatherRingMetricCard(
                            icon: "drop.fill",
                            title: "Dew Point",
                            value: "\(Int(homeViewModel.weather.dewPointFahrenheit.rounded()))°",
                            subtitle: "air feel",
                            progress: min(max(homeViewModel.weather.dewPointFahrenheit / 80, 0), 1),
                            accent: .gpActivePlanGlow
                        )
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Text(homeViewModel.statusMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
            }
        }
    }

    private var weatherColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 9), count: 3)
    }

    private var recommendationCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(Int(estimate.estimatedIU.rounded()))")
                        .font(.system(size: 46, weight: .black))
                        .foregroundStyle(.solarGold)
                        .contentTransition(.numericText())

                    Text("IU estimated")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white.opacity(0.72))

                    Spacer()
                }

                Text("Based on your \(activeProfile.skinType.title), about \(Int(activeProfile.typicalExposedBodySurfaceArea * 100))% skin exposed, and a UV index of \(homeViewModel.weather.uvIndex.formatted(.number.precision(.fractionLength(1)))).")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))

                Button {
                    sessionRoute = .typePicker
                } label: {
                    Label("Start Sun Session", systemImage: "play.fill")
                        .font(.headline.weight(.black))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.solarOrange)
            }
        }
    }

    private var metricGrid: some View {
        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
            MetricPill(title: "UV Index", value: homeViewModel.weather.uvIndex.formatted(.number.precision(.fractionLength(1))), systemImage: "sun.max.fill")
            MetricPill(title: "Risk Used", value: "\(estimate.riskPercent)%", systemImage: "shield.lefthalf.filled")
            MetricPill(title: "Skin Type", value: activeProfile.skinType.title, systemImage: "person.crop.square")
            MetricPill(title: "Goal", value: "\(Int(activeProfile.goalNanogramsPerMilliliter)) ng/mL", systemImage: "target")
        }
    }

    private var legalFooter: some View {
        Text(AppConstants.legalFooter)
            .font(.caption2.weight(.medium))
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
                case .lamp, .supplement, .scheduled:
                    sessionRoute = .sunPlanner
                }
            } onCancel: {
                sessionRoute = nil
            }

        case .sunPlanner:
            SunSessionPlannerView(
                profile: activeProfile,
                weather: homeViewModel.weather,
                onCancel: { sessionRoute = .typePicker },
                onStart: { plan in sessionRoute = .activeSunSession(plan) }
            )

        case .activeSunSession(let plan):
            ActiveSunSessionView(
                plan: plan,
                onCancel: { sessionRoute = .sunPlanner },
                onComplete: { result in sessionRoute = .completion(result) }
            )

        case .completion(let result):
            SunSessionCompleteView(result: result) {
                save(result)
                sessionRoute = nil
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
}

#Preview {
    HomeView(profile: .preview)
        .modelContainer(BigDoseModelContainerFactory.preview)
}

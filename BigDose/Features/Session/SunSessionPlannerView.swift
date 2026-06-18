import SwiftUI

struct SunSessionPlannerView: View {
    var profile: UserProfile
    var weather: BigDoseWeatherSnapshot
    var onCancel: () -> Void
    var onStart: (SunSessionPlan) -> Void

    @State private var exposedBodySurfaceArea: Double
    @State private var cloudCover: CloudCoverPreset = .clear
    @State private var durationSeconds: TimeInterval = 15 * 60
    @State private var isShowingSkinExposure = false

    init(
        profile: UserProfile,
        weather: BigDoseWeatherSnapshot,
        onCancel: @escaping () -> Void,
        onStart: @escaping (SunSessionPlan) -> Void
    ) {
        self.profile = profile
        self.weather = weather
        self.onCancel = onCancel
        self.onStart = onStart
        _exposedBodySurfaceArea = State(initialValue: profile.typicalExposedBodySurfaceArea)
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
            exitLeadFraction: profile.prepareExitLeadFraction
        )
    }

    private var estimate: VitaminDExposureEstimate {
        plan.estimate
    }

    var body: some View {
        ZStack {
            BigDoseGradientBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    controls
                    estimateCard
                    medWarning
                    startButton
                }
                .padding(18)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
        }
        .sheet(isPresented: $isShowingSkinExposure) {
            SkinExposurePickerView(exposedBodySurfaceArea: $exposedBodySurfaceArea)
                .presentationDetents([.medium, .large])
        }
    }

    private var header: some View {
        HStack {
            Button(action: onCancel) {
                Image(systemName: "chevron.left")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(.white.opacity(0.10), in: .circle)
            }

            Spacer()

            Text("Plan Your Session")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)

            Spacer()

            Color.clear.frame(width: 46, height: 46)
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
                    HStack {
                        Text("Session Length")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                        Spacer()
                        Text("\(Int(durationSeconds / 60)) min")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.solarGold)
                    }

                    Slider(value: $durationSeconds, in: 60...90 * 60, step: 60)
                        .tint(.solarGold)

                    HStack(spacing: 8) {
                        ForEach([15, 30, 45, 60], id: \.self) { minutes in
                            Button("\(minutes) min") {
                                withAnimation(.smooth) {
                                    durationSeconds = TimeInterval(minutes * 60)
                                }
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(durationSeconds == TimeInterval(minutes * 60) ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(durationSeconds == TimeInterval(minutes * 60) ? Color.solarGold : .white.opacity(0.08), in: .rect(cornerRadius: 12))
                        }
                    }
                }
            }
        }
    }

    private var estimateCard: some View {
        GlassCard {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(Int(durationSeconds / 60)) min")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(.solarGold)
                    Text("planned time")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.title.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.35))

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Text("\(Int(estimate.estimatedIU.rounded()))")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("IU estimated")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
    }

    private var medWarning: some View {
        let minutes = Int((plan.medTimeSeconds / 60).rounded())
        return HStack(spacing: 8) {
            Image(systemName: "flame.fill")
            Text(minutes > 0 ? "Time to MED: \(minutes) min. Turn over before then." : "No meaningful UV estimate right now.")
        }
        .font(.headline.weight(.semibold))
        .foregroundStyle(.solarOrange)
        .padding(.horizontal, 4)
    }

    private var startButton: some View {
        Button {
            onStart(plan)
        } label: {
            Label("Start Session", systemImage: "play.fill")
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
    }

    private func plannerRow(icon: String, title: String, value: String) -> some View {
        GlassCard(cornerRadius: 22) {
            HStack {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.solarGold)

                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)

                Spacer()

                Text(value)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.68))

                Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.42))
            }
        }
    }
}


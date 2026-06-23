import SwiftData
import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LabResult.measuredAt, order: .reverse) private var labResults: [LabResult]
    @Query(sort: \SupplementDose.takenAt, order: .reverse) private var supplements: [SupplementDose]
    @FocusState private var focusedField: OnboardingField?
    var profile: UserProfile?
    var onFinished: (() -> Void)? = nil

    @State private var displayName = ""
    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -40, to: .now) ?? .now
    @State private var biologicalSex: BiologicalSex = .notSpecified
    @State private var heightFeetText = ""
    @State private var heightInchesText = ""
    @State private var weightPoundsText = ""
    @State private var levelKnowledge: VitaminDLevelKnowledge = .willAddLater
    @State private var baselineNanogramsText = ""
    @State private var baselineMeasuredAt = Date()
    @State private var goalNanogramsPerMilliliter = 50.0
    @State private var exposedBodySurfaceArea = 0.25
    @State private var incidentalSunMinutesPerWeek = 30.0
    @State private var usuallyUsesSunscreen = false
    @State private var defaultSupplementIUText = "1000"
    @State private var wantsDWindowOpeningAlerts = true
    @State private var wantsDWindowClosingAlerts = true
    @State private var wantsSolarNoonAlerts = true
    @State private var wantsSunriseSunsetAlerts = true
    @State private var wantsAMLightWindowAlerts = true
    @State private var wantsNextDOpportunityAlerts = true
    @State private var wantsRiskAlerts = true
    @State private var wantsSupplementReminders = false
    @State private var wantsLabReminders = true
    @State private var wantsWeeklyProgressAlerts = true
    @State private var wantsLevelTrendAlerts = true
    @State private var wantsMilestoneAlerts = true
    @State private var wantsWeatherBreakAlerts = false
    @State private var autoApplyDailySupplementIU = true
    @State private var selectedSkinType: FitzpatrickSkinType = .typeII
    @State private var wantsHealthKitSupplementExport = false
    @State private var didPrefillSupplementFromHealth = false
    @State private var page = 0
    @State private var isSyncingHealth = false
    @State private var healthAutofillMessage: String?
    @State private var healthAutofillTitle = "Apple Health Autofill"
    @State private var isShowingHealthAutofillResult = false
    @State private var pendingMetricUpdate: HealthProfileMetricUpdatePlan?
    @State private var isShowingMetricSyncConfirmation = false
    @State private var isFinishingOnboarding = false
    @State private var isCheckingMetricSync = false
    @State private var metricSyncNextAction: MetricSyncNextAction?
    @State private var healthKitImportService = HealthKitImportService()

    private let healthPage = 2
    private let bodyPageIndex = 4
    private let levelPageIndex = 5
    private let firstResultPageIndex = 11
    private let disclaimerPageIndex = 12
    private let onboardingPageCount = 13

    var body: some View {
        ZStack {
            BigDoseGradientBackground()

            VStack(spacing: 24) {
                TabView(selection: $page) {
                    OnboardingPageView(
                        symbolName: "sun.max.fill",
                        eyebrow: "BigDose",
                        title: "Find your best sunlight window.",
                        detail: "We look at your location, the sun angle, UV index and your profile to estimate useful vitamin D time."
                    )
                    .tag(0)

                    OnboardingPageView(
                        symbolName: "shield.lefthalf.filled",
                        eyebrow: "Not Medical Advice",
                        title: "Useful guidance...\nNot a diagnosis.",
                        detail: "BigDose is wellness information you can choose to use. Labs and clinicians are the source of truth for vitamin D deficiency."
                    )
                    .tag(1)

                    OnboardingAppleHealthPage(
                        isSyncing: isSyncingHealth,
                        onSync: {
                            Task { await syncHealthData() }
                        },
                        onSkip: {
                            withAnimation(.smooth) {
                                page = healthPage + 1
                            }
                        }
                    )
                    .tag(2)

                    basicsPage
                        .tag(3)

                    bodyPage
                        .tag(4)

                    levelPage
                        .tag(5)

                    supplementPage
                        .tag(6)

                    skinTypePage
                        .tag(7)

                    sunSafetyPage
                        .tag(8)

                    exposurePage
                        .tag(9)

                    alertsPage
                        .tag(10)

                    firstResultPage
                        .tag(11)

                    disclaimerPage
                        .tag(12)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                onboardingPageDots
                    .padding(.bottom, 4)

                if page != healthPage && page != disclaimerPageIndex {
                    primaryButton
                        .padding(.horizontal, 22)
                        .padding(.bottom, 18)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: page) {
            focusedField = nil
        }
        .onAppear {
            displayName = profile?.displayName ?? ""
            dateOfBirth = profile?.dateOfBirth ?? dateOfBirth
            biologicalSex = profile?.biologicalSex ?? .notSpecified
            let heightInches = Int(((profile?.heightCentimeters ?? 0) / 2.54).rounded())
            heightFeetText = heightInches > 0 ? String(heightInches / 12) : ""
            heightInchesText = heightInches > 0 ? String(heightInches % 12) : ""
            weightPoundsText = profile?.weightKilograms.map { String(Int(($0 * 2.20462).rounded())) } ?? ""
            levelKnowledge = profile?.levelKnowledge ?? .willAddLater
            baselineNanogramsText = profile?.baselineNanogramsPerMilliliter.map { String(Int($0.rounded())) } ?? ""
            goalNanogramsPerMilliliter = profile?.goalNanogramsPerMilliliter ?? 50
            exposedBodySurfaceArea = profile?.typicalExposedBodySurfaceArea ?? 0.25
            incidentalSunMinutesPerWeek = Double(profile?.incidentalSunMinutesPerWeek ?? 30)
            usuallyUsesSunscreen = profile?.usuallyUsesSunscreen ?? false
            defaultSupplementIUText = String(profile?.defaultSupplementIU ?? 1_000)
            wantsDWindowOpeningAlerts = profile?.wantsDWindowOpeningAlerts ?? true
            wantsDWindowClosingAlerts = profile?.wantsDWindowClosingAlerts ?? true
            wantsSolarNoonAlerts = profile?.wantsSolarNoonAlerts ?? true
            wantsSunriseSunsetAlerts = profile?.wantsSunriseSunsetAlerts ?? true
            wantsAMLightWindowAlerts = profile?.wantsAMLightWindowAlerts ?? true
            wantsNextDOpportunityAlerts = profile?.wantsNextDOpportunityAlerts ?? true
            wantsRiskAlerts = profile?.wantsRiskAlerts ?? true
            wantsSupplementReminders = profile?.wantsSupplementReminders ?? false
            wantsLabReminders = profile?.wantsLabReminders ?? true
            wantsWeeklyProgressAlerts = profile?.wantsWeeklyProgressAlerts ?? true
            wantsLevelTrendAlerts = profile?.wantsLevelTrendAlerts ?? true
            wantsMilestoneAlerts = profile?.wantsMilestoneAlerts ?? true
            wantsWeatherBreakAlerts = profile?.wantsWeatherBreakAlerts ?? false
            autoApplyDailySupplementIU = profile?.autoApplyDailySupplementIU ?? true
            selectedSkinType = profile?.skinType ?? .typeII
            wantsHealthKitSupplementExport = profile?.wantsHealthKitSupplementExport ?? false
        }
        .bigDoseAlert(
            healthAutofillTitle,
            isPresented: $isShowingHealthAutofillResult,
            message: healthAutofillMessage ?? "",
            actions: [
                .cancel("OK") {
                    if page == healthPage {
                        withAnimation(.smooth) {
                            page = healthPage + 1
                        }
                    }
                }
            ],
            backdropOpacity: healthAutofillTitle == "Apple Health Connected" ? 0.58 : 0.35,
            trailingImageName: healthAutofillTitle == "Apple Health Connected" ? "AppleHealthAppIcon" : nil
        )
        .onChange(of: isShowingHealthAutofillResult) { _, isShowing in
            guard isShowing else { return }
            BigDoseAlertFeedback.present(kind: .informational)
        }
        .bigDoseAlert(
            "Update Apple Health?",
            isPresented: $isShowingMetricSyncConfirmation,
            message: pendingMetricUpdate?.confirmationMessage ?? "",
            actions: [
                .default("Update Apple Health") {
                    Task {
                        await applyPendingMetricUpdate()
                        completeMetricSyncNextAction()
                    }
                },
                .cancel("Not Now") {
                    completeMetricSyncNextAction()
                }
            ]
        )
        .onChange(of: isShowingMetricSyncConfirmation) { _, isShowing in
            guard isShowing else { return }
            BigDoseAlertFeedback.present(kind: .informational)
        }
    }

    private var basicsPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                OnboardingHeader(
                    symbolName: "person.text.rectangle.fill",
                    eyebrow: "About You",
                    title: "Let’s make the meter personal."
                )

                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        OnboardingTextField(
                            title: "Name",
                            text: $displayName,
                            placeholder: "What should BigDose call you?",
                            focusedField: $focusedField,
                            field: .name
                        )

                        DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                            .font(.bigDoseHeader(.headline).weight(.semibold))
                            .foregroundStyle(.white)
                            .tint(.solarGold)

                        Picker("Biological Sex", selection: $biologicalSex) {
                            ForEach(BiologicalSex.allCases) { sex in
                                Text(sex.title).tag(sex)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Text("Age and biological sex can affect vitamin D metabolism.")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
            }
            .padding(22)
        }
    }

    private var bodyPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                OnboardingHeader(
                    symbolName: "figure.stand",
                    eyebrow: "Body Context",
                    title: "A little body context helps."
                )

                GlassCard {
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            OnboardingTextField(title: "Height", text: $heightFeetText, placeholder: "ft", keyboardType: .numberPad, focusedField: $focusedField, field: .heightFeet)
                            OnboardingTextField(title: "Inches", text: $heightInchesText, placeholder: "in", keyboardType: .numberPad, focusedField: $focusedField, field: .heightInches)
                        }

                        OnboardingTextField(title: "Weight", text: $weightPoundsText, placeholder: "lbs", keyboardType: .numberPad, focusedField: $focusedField, field: .weight)

                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .firstTextBaseline) {
                                HStack(spacing: 4) {
                                    Text("Goal Vitamin D Blood Level")
                                        .font(.bigDoseHeader(.headline).weight(.semibold))
                                        .foregroundStyle(.white)
                                    InfoCircleButton(topic: .goal, compact: true)
                                }

                                Spacer()

                                Text("\(Int(goalNanogramsPerMilliliter))")
                                    .font(.system(size: 36, weight: .semibold))
                                    .foregroundStyle(.solarGold)

                                Text("ng/mL")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.68))
                            }

                            Slider(value: $goalNanogramsPerMilliliter, in: 20...80, step: 1)
                                .tint(.solarGold)

                            Text("This is the blood-test number people usually mean when they say vitamin D level: 25(OH)D, measured in ng/mL. BigDose can estimate trends, but only a lab test can tell you the real number.")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.64))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                Text("Height and weight help personalize estimates. BigDose stores metric internally but shows U.S. units here.")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
            }
            .padding(22)
        }
    }

    private var skinTypePage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                OnboardingHeader(
                    symbolName: "person.crop.square.fill",
                    eyebrow: "Skin Type",
                    title: "What sounds closest?",
                    infoTopic: .skinType
                )

                Text("The Fitzpatrick scale runs Type I (very fair, burns easily) through Type VI (deep brown, least likely to burn). Pick the type that matches your sunburn history — not your tan goals.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.68))
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 10) {
                    ForEach(FitzpatrickSkinType.allCases) { skinType in
                        Button {
                            withAnimation(.smooth) {
                                selectedSkinType = skinType
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(skinType.title)
                                        .font(.bigDoseHeader(.headline).weight(.semibold))
                                    Text(skinType.subtitle)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.white.opacity(0.62))
                                }

                                Spacer()

                                Image(systemName: selectedSkinType == skinType ? "checkmark.circle.fill" : "circle")
                                    .font(.bigDoseHeader(.title3).weight(.bold))
                                    .foregroundStyle(selectedSkinType == skinType ? .solarGold : .white.opacity(0.35))
                            }
                            .foregroundStyle(.white)
                            .padding(14)
                            .bigDoseGlass(cornerRadius: 20)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("Your skin type sets BigDose's burn-risk and vitamin D time estimates. When unsure, choose the more burn-prone type.")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
            }
            .padding(22)
        }
    }

    private var sunSafetyPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                OnboardingHeader(
                    symbolName: "shield.lefthalf.filled",
                    eyebrow: "Sun Safety - READ THIS!",
                    title: "BigDose watches your burn risk.",
                    infoTopic: .sunSafetyOverview
                )

                CollapsibleGlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("UVB triggers vitamin D production in your skin. But too much sun exposure also burns skin, contributes to photoaging and raises long-term skin cancer risk with repeated overexposure.")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.72))
                            .fixedSize(horizontal: false, vertical: true)

                        Text("BigDose estimates your personal burn threshold from your skin type, UV, clouds and sunscreen. We track risk in real time, warn you at each milestone and never stop the session for you.")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.72))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                CollapsibleGlassCard(style: .hidden) {
                    HStack(spacing: 4) {
                        Text("During a sun session")
                            .font(.bigDoseHeader(.headline).weight(.semibold))
                            .foregroundStyle(.white)
                        InfoCircleButton(topic: .med, compact: true)
                    }
                } content: {
                    SunSafetyMilestoneGuide()
                }

                CollapsibleGlassCard(style: .hidden) {
                    Label("We stay vigilant", systemImage: "bell.badge.fill")
                        .font(.bigDoseHeader(.headline).weight(.semibold))
                        .foregroundStyle(.solarGold)
                } content: {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("During a live sun session, BigDose warns you when it is time to turn over, wrap up and come out of the sun — including background notifications when the app is closed. Only you stop the session.")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.72))
                            .fixedSize(horizontal: false, vertical: true)

                        Text("**Nanny in Settings → Session Safety** is on by default. She adds one extra reminder at **98% MED (burn risk)** while you stay out. Turn **Nanny** off anytime if you only want the **95%** guidance alert without the extra reminder — over-limit tracking still applies past **100%**.")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.72))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Text("These are conservative wellness estimates, not medical guarantees. Review the full explainer anytime in Profile → Science.")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
            }
            .padding(22)
        }
    }

    private var levelPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                OnboardingHeader(
                    symbolName: "testtube.2",
                    eyebrow: "Starting Level",
                    title: "Do you have a recent 25(OH)D result?",
                    infoTopic: .labResult25OHD
                )

                VStack(spacing: 10) {
                    ForEach(VitaminDLevelKnowledge.allCases) { option in
                        levelOptionCard(option)
                    }
                }

                Text("A lab result anchors the estimate. If you do not have one, BigDose starts conservatively and makes that clear everywhere.")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
            }
            .padding(22)
            .padding(.bottom, 28)
        }
    }

    private func levelOptionCard(_ option: VitaminDLevelKnowledge) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.smooth) {
                    levelKnowledge = option
                    if option == .knowsRecentResult {
                        focusedField = .baselineLevel
                    } else {
                        focusedField = nil
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: levelKnowledge == option ? "checkmark.circle.fill" : "circle")
                        .font(.bigDoseHeader(.title3).weight(.semibold))
                        .foregroundStyle(levelKnowledge == option ? .solarGold : .white.opacity(0.42))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(option.title)
                            .font(.bigDoseHeader(.headline).weight(.semibold))
                        Text(option.detail)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.62))
                    }

                    Spacer()
                }
                .foregroundStyle(.white)
                .padding(14)
            }
            .buttonStyle(.plain)

            if option == .knowsRecentResult, levelKnowledge == .knowsRecentResult {
                VStack(alignment: .leading, spacing: 16) {
                    Divider()
                        .overlay(.white.opacity(0.12))

                    OnboardingTextField(
                        title: "25(OH)D Result",
                        text: $baselineNanogramsText,
                        placeholder: "e.g. 42",
                        keyboardType: .decimalPad,
                        focusedField: $focusedField,
                        field: .baselineLevel
                    )

                    DatePicker("Measured", selection: $baselineMeasuredAt, displayedComponents: .date)
                        .font(.bigDoseHeader(.headline).weight(.semibold))
                        .foregroundStyle(.white)
                        .tint(.solarGold)

                    Text("This is the number from your lab report, usually labeled 25(OH)D or vitamin D, measured in ng/mL.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.58))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .bigDoseGlass(cornerRadius: 20)
    }

    private var supplementPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                OnboardingHeader(
                    symbolName: "pills.fill",
                    eyebrow: "Daily Intake",
                    title: "Do supplements belong in your baseline?",
                    infoTopic: .supplementBaseline
                )

                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        RecommendedDailyIUCard(
                            recommendation: onboardingDailyIURecommendation,
                            showsSunTarget: true
                        )

                        Divider()
                            .overlay(.white.opacity(0.12))

                        OnboardingTextField(
                            title: "Default Supplement",
                            text: $defaultSupplementIUText,
                            placeholder: "IU per dose",
                            keyboardType: .numberPad,
                            focusedField: $focusedField,
                            field: .defaultSupplement
                        )

                        Toggle("Remind me to log it", isOn: $wantsSupplementReminders)
                            .font(.bigDoseHeader(.headline).weight(.semibold))
                            .foregroundStyle(.white)
                            .tint(.solarGold)

                        Toggle("Save supplements to Apple Health", isOn: $wantsHealthKitSupplementExport)
                            .font(.bigDoseHeader(.headline).weight(.semibold))
                            .foregroundStyle(.white)
                            .tint(.solarGold)
                            .onChange(of: wantsHealthKitSupplementExport) { _, isEnabled in
                                guard isEnabled else { return }
                                Task { await requestSupplementWriteAccess() }
                            }
                    }
                }

                if didPrefillSupplementFromHealth {
                    Text("Default supplement was prefilled from recent vitamin D entries in Apple Health. Review before continuing.")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.solarGold)
                }

                Text("You can log one-off doses or use this value for a quick daily entry from Dashboard.")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
            }
            .padding(22)
        }
    }

    private var exposurePage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                OnboardingHeader(
                    symbolName: "tshirt.fill",
                    eyebrow: "Sun Habit",
                    title: "What's usually uncovered?",
                    infoTopic: .sunHabitOverview
                )

                Text("Set your usual daily walk-around outfit — how much skin is normally uncovered when you're outside, not how much do you have on right now. Long sleeves and pants mean less; shorts and a tee mean more. These are general habits that pre-fill sun sessions — not settings you re-enter for each session.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.68))
                    .fixedSize(horizontal: false, vertical: true)

                GlassCard {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 4) {
                                Text("Typical skin exposure")
                                    .font(.bigDoseHeader(.headline).weight(.semibold))
                                    .foregroundStyle(.white)
                                InfoCircleButton(topic: .typicalSkinExposure, compact: true)
                            }

                            HStack(alignment: .firstTextBaseline) {
                                Text("\(Int(exposedBodySurfaceArea * 100))")
                                    .font(.system(size: 48, weight: .semibold))
                                    .foregroundStyle(.solarGold)
                                Text("% uncovered")
                                    .font(.bigDoseHeader(.headline).weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.72))
                            }

                            Text(SkinExposurePreset.coverageLabel(for: exposedBodySurfaceArea))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.solarGold)

                            Slider(value: $exposedBodySurfaceArea, in: 0.05...0.65, step: 0.05)
                                .tint(.solarGold)

                            Text("Your usual outfit default — change per session in the planner if today is different.")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.62))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Divider()
                            .overlay(.white.opacity(0.12))

                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 4) {
                                Toggle("I usually wear sunscreen", isOn: $usuallyUsesSunscreen)
                                    .font(.bigDoseHeader(.headline).weight(.semibold))
                                    .foregroundStyle(.white)
                                    .tint(.solarGold)
                                InfoCircleButton(topic: .usualSunscreen, compact: true)
                            }

                            Text("Your general sunscreen habit — not a per-session choice.")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.62))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Divider()
                            .overlay(.white.opacity(0.12))

                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 4) {
                                Text("Casual outdoor time")
                                    .font(.bigDoseHeader(.headline).weight(.semibold))
                                    .foregroundStyle(.white)
                                InfoCircleButton(topic: .casualOutdoorTime, compact: true)
                            }

                            Text("\(Int(incidentalSunMinutesPerWeek)) minutes per week")
                                .font(.bigDoseHeader(.title2).weight(.semibold))
                                .foregroundStyle(.solarGold)

                            Slider(value: $incidentalSunMinutesPerWeek, in: 0...180, step: 5)
                                .tint(.solarGold)

                            Text("Background outdoor time in general — not tracked sun sessions.")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.62))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                Text("General habits live in Dose DNA and prefill the planner. Each sun session can still use different coverage or conditions.")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
            }
            .padding(22)
        }
    }

    private var alertsPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                OnboardingHeader(
                    symbolName: "bell.badge.fill",
                    eyebrow: "Guidance",
                    title: "Choose what BigDose can remind you about."
                )

                GlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Sun & D Window")
                            .font(.bigDoseHeader(.subheadline).weight(.semibold))
                            .foregroundStyle(.white.opacity(0.62))

                        Toggle("D window opening", isOn: $wantsDWindowOpeningAlerts)
                        Toggle("D window closing", isOn: $wantsDWindowClosingAlerts)
                        Toggle("Solar noon", isOn: $wantsSolarNoonAlerts)
                        Toggle("Sunrise & sunset", isOn: $wantsSunriseSunsetAlerts)
                        Toggle("AM light window (1°–3°)", isOn: $wantsAMLightWindowAlerts)
                        Toggle("Next D window opportunity", isOn: $wantsNextDOpportunityAlerts)

                        Text("Each sun alert fires 15 minutes before the event and again at the event time.")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.52))

                        Divider()
                            .overlay(.white.opacity(0.18))

                        Text("Other Guidance")
                            .font(.bigDoseHeader(.subheadline).weight(.semibold))
                            .foregroundStyle(.white.opacity(0.62))

                        VStack(alignment: .leading, spacing: 6) {
                            Toggle("Session safety guidance", isOn: $wantsRiskAlerts)

                            Text("Turn-over, wrap-up and stop alerts during live sun sessions — plus background notifications.")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.55))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Toggle("Supplement reminders", isOn: $wantsSupplementReminders)
                        Toggle("Lab retest reminders", isOn: $wantsLabReminders)
                        Toggle("Weekly progress", isOn: $wantsWeeklyProgressAlerts)
                        Toggle("Level trend notices", isOn: $wantsLevelTrendAlerts)
                        Toggle("Milestones", isOn: $wantsMilestoneAlerts)
                        Toggle("Weather break alerts", isOn: $wantsWeatherBreakAlerts)
                    }
                    .font(.bigDoseHeader(.headline).weight(.semibold))
                    .foregroundStyle(.white)
                    .tint(.solarGold)
                }

                Text("You can change these later. BigDose keeps reminder categories separate so one noisy category does not flood the rest.")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
            }
            .padding(22)
        }
    }

    private var firstResultPage: some View {
        ScrollView {
            VStack(spacing: 20) {
                OnboardingHeader(
                    symbolName: "sparkles",
                    eyebrow: "Your First Read",
                    title: "A smarter sun session starts here."
                )

                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        SunArcMeter(
                            progress: autoApplyDailySupplementIU
                                ? min(Double(defaultSupplementIU) / Double(max(defaultSupplementIU, 1_000)), 1)
                                : 0,
                            quality: autoApplyDailySupplementIU && defaultSupplementIU > 0 ? .prime : .low,
                            title: autoApplyDailySupplementIU ? "\(defaultSupplementIU)" : "0",
                            subtitle: autoApplyDailySupplementIU
                                ? "IU toward today"
                                : "Log manually or turn on auto-apply",
                            subtitleInfoTopic: .supplementBaseline
                        )

                        Toggle(isOn: $autoApplyDailySupplementIU) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Auto-apply daily supplement IU")
                                    .font(.bigDoseHeader(.headline).weight(.semibold))
                                    .foregroundStyle(.white)

                                Text("When on, BigDose adds your \(defaultSupplementIU) IU default to each day's total. When off, you log supplements yourself.")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.58))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .toggleStyle(.switch)
                        .tint(.solarGold)
                    }
                }

                Text("This is your saved default from setup — not a medical prescription. You can change the amount and this toggle anytime in Settings.")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
            }
            .padding(22)
        }
    }

    private var disclaimerPage: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    OnboardingHeader(
                        symbolName: "exclamationmark.shield.fill",
                        eyebrow: "Before You Enter",
                        title: "Use BigDose at your own risk."
                    )

                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            disclaimerSection(
                                title: "Wellness guidance only",
                                body: "BigDose provides informational wellness guidance about sunlight, supplements and vitamin D habits. It does not diagnose, treat, cure or prevent any disease and is not a substitute for professional medical advice, diagnosis or treatment."
                            )

                            disclaimerSection(
                                title: "Your responsibility",
                                body: "Sun exposure carries real risks including sunburn, skin damage and skin cancer. Supplement and food estimates are approximations. You alone decide how you use BigDose and any actions you take based on it."
                            )

                            disclaimerSection(
                                title: "No warranties",
                                body: "BigDose is provided \"as is\" without warranties of any kind, express or implied, including accuracy, fitness for a particular purpose or non-infringement."
                            )

                            disclaimerSection(
                                title: "Limitation of liability",
                                body: "To the fullest extent permitted by law, Cre8v Planet, BigRoll and their affiliates, officers, employees and partners accept no responsibility or liability for any injury, loss, damage or adverse outcome arising from your use of BigDose or reliance on its estimates, alerts or content — whether or not we were advised such outcomes were possible."
                            )

                            Text("If you have a medical condition, take medications or are unsure about sun or supplement choices, consult a qualified healthcare professional before changing your routine.")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.72))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(22)
                .padding(.bottom, 12)
            }
            .scrollIndicators(.hidden)

            BigDosePrimaryButton(
                title: "Accept & Enter BigDose",
                isEnabled: !isFinishingOnboarding && !isCheckingMetricSync
            ) {
                acceptDisclaimerAndFinish()
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 18)
        }
    }

    private func disclaimerSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.bigDoseHeader(.headline).weight(.semibold))
                .foregroundStyle(.solarGold)

            Text(body)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var onboardingPageDots: some View {
        HStack(spacing: 5) {
            ForEach(0..<onboardingPageCount, id: \.self) { index in
                Circle()
                    .fill(index == page ? Color.white : Color.white.opacity(0.28))
                    .frame(width: index == page ? 7 : 5, height: index == page ? 7 : 5)
            }
        }
        .animation(.smooth, value: page)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(page + 1) of \(onboardingPageCount)")
    }

    private var primaryButton: some View {
        BigDosePrimaryButton(
            title: "Continue",
            isEnabled: !isPrimaryButtonDisabled
        ) {
            advance()
        }
    }

    private var isPrimaryButtonDisabled: Bool {
        if isFinishingOnboarding || isCheckingMetricSync {
            return true
        }

        if page == levelPageIndex, levelKnowledge == .knowsRecentResult {
            return baselineNanogramsPerMilliliter == nil
        }

        return false
    }

    private func advance() {
        focusedField = nil

        if page == bodyPageIndex {
            offerMetricSyncBeforeContinuing(nextAction: .advancePage)
            return
        }

        if page == firstResultPageIndex {
            withAnimation(.smooth) {
                page = disclaimerPageIndex
            }
            return
        }

        withAnimation(.smooth) {
            page += 1
        }
    }

    private func acceptDisclaimerAndFinish() {
        focusedField = nil

        let activeProfile = profile ?? UserProfile()
        applyOnboardingValues(to: activeProfile)

        if profile == nil {
            modelContext.insert(activeProfile)
        }

        saveBaselineLabIfNeeded()
        try? modelContext.save()

        isFinishingOnboarding = true
        offerMetricSyncBeforeContinuing(nextAction: .finishOnboarding(activeProfile))
    }

    private func applyOnboardingValues(to activeProfile: UserProfile) {
        activeProfile.displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        activeProfile.dateOfBirth = dateOfBirth
        activeProfile.biologicalSex = biologicalSex
        activeProfile.heightCentimeters = heightCentimeters
        activeProfile.weightKilograms = weightKilograms
        activeProfile.levelKnowledge = levelKnowledge
        activeProfile.baselineNanogramsPerMilliliter = baselineNanogramsPerMilliliter
        activeProfile.goalNanogramsPerMilliliter = goalNanogramsPerMilliliter
        activeProfile.typicalExposedBodySurfaceArea = exposedBodySurfaceArea
        activeProfile.incidentalSunMinutesPerWeek = Int(incidentalSunMinutesPerWeek)
        activeProfile.usuallyUsesSunscreen = usuallyUsesSunscreen
        activeProfile.defaultSupplementIU = defaultSupplementIU
        activeProfile.autoApplyDailySupplementIU = autoApplyDailySupplementIU
        activeProfile.preferredDailyIU = onboardingDailyIURecommendation.sunSessionTargetIU
        activeProfile.wantsDWindowOpeningAlerts = wantsDWindowOpeningAlerts
        activeProfile.wantsDWindowClosingAlerts = wantsDWindowClosingAlerts
        activeProfile.wantsSolarNoonAlerts = wantsSolarNoonAlerts
        activeProfile.wantsSunriseSunsetAlerts = wantsSunriseSunsetAlerts
        activeProfile.wantsAMLightWindowAlerts = wantsAMLightWindowAlerts
        activeProfile.wantsNextDOpportunityAlerts = wantsNextDOpportunityAlerts
        activeProfile.wantsRiskAlerts = wantsRiskAlerts
        activeProfile.wantsSupplementReminders = wantsSupplementReminders
        activeProfile.wantsLabReminders = wantsLabReminders
        activeProfile.wantsWeeklyProgressAlerts = wantsWeeklyProgressAlerts
        activeProfile.wantsLevelTrendAlerts = wantsLevelTrendAlerts
        activeProfile.wantsMilestoneAlerts = wantsMilestoneAlerts
        activeProfile.wantsWeatherBreakAlerts = wantsWeatherBreakAlerts
        activeProfile.wantsHealthKitSupplementExport = wantsHealthKitSupplementExport
        activeProfile.skinType = selectedSkinType
        activeProfile.hasAcceptedWellnessDisclaimer = true
        activeProfile.isOnboardingComplete = true
        activeProfile.updatedAt = .now
        activeProfile.syncLegacySolarAlertPreferences()
    }

    private func offerMetricSyncBeforeContinuing(nextAction: MetricSyncNextAction) {
        isCheckingMetricSync = true
        metricSyncNextAction = nextAction

        let plannedHeightCentimeters = heightCentimeters
        let plannedWeightKilograms = weightKilograms

        Task { @MainActor in
            let plan = await healthKitImportService.profileMetricUpdatePlan(
                heightCentimeters: plannedHeightCentimeters,
                weightKilograms: plannedWeightKilograms
            )

            isCheckingMetricSync = false

            if let plan {
                pendingMetricUpdate = plan
                isShowingMetricSyncConfirmation = true
            } else {
                completeMetricSyncNextAction()
            }
        }
    }

    private func completeMetricSyncNextAction() {
        guard let metricSyncNextAction else { return }

        switch metricSyncNextAction {
        case .advancePage:
            withAnimation(.smooth) {
                page += 1
            }
        case .finishOnboarding(let profile):
            finishOnboarding(profile: profile)
        }

        pendingMetricUpdate = nil
        self.metricSyncNextAction = nil
    }

    private func finishOnboarding(profile: UserProfile) {
        isFinishingOnboarding = false

        DailySupplementAutoApplyService.applyIfNeeded(
            profile: profile,
            supplements: supplements,
            modelContext: modelContext
        )

        Task {
            await BigDoseNotificationCoordinator.refreshManagedAlerts(
                profile: profile,
                modelContext: modelContext
            )
        }
        onFinished?()
        dismiss()
    }

    private func applyPendingMetricUpdate() async {
        guard let pendingMetricUpdate else { return }

        do {
            try await healthKitImportService.requestProfileMetricsWriteAuthorization()
            try await healthKitImportService.applyProfileMetricUpdates(pendingMetricUpdate)
        } catch {
            return
        }
    }

    private var heightCentimeters: Double? {
        guard let feet = Double(heightFeetText), let inches = Double(heightInchesText) else {
            return nil
        }

        return (feet * 12 + inches) * 2.54
    }

    private var weightKilograms: Double? {
        guard let pounds = Double(weightPoundsText) else {
            return nil
        }

        return pounds / 2.20462
    }

    private func syncHealthData() async {
        isSyncingHealth = true
        defer { isSyncingHealth = false }

        do {
            let autofill = try await healthKitImportService.fetchProfileAutofill()
            apply(autofill)
            profile?.healthKitImportStatus = .authorized

            if autofill.filledFields.isEmpty {
                healthAutofillTitle = "Apple Health Connected"
                healthAutofillMessage = "Permission was granted, but Apple Health did not share profile fields yet. You can enter them manually on the next screens."
            } else {
                healthAutofillTitle = "Apple Health Connected"
                var message = "Filled \(autofill.filledFields.joined(separator: ", ")) from Apple Health."
                if !autofill.missingFields.isEmpty {
                    message += "\n\nNot found or not shared: \(autofill.missingFields.joined(separator: ", "))."
                }
                healthAutofillMessage = message
            }

            isShowingHealthAutofillResult = true
        } catch {
            healthAutofillTitle = "Apple Health Unavailable"
            healthAutofillMessage = "Apple Health sync was not available: \(error.localizedDescription)"
            isShowingHealthAutofillResult = true
        }
    }

    private func apply(_ autofill: HealthProfileAutofill) {
        if let dateOfBirth = autofill.dateOfBirth {
            self.dateOfBirth = dateOfBirth
        }

        if let biologicalSex = autofill.biologicalSex {
            self.biologicalSex = biologicalSex
        }

        if let heightCentimeters = autofill.heightCentimeters {
            let inches = Int((heightCentimeters / 2.54).rounded())
            heightFeetText = String(inches / 12)
            heightInchesText = String(inches % 12)
        }

        if let weightKilograms = autofill.weightKilograms {
            weightPoundsText = String(Int((weightKilograms * 2.20462).rounded()))
        }

        if let skinType = autofill.skinType {
            selectedSkinType = skinType
        }

        if let suggestedDefaultSupplementIU = autofill.suggestedDefaultSupplementIU {
            defaultSupplementIUText = String(suggestedDefaultSupplementIU)
            didPrefillSupplementFromHealth = true
        }
    }

    private func requestSupplementWriteAccess() async {
        do {
            try await healthKitImportService.requestSupplementWriteAuthorization()
        } catch {
            wantsHealthKitSupplementExport = false
            healthAutofillTitle = "Apple Health Write Unavailable"
            healthAutofillMessage = "BigDose could not get permission to save supplements to Apple Health: \(error.localizedDescription)"
            isShowingHealthAutofillResult = true
        }
    }

    private var baselineNanogramsPerMilliliter: Double? {
        guard levelKnowledge == .knowsRecentResult else {
            return nil
        }

        return Double(baselineNanogramsText)
    }

    private var onboardingDailyIURecommendation: OptimalDailyIURecommendation {
        OptimalDailyIUService.recommend(
            dateOfBirth: dateOfBirth,
            biologicalSex: biologicalSex,
            weightKilograms: weightKilograms,
            goalNanogramsPerMilliliter: goalNanogramsPerMilliliter,
            baselineNanogramsPerMilliliter: baselineNanogramsPerMilliliter,
            levelKnowledge: levelKnowledge,
            incidentalSunMinutesPerWeek: Int(incidentalSunMinutesPerWeek),
            defaultSupplementIU: defaultSupplementIU
        )
    }

    private var defaultSupplementIU: Int {
        max(Int(defaultSupplementIUText) ?? 0, 0)
    }

    private func saveBaselineLabIfNeeded() {
        guard let baselineNanogramsPerMilliliter else { return }

        let alreadySaved = labResults.contains { result in
            Calendar.current.isDate(result.measuredAt, inSameDayAs: baselineMeasuredAt)
                && abs(result.nanogramsPerMilliliter - baselineNanogramsPerMilliliter) < 0.1
        }

        guard !alreadySaved else { return }

        modelContext.insert(
            LabResult(
                measuredAt: baselineMeasuredAt,
                nanogramsPerMilliliter: baselineNanogramsPerMilliliter,
                note: "Added during setup"
            )
        )
    }
}

private struct OnboardingPageView: View {
    var symbolName: String
    var eyebrow: String
    var title: String
    var detail: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            OnboardingHeader(symbolName: symbolName, eyebrow: eyebrow, title: title)

            Text(detail)
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.72))
                .padding(.horizontal, 24)
            Spacer()
        }
        .padding(22)
    }
}

private struct OnboardingHeader: View {
    var symbolName: String
    var eyebrow: String
    var title: String
    var infoTopic: BigDoseInfoTopic?

    init(
        symbolName: String,
        eyebrow: String,
        title: String,
        infoTopic: BigDoseInfoTopic? = nil
    ) {
        self.symbolName = symbolName
        self.eyebrow = eyebrow
        self.title = title
        self.infoTopic = infoTopic
    }

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbolName)
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(.solarGold)
                .symbolEffect(.bounce, value: title)

            Text(eyebrow.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(1.8)
                .foregroundStyle(.solarGold)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(title)
                    .font(.bigDoseHeader(.largeTitle))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.82)
                    .fixedSize(horizontal: false, vertical: true)

                if let infoTopic {
                    InfoCircleButton(topic: infoTopic, compact: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

private struct OnboardingTextField: View {
    var title: String
    @Binding var text: String
    var placeholder: String
    var keyboardType: UIKeyboardType = .default
    var focusedField: FocusState<OnboardingField?>.Binding
    var field: OnboardingField

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.6))

            TextField(placeholder, text: $text)
                .font(.bigDoseHeader(.headline).weight(.semibold))
                .foregroundStyle(.white)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.words)
                .focused(focusedField, equals: field)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            focusedField.wrappedValue = nil
                        }
                    }
                }
                .padding(14)
                .background(.white.opacity(0.08), in: .rect(cornerRadius: 16))
        }
    }
}

private enum MetricSyncNextAction {
    case advancePage
    case finishOnboarding(UserProfile)
}

private enum OnboardingField: Hashable {
    case name
    case heightFeet
    case heightInches
    case weight
    case baselineLevel
    case defaultSupplement
}

#Preview {
    OnboardingView(profile: .preview)
        .modelContainer(BigDoseModelContainerFactory.preview)
}

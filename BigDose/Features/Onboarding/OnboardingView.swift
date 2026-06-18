import SwiftData
import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LabResult.measuredAt, order: .reverse) private var labResults: [LabResult]
    @FocusState private var focusedField: OnboardingField?
    var profile: UserProfile?

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
    @State private var wantsSolarWindowAlerts = true
    @State private var wantsRiskAlerts = true
    @State private var wantsSupplementReminders = false
    @State private var wantsLabReminders = true
    @State private var wantsWeeklyProgressAlerts = true
    @State private var selectedSkinType: FitzpatrickSkinType = .typeII
    @State private var acceptedDisclaimer = false
    @State private var page = 0
    @State private var isAutofillingFromHealth = false
    @State private var healthAutofillMessage: String?
    @State private var healthAutofillTitle = "Apple Health Autofill"
    @State private var isShowingHealthAutofillResult = false
    @State private var healthKitImportService = HealthKitImportService()

    private let lastPage = 9

    var body: some View {
        ZStack {
            BigDoseGradientBackground()

            VStack(spacing: 24) {
                TabView(selection: $page) {
                    OnboardingPageView(
                        symbolName: "sun.max.fill",
                        eyebrow: "BigDose",
                        title: "Find your best sunlight window.",
                        detail: "We look at your location, the sun angle, UV index, and your profile to estimate useful vitamin D time."
                    )
                    .tag(0)

                    OnboardingPageView(
                        symbolName: "shield.lefthalf.filled",
                        eyebrow: "Not Medical Advice",
                        title: "Useful guidance. Not a diagnosis.",
                        detail: "BigDose is wellness information you can choose to use. Labs and clinicians are the source of truth for vitamin D deficiency."
                    )
                    .tag(1)

                    basicsPage
                        .tag(2)

                    bodyPage
                        .tag(3)

                    levelPage
                        .tag(4)

                    supplementPage
                        .tag(5)

                    skinTypePage
                        .tag(6)

                    exposurePage
                        .tag(7)

                    alertsPage
                        .tag(8)

                    firstResultPage
                        .tag(9)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                primaryButton
                    .padding(.horizontal, 22)
                    .padding(.bottom, 18)
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
            wantsSolarWindowAlerts = profile?.wantsSolarWindowAlerts ?? true
            wantsRiskAlerts = profile?.wantsRiskAlerts ?? true
            wantsSupplementReminders = profile?.wantsSupplementReminders ?? false
            wantsLabReminders = profile?.wantsLabReminders ?? true
            wantsWeeklyProgressAlerts = profile?.wantsWeeklyProgressAlerts ?? true
            selectedSkinType = profile?.skinType ?? .typeII
            acceptedDisclaimer = profile?.hasAcceptedWellnessDisclaimer ?? false
        }
        .alert(healthAutofillTitle, isPresented: $isShowingHealthAutofillResult) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(healthAutofillMessage ?? "")
        }
        .onChange(of: isShowingHealthAutofillResult) { _, isShowing in
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
                            .font(.headline.weight(.semibold))
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

                Button {
                    Task {
                        await autofillFromHealth()
                    }
                } label: {
                    Label(isAutofillingFromHealth ? "Checking Apple Health" : "Autofill from Apple Health", systemImage: "heart.fill")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                }
                .buttonStyle(.bordered)
                .tint(.solarGold)
                .disabled(isAutofillingFromHealth)

                if let healthAutofillMessage {
                    Text(healthAutofillMessage)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.68))
                }

                Text("Age and biological sex can affect vitamin D metabolism. We keep this local in SwiftData.")
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
                                Text("Goal Vitamin D Blood Level")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.white)

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
                    title: "What sounds closest?"
                )

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
                                        .font(.headline.weight(.semibold))
                                    Text(skinType.subtitle)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.white.opacity(0.62))
                                }

                                Spacer()

                                Image(systemName: selectedSkinType == skinType ? "checkmark.circle.fill" : "circle")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(selectedSkinType == skinType ? .solarGold : .white.opacity(0.35))
                            }
                            .foregroundStyle(.white)
                            .padding(14)
                            .bigDoseGlass(cornerRadius: 20)
                        }
                        .buttonStyle(.plain)
                    }
                }
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
                    title: "Do you have a recent 25(OH)D result?"
                )

                VStack(spacing: 10) {
                    ForEach(VitaminDLevelKnowledge.allCases) { option in
                        Button {
                            withAnimation(.smooth) {
                                levelKnowledge = option
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: levelKnowledge == option ? "checkmark.circle.fill" : "circle")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(levelKnowledge == option ? .solarGold : .white.opacity(0.42))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(option.title)
                                        .font(.headline.weight(.semibold))
                                    Text(option.detail)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.white.opacity(0.62))
                                }

                                Spacer()
                            }
                            .foregroundStyle(.white)
                            .padding(14)
                            .bigDoseGlass(cornerRadius: 20)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if levelKnowledge == .knowsRecentResult {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            OnboardingTextField(
                                title: "25(OH)D Result",
                                text: $baselineNanogramsText,
                                placeholder: "ng/mL",
                                keyboardType: .decimalPad,
                                focusedField: $focusedField,
                                field: .baselineLevel
                            )

                            DatePicker("Measured", selection: $baselineMeasuredAt, displayedComponents: .date)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white)
                                .tint(.solarGold)
                        }
                    }
                }

                Text("A lab result anchors the estimate. If you do not have one, BigDose starts conservatively and makes that clear everywhere.")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
            }
            .padding(22)
        }
    }

    private var supplementPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                OnboardingHeader(
                    symbolName: "pills.fill",
                    eyebrow: "Daily Intake",
                    title: "Do supplements belong in your baseline?"
                )

                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        OnboardingTextField(
                            title: "Default Supplement",
                            text: $defaultSupplementIUText,
                            placeholder: "IU per dose",
                            keyboardType: .numberPad,
                            focusedField: $focusedField,
                            field: .defaultSupplement
                        )

                        Toggle("Remind me to log it", isOn: $wantsSupplementReminders)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .tint(.solarGold)
                    }
                }

                Text("You can log one-off doses or use this value for a quick daily entry from Home.")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
            }
            .padding(22)
        }
    }

    private var exposurePage: some View {
        VStack(alignment: .leading, spacing: 18) {
            OnboardingHeader(
                symbolName: "sun.horizon.fill",
                eyebrow: "Sun Habit",
                title: "What does ordinary sun look like?"
            )

            GlassCard {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(Int(exposedBodySurfaceArea * 100))")
                            .font(.system(size: 48, weight: .semibold))
                            .foregroundStyle(.solarGold)
                        Text("% exposed")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.72))
                    }

                    Slider(value: $exposedBodySurfaceArea, in: 0.05...0.65, step: 0.05)
                        .tint(.solarGold)

                    Toggle("I usually wear sunscreen", isOn: $usuallyUsesSunscreen)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .tint(.solarGold)

                    Divider()
                        .overlay(.white.opacity(0.12))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("\(Int(incidentalSunMinutesPerWeek)) minutes per week")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.solarGold)

                        Slider(value: $incidentalSunMinutesPerWeek, in: 0...180, step: 5)
                            .tint(.solarGold)

                        Text("Incidental outdoor time means casual exposure: walking, errands, yard work, or lunch outside.")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.62))
                    }
                }
            }

            Text("More exposed skin usually means less time needed. Sunscreen reduces UVB transmission, so BigDose adjusts the estimate.")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.62))
        }
        .padding(22)
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
                        Toggle("Useful sunlight timing", isOn: $wantsSolarWindowAlerts)
                        Toggle("Skin-limit safety guidance", isOn: $wantsRiskAlerts)
                        Toggle("Supplement logging", isOn: $wantsSupplementReminders)
                        Toggle("Lab retest cadence", isOn: $wantsLabReminders)
                        Toggle("Weekly progress", isOn: $wantsWeeklyProgressAlerts)
                    }
                    .font(.headline.weight(.semibold))
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
        VStack(spacing: 20) {
            OnboardingHeader(
                symbolName: "sparkles",
                eyebrow: "Your First Read",
                title: "A smarter sun session starts here."
            )

            GlassCard {
                SunArcMeter(
                    progress: min(Double(defaultSupplementIU) / Double(max(defaultSupplementIU, 1_000)), 1),
                    quality: defaultSupplementIU > 0 ? .prime : .low,
                    title: "\(defaultSupplementIU)",
                    subtitle: "IU supplement baseline"
                )
            }

            Toggle(isOn: $acceptedDisclaimer) {
                Text("I understand BigDose is informational wellness guidance, not medical advice.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.78))
            }
            .toggleStyle(.switch)
            .tint(.solarGold)
            .padding(18)
            .bigDoseGlass(cornerRadius: 24)

            if !acceptedDisclaimer {
                Text("Required before entering BigDose.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.solarGold)
            }
        }
        .padding(22)
    }

    private var primaryButton: some View {
        Button {
            advance()
        } label: {
            Text(page == lastPage ? "Enter BigDose" : "Continue")
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .tint(.solarOrange)
        .disabled(page == lastPage && !acceptedDisclaimer)
    }

    private func advance() {
        focusedField = nil

        if page == lastPage && !acceptedDisclaimer {
            return
        }

        guard page == lastPage else {
            withAnimation(.smooth) {
                page += 1
            }
            return
        }

        let activeProfile = profile ?? UserProfile()
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
        activeProfile.preferredDailyIU = max(defaultSupplementIU, 1_000)
        activeProfile.wantsWindowReminders = wantsSolarWindowAlerts
        activeProfile.wantsSolarWindowAlerts = wantsSolarWindowAlerts
        activeProfile.wantsRiskAlerts = wantsRiskAlerts
        activeProfile.wantsSupplementReminders = wantsSupplementReminders
        activeProfile.wantsLabReminders = wantsLabReminders
        activeProfile.wantsWeeklyProgressAlerts = wantsWeeklyProgressAlerts
        activeProfile.skinType = selectedSkinType
        activeProfile.hasAcceptedWellnessDisclaimer = acceptedDisclaimer
        activeProfile.isOnboardingComplete = true
        activeProfile.updatedAt = .now

        if profile == nil {
            modelContext.insert(activeProfile)
        }

        saveBaselineLabIfNeeded()
        try? modelContext.save()
        Task {
            await BigDoseNotificationCoordinator.refreshManagedAlerts(
                profile: activeProfile,
                modelContext: modelContext
            )
        }
        dismiss()
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

    private func autofillFromHealth() async {
        isAutofillingFromHealth = true
        defer { isAutofillingFromHealth = false }

        do {
            let autofill = try await healthKitImportService.fetchProfileAutofill()
            apply(autofill)

            if autofill.filledFields.isEmpty {
                healthAutofillTitle = "Nothing to Autofill"
                healthAutofillMessage = "Apple Health did not return profile fields for BigDose to fill. You can keep entering them manually."
            } else {
                healthAutofillTitle = "Autofill Complete"
                var message = "Filled \(autofill.filledFields.joined(separator: ", ")) from Apple Health. Review before continuing."
                if !autofill.missingFields.isEmpty {
                    message += "\n\nNot found or not shared: \(autofill.missingFields.joined(separator: ", "))."
                }
                if autofill.heightCentimeters != nil || autofill.weightKilograms != nil {
                    message += "\n\nContinue to Body Context to review height and weight."
                }
                healthAutofillMessage = message
            }
            isShowingHealthAutofillResult = true
        } catch {
            healthAutofillTitle = "Apple Health Unavailable"
            healthAutofillMessage = "Apple Health autofill was not available: \(error.localizedDescription)"
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
    }

    private var baselineNanogramsPerMilliliter: Double? {
        guard levelKnowledge == .knowsRecentResult else {
            return nil
        }

        return Double(baselineNanogramsText)
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
                .font(.title3.weight(.semibold))
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

            Text(title)
                .font(.system(.largeTitle, weight: .semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.82)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
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
                .font(.headline.weight(.semibold))
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

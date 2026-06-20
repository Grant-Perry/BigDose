import SwiftData
import SwiftUI

struct DoseDNAEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @FocusState private var focusedField: DoseDNAField?

    @Bindable var profile: UserProfile

    @State private var displayName = ""
    @State private var dateOfBirth = Date.now
    @State private var biologicalSex: BiologicalSex = BiologicalSex.notSpecified
    @State private var heightFeetText = ""
    @State private var heightInchesText = ""
    @State private var weightPoundsText = ""
    @State private var selectedSkinType: FitzpatrickSkinType = FitzpatrickSkinType.typeII
    @State private var goalNanogramsPerMilliliter = 50.0
    @State private var exposedBodySurfaceArea = 0.25
    @State private var incidentalSunMinutesPerWeek = 30.0
    @State private var usuallyUsesSunscreen = false
    @State private var defaultSupplementIUText = "1000"
    @State private var avatarImageData: Data?
    @State private var isShowingAvatarEditor = false
    @State private var hasLoadedFromProfile = false
    @State private var healthKitImportService = HealthKitImportService()

    var body: some View {
        ZStack {
            BigDoseGradientBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    avatarCard
                    basicsCard
                    bodyCard
                    skinTypeCard
                    exposureCard
                    supplementCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Edit Profile")
        .toolbarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .sheet(isPresented: $isShowingAvatarEditor) {
            ProfileAvatarEditorView(existingImageData: avatarImageData) { data in
                avatarImageData = data
                persistProfile()
            }
        }
        .onAppear(perform: loadFromProfile)
        .onDisappear(perform: persistProfile)
        .onChange(of: displayName) { _, _ in persistProfile() }
        .onChange(of: dateOfBirth) { _, _ in persistProfile() }
        .onChange(of: biologicalSex) { _, _ in persistProfile() }
        .onChange(of: heightFeetText) { _, _ in persistProfile() }
        .onChange(of: heightInchesText) { _, _ in persistProfile() }
        .onChange(of: weightPoundsText) { _, _ in persistProfile() }
        .onChange(of: selectedSkinType) { _, _ in persistProfile() }
        .onChange(of: goalNanogramsPerMilliliter) { _, _ in persistProfile() }
        .onChange(of: exposedBodySurfaceArea) { _, _ in persistProfile() }
        .onChange(of: incidentalSunMinutesPerWeek) { _, _ in persistProfile() }
        .onChange(of: usuallyUsesSunscreen) { _, _ in persistProfile() }
        .onChange(of: defaultSupplementIUText) { _, _ in persistProfile() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Edit Dose DNA")
                .font(.system(.largeTitle, weight: .semibold))
                .foregroundStyle(.white)

            Text("Changes save automatically as you edit.")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
        }
    }

    private var avatarCard: some View {
        GlassCard {
            HStack(spacing: 16) {
                Button {
                    isShowingAvatarEditor = true
                } label: {
                    ProfileAvatarView(imageData: avatarImageData, diameter: 88, showsEditBadge: true)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 6) {
                    Text(displayName.isEmpty ? "Add your name" : displayName)
                        .font(.bigDoseHeader(.title2).weight(.black))
                        .foregroundStyle(.white)

                    Text("Tap the photo to choose, zoom, and crop.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var basicsCard: some View {
        sectionCard(title: "About You", systemImage: "person.text.rectangle.fill") {
            DoseDNATextField(
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

    private var bodyCard: some View {
        sectionCard(title: "Body Context", systemImage: "figure.stand") {
            HStack(spacing: 12) {
                DoseDNATextField(
                    title: "Height",
                    text: $heightFeetText,
                    placeholder: "ft",
                    keyboardType: .numberPad,
                    focusedField: $focusedField,
                    field: .heightFeet
                )
                DoseDNATextField(
                    title: "Inches",
                    text: $heightInchesText,
                    placeholder: "in",
                    keyboardType: .numberPad,
                    focusedField: $focusedField,
                    field: .heightInches
                )
            }

            DoseDNATextField(
                title: "Weight",
                text: $weightPoundsText,
                placeholder: "lbs",
                keyboardType: .numberPad,
                focusedField: $focusedField,
                field: .weight
            )

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Target Vitamin D Blood Level")
                        .font(.bigDoseHeader(.headline).weight(.semibold))
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
            }
        }
    }

    private var skinTypeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Skin Type", systemImage: "person.crop.square.fill")

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
    }

    private var exposureCard: some View {
        sectionCard(title: "Sun Habit", systemImage: "sun.horizon.fill") {
            HStack(alignment: .firstTextBaseline) {
                Text("\(Int(exposedBodySurfaceArea * 100))")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(.solarGold)
                Text("% skin exposed")
                    .font(.bigDoseHeader(.headline).weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))
            }

            Slider(value: $exposedBodySurfaceArea, in: 0.05...0.65, step: 0.05)
                .tint(.solarGold)

            Toggle("I usually wear sunscreen", isOn: $usuallyUsesSunscreen)
                .font(.bigDoseHeader(.headline).weight(.semibold))
                .foregroundStyle(.white)
                .tint(.solarGold)

            Divider().overlay(.white.opacity(0.12))

            Text("\(Int(incidentalSunMinutesPerWeek)) minutes per week")
                .font(.bigDoseHeader(.title3).weight(.semibold))
                .foregroundStyle(.solarGold)

            Slider(value: $incidentalSunMinutesPerWeek, in: 0...180, step: 5)
                .tint(.solarGold)
        }
    }

    private var supplementCard: some View {
        sectionCard(title: "Daily Supplement", systemImage: "pills.fill") {
            DoseDNATextField(
                title: "Default Supplement",
                text: $defaultSupplementIUText,
                placeholder: "IU per dose",
                keyboardType: .numberPad,
                focusedField: $focusedField,
                field: .defaultSupplement
            )

            Toggle("Save supplements to Apple Health", isOn: $profile.wantsHealthKitSupplementExport)
                .font(.bigDoseHeader(.headline).weight(.semibold))
                .foregroundStyle(.white)
                .tint(.solarGold)
                .onChange(of: profile.wantsHealthKitSupplementExport) { _, isEnabled in
                    guard isEnabled else { return }
                    Task { await requestSupplementWriteAccess() }
                }
        }
    }

    private func sectionCard<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(title, systemImage: systemImage)

            GlassCard {
                VStack(alignment: .leading, spacing: 16) {
                    content()
                }
            }
        }
    }

    private func sectionLabel(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.bigDoseHeader(.title3).weight(.semibold))
            .foregroundStyle(.white)
    }

    private func loadFromProfile() {
        guard !hasLoadedFromProfile else { return }

        displayName = profile.displayName
        avatarImageData = profile.avatarImageData
        dateOfBirth = profile.dateOfBirth ?? dateOfBirth
        biologicalSex = profile.biologicalSex
        let heightInches = Int(((profile.heightCentimeters ?? 0) / 2.54).rounded())
        heightFeetText = heightInches > 0 ? String(heightInches / 12) : ""
        heightInchesText = heightInches > 0 ? String(heightInches % 12) : ""
        weightPoundsText = profile.weightKilograms.map { String(Int(($0 * 2.20462).rounded())) } ?? ""
        selectedSkinType = profile.skinType
        goalNanogramsPerMilliliter = profile.goalNanogramsPerMilliliter
        exposedBodySurfaceArea = profile.typicalExposedBodySurfaceArea
        incidentalSunMinutesPerWeek = Double(profile.incidentalSunMinutesPerWeek)
        usuallyUsesSunscreen = profile.usuallyUsesSunscreen
        defaultSupplementIUText = String(profile.defaultSupplementIU)

        hasLoadedFromProfile = true
    }

    private func persistProfile() {
        guard hasLoadedFromProfile else { return }

        profile.displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.avatarImageData = avatarImageData
        profile.dateOfBirth = dateOfBirth
        profile.biologicalSex = biologicalSex
        profile.heightCentimeters = heightCentimeters
        profile.weightKilograms = weightKilograms
        profile.skinType = selectedSkinType
        profile.goalNanogramsPerMilliliter = goalNanogramsPerMilliliter
        profile.typicalExposedBodySurfaceArea = exposedBodySurfaceArea
        profile.incidentalSunMinutesPerWeek = Int(incidentalSunMinutesPerWeek)
        profile.usuallyUsesSunscreen = usuallyUsesSunscreen
        profile.defaultSupplementIU = defaultSupplementIU
        profile.preferredDailyIU = max(defaultSupplementIU, 1_000)
        profile.updatedAt = Date.now

        try? modelContext.save()
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

    private var defaultSupplementIU: Int {
        Int(defaultSupplementIUText) ?? profile.defaultSupplementIU
    }

    private func requestSupplementWriteAccess() async {
        do {
            try await healthKitImportService.requestSupplementWriteAuthorization()
            try? modelContext.save()
        } catch {
            profile.wantsHealthKitSupplementExport = false
            try? modelContext.save()
        }
    }
}

struct DoseDNAEditorContainer: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var profile: UserProfile

    @State private var healthKitImportService = HealthKitImportService()
    @State private var pendingMetricUpdate: HealthProfileMetricUpdatePlan?
    @State private var isShowingMetricSyncConfirmation = false

    var body: some View {
        DoseDNAEditorView(profile: profile)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task { await prepareToLeave() }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.bigDoseHeader(.headline).weight(.semibold))
                    }
                    .accessibilityLabel("Back")
                }
            }
            .bigDoseAlert(
                "Update Apple Health?",
                isPresented: $isShowingMetricSyncConfirmation,
                message: pendingMetricUpdate?.confirmationMessage ?? "",
                actions: [
                    .default("Update Apple Health") {
                        Task {
                            await applyPendingMetricUpdate()
                            pendingMetricUpdate = nil
                            dismiss()
                        }
                    },
                    .cancel("Not Now") {
                        pendingMetricUpdate = nil
                        dismiss()
                    }
                ]
            )
            .onChange(of: isShowingMetricSyncConfirmation) { _, isShowing in
                guard isShowing else { return }
                BigDoseAlertFeedback.present(kind: .informational)
            }
    }

    private func prepareToLeave() async {
        let plan = await healthKitImportService.profileMetricUpdatePlan(
            heightCentimeters: profile.heightCentimeters,
            weightKilograms: profile.weightKilograms
        )

        if let plan {
            pendingMetricUpdate = plan
            isShowingMetricSyncConfirmation = true
        } else {
            dismiss()
        }
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
}

private enum DoseDNAField: Hashable {
    case name
    case heightFeet
    case heightInches
    case weight
    case defaultSupplement
}

private struct DoseDNATextField: View {
    var title: String
    @Binding var text: String
    var placeholder: String
    var keyboardType: UIKeyboardType = .default
    var focusedField: FocusState<DoseDNAField?>.Binding
    var field: DoseDNAField

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.6))

            TextField(placeholder, text: $text)
                .font(.bigDoseHeader(.headline).weight(.semibold))
                .foregroundStyle(.white)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(field == .name ? .words : .never)
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

#Preview {
    NavigationStack {
        DoseDNAEditorView(profile: .preview)
    }
    .modelContainer(BigDoseModelContainerFactory.preview)
}

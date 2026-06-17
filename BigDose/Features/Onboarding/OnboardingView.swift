import SwiftData
import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @FocusState private var focusedField: OnboardingField?
    var profile: UserProfile?

    @State private var displayName = ""
    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -40, to: .now) ?? .now
    @State private var biologicalSex: BiologicalSex = .notSpecified
    @State private var heightFeetText = ""
    @State private var heightInchesText = ""
    @State private var weightPoundsText = ""
    @State private var goalNanogramsPerMilliliter = 50.0
    @State private var exposedBodySurfaceArea = 0.25
    @State private var usuallyUsesSunscreen = false
    @State private var selectedSkinType: FitzpatrickSkinType = .typeII
    @State private var acceptedDisclaimer = false
    @State private var page = 0

    private let lastPage = 6

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

                    skinTypePage
                        .tag(4)

                    exposurePage
                        .tag(5)

                    firstResultPage
                        .tag(6)
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
            goalNanogramsPerMilliliter = profile?.goalNanogramsPerMilliliter ?? 50
            exposedBodySurfaceArea = profile?.typicalExposedBodySurfaceArea ?? 0.25
            usuallyUsesSunscreen = profile?.usuallyUsesSunscreen ?? false
            selectedSkinType = profile?.skinType ?? .typeII
            acceptedDisclaimer = profile?.hasAcceptedWellnessDisclaimer ?? false
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

    private var exposurePage: some View {
        VStack(alignment: .leading, spacing: 18) {
            OnboardingHeader(
                symbolName: "sun.horizon.fill",
                eyebrow: "Sun Habit",
                title: "How much skin usually sees sun?"
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
                }
            }

            Text("More exposed skin usually means less time needed. Sunscreen reduces UVB transmission, so BigDose adjusts the estimate.")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.62))
        }
        .padding(22)
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
                    progress: 0.68,
                    quality: .prime,
                    title: "14m",
                    subtitle: "demo target"
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
        activeProfile.goalNanogramsPerMilliliter = goalNanogramsPerMilliliter
        activeProfile.typicalExposedBodySurfaceArea = exposedBodySurfaceArea
        activeProfile.usuallyUsesSunscreen = usuallyUsesSunscreen
        activeProfile.skinType = selectedSkinType
        activeProfile.hasAcceptedWellnessDisclaimer = acceptedDisclaimer
        activeProfile.isOnboardingComplete = true
        activeProfile.updatedAt = .now

        if profile == nil {
            modelContext.insert(activeProfile)
        }

        try? modelContext.save()
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
}

#Preview {
    OnboardingView(profile: .preview)
        .modelContainer(BigDoseModelContainerFactory.preview)
}

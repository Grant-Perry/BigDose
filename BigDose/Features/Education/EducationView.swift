import SwiftUI

struct EducationView: View {
    private let scienceSections = [
        EducationSection(
            symbolName: "sun.max.fill",
            title: "Sunlight Makes The Starter",
            detail: "Your skin uses UVB light to start making vitamin D. UVA can tan or age skin, but UVB is the part BigDose cares about for vitamin D timing."
        ),
        EducationSection(
            symbolName: "arrow.up.and.down.and.arrow.left.and.right",
            title: "Angle Matters",
            detail: "When the sun is higher in the sky, UVB travels through less atmosphere. That is why the best window is usually near solar noon, not sunrise or sunset."
        ),
        EducationSection(
            symbolName: "location.fill",
            title: "Your Place Changes Everything",
            detail: "Latitude, season, altitude, clouds and local UV all change how much useful sunlight reaches your skin."
        ),
        EducationSection(
            symbolName: "person.fill",
            title: "Your Body Changes The Estimate",
            detail: "Skin type, age, sunscreen, clothing and exposed skin area all change the estimated time. BigDose uses those inputs to personalize the meter."
        ),
        EducationSection(
            symbolName: "exclamationmark.triangle.fill",
            title: "UV Does Two Jobs",
            detail: "UVB triggers vitamin D production in your skin. High UV also burns skin, ages it and raises long-term skin cancer risk. More sun is not better — timing and limits matter."
        ),
        EducationSection(
            symbolName: "shield.lefthalf.filled",
            title: "What MED (burn risk) Means",
            detail: "MED (burn risk) — minimal erythema dose — is a science-based estimate of the UV exposure that would start to redden your skin. Your Fitzpatrick skin type sets the baseline. BigDose tracks MED (burn risk) Used during every live session."
        ),
        EducationSection(
            symbolName: "bell.badge.fill",
            title: "How BigDose Limits Sessions",
            detail: "Safe max caps planned time at about 95% of MED (burn risk). Turn-over alerts fire near 50%. A stop-now warning always fires at 100% MED (burn risk). Nanny adds wrap-up at 75%, the 95% guidance alert and a 98% reminder while you stay out. Only you stop the session."
        ),
        EducationSection(
            symbolName: "cross.case.fill",
            title: "Not Medical Grade",
            detail: "BigDose is informational wellness guidance. It does not diagnose deficiency, prescribe treatment or replace a 25(OH)D blood test."
        )
    ]

    var body: some View {
        ZStack {
            BigDoseGradientBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How BigDose Works")
                            .font(.system(.largeTitle, weight: .semibold))
                            .foregroundStyle(.white)

                        Text("The freshman-science version. Clear, useful, no medical cosplay.")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.68))
                    }
                    .padding(.top, 18)

                    GlassCard(cornerRadius: 28) {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("Why BigDose", systemImage: "sparkles")
                                .font(.bigDoseHeader(.subheadline).weight(.semibold))
                                .foregroundStyle(.solarGold)

                            WhyBigDoseTaglineHeader()
                        }
                    }

                    ForEach(WhyBigDoseEducationContent.philosophySections) { section in
                        WhyBigDoseSectionCard(section: section)
                    }

                    WhyBigDoseSectionCard(section: WhyBigDoseEducationContent.scienceFooter)

                    sectionDivider(title: "The Mechanics")

                    ForEach(scienceSections) { section in
                        scienceSectionCard(section)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Science")
        .toolbarTitleDisplayMode(.inline)
    }

    private func sectionDivider(title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
                .overlay(.white.opacity(0.18))

            Text(title)
                .font(.bigDoseHeader(.subheadline).weight(.semibold))
                .foregroundStyle(.white.opacity(0.62))
        }
        .padding(.top, 4)
    }

    private func scienceSectionCard(_ section: EducationSection) -> some View {
        GlassCard(cornerRadius: 26) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: section.symbolName)
                    .font(.bigDoseHeader(.title2).weight(.black))
                    .foregroundStyle(.solarGold)
                    .frame(width: 34)

                VStack(alignment: .leading, spacing: 6) {
                    Text(section.title)
                        .font(.bigDoseHeader(.headline).weight(.black))
                        .foregroundStyle(.white)

                    Text(section.detail)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

private struct EducationSection: Identifiable {
    let id = UUID()
    var symbolName: String
    var title: String
    var detail: String
}

#Preview {
    NavigationStack {
        EducationView()
    }
}
